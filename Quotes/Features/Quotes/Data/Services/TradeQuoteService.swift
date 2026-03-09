//
//  TradeQuoteService.swift
//  Quotes
//
//  Created by s pugach on 3.03.26.
//

import Foundation

enum QuoteStreamState {
    case connecting
    case live
    case fallback(String)
    case failed(String)
}

enum QuoteServiceError: LocalizedError {
    case invalidSocketEndpoint
    case subscriptionPayloadEncoding
    case socketSend(Error)
    case socketReceive(Error)
    case topSecuritiesTransport(Error)
    case topSecuritiesHTTPStatus(Int)
    case topSecuritiesEmptyPayload
    case noLiveUpdatesWithinTimeout

    var errorDescription: String? {
        switch self {
        case .invalidSocketEndpoint:
            return String.loc.quoteServiceInvalidSocketEndpoint
        case .subscriptionPayloadEncoding:
            return String.loc.quoteServiceSubscriptionPayloadEncoding
        case let .socketSend(error):
            return String.loc.quoteServiceSocketSendFailed(reason: Self.transportReason(for: error))
        case let .socketReceive(error):
            return String.loc.quoteServiceSocketReceiveFailed(reason: Self.transportReason(for: error))
        case let .topSecuritiesTransport(error):
            return String.loc.quoteServiceTopSecuritiesTransportFailed(reason: Self.transportReason(for: error))
        case let .topSecuritiesHTTPStatus(statusCode):
            return String.loc.quoteServiceTopSecuritiesHTTPStatus(statusCode)
        case .topSecuritiesEmptyPayload:
            return String.loc.quoteServiceTopSecuritiesEmptyPayload
        case .noLiveUpdatesWithinTimeout:
            return String.loc.quoteServiceNoLiveUpdatesWithinTimeout
        }
    }

    private static func transportReason(for error: Error) -> String {
        let nsError = error as NSError
        guard nsError.domain == NSURLErrorDomain else {
            return error.localizedDescription
        }

        switch nsError.code {
        case NSURLErrorNotConnectedToInternet, NSURLErrorTimedOut:
            return String.loc.quoteServiceNoInternet
        default:
            return error.localizedDescription
        }
    }
}

protocol TradeQuoteServicing: AnyObject {
    var delegate: TradeQuoteServiceDelegate? { get set }
    func start()
    func stop()
}

protocol TradeQuoteServiceDelegate: AnyObject {
    func tradeQuoteService(_ service: TradeQuoteServicing, didUpdate quotes: [Quote])
    func tradeQuoteService(_ service: TradeQuoteServicing, didChangeState state: QuoteStreamState)
}

extension TradeQuoteServiceDelegate {
    func tradeQuoteService(_ service: TradeQuoteServicing, didChangeState state: QuoteStreamState) {}
}

final class TradeQuoteService: TradeQuoteServicing {
    weak var delegate: TradeQuoteServiceDelegate?

    private enum Endpoint {
        static let socket = URL(string: "wss://wss.tradernet.com")
        static let topSecurities = URL(string: "https://tradernet.com/tradernet-api/quotes-get-top-securities")
    }

    private enum Constants {
        static let stateQueueLabel = "com.quotes.quote-service.state"
        static let fallbackTimeout: TimeInterval = 3
        static let liveSilenceTimeout: TimeInterval = 3
        static let reconnectDelay: TimeInterval = 1.5
        static let maxReconnectAttempts = 3
        static let topSecuritiesType = "stocks"
        static let topSecuritiesExchange = "russia"
        static let topSecuritiesGainers = 0
        static let topSecuritiesLimit = 30
    }

    private let symbols: [String]
    private let stateQueue: DispatchQueue
    private let quoteStore: QuoteStoring
    private let streamStateMachine: QuoteStreamStateMachining
    private let webSocketClient: QuoteWebSocketClienting
    private let topSecuritiesClient: TopSecuritiesFetching

    private var isRunning = false
    private var liveSilenceWatchdog: DispatchWorkItem?

    init(
        symbols: [String],
        stateQueue: DispatchQueue,
        quoteStore: QuoteStoring,
        streamStateMachine: QuoteStreamStateMachining,
        webSocketClient: QuoteWebSocketClienting,
        topSecuritiesClient: TopSecuritiesFetching
    ) {
        self.symbols = symbols
        self.stateQueue = stateQueue
        self.quoteStore = quoteStore
        self.streamStateMachine = streamStateMachine
        self.webSocketClient = webSocketClient
        self.topSecuritiesClient = topSecuritiesClient

        self.webSocketClient.delegate = self
    }

    convenience init(symbols: [String], session: URLSession) {
        let stateQueue = DispatchQueue(label: Constants.stateQueueLabel)
        let quoteStore = QuoteStore(symbols: symbols)
        let streamStateMachine = QuoteStreamStateMachine(
            maxReconnectAttempts: Constants.maxReconnectAttempts,
            reconnectDelay: Constants.reconnectDelay
        )
        let webSocketClient = QuoteWebSocketClient(
            session: session,
            socketEndpoint: Endpoint.socket,
            callbackQueue: stateQueue
        )
        let topSecuritiesClient = TopSecuritiesClient(
            session: session,
            endpoint: Endpoint.topSecurities,
            callbackQueue: stateQueue,
            type: Constants.topSecuritiesType,
            exchange: Constants.topSecuritiesExchange,
            gainers: Constants.topSecuritiesGainers,
            limit: Constants.topSecuritiesLimit
        )

        self.init(
            symbols: symbols,
            stateQueue: stateQueue,
            quoteStore: quoteStore,
            streamStateMachine: streamStateMachine,
            webSocketClient: webSocketClient,
            topSecuritiesClient: topSecuritiesClient
        )
    }

    convenience init(symbols: [String]) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        let session = URLSession(configuration: configuration)

        self.init(symbols: symbols, session: session)
    }

    func start() {
        stateQueue.async { [weak self] in
            self?.startOnStateQueue()
        }
    }

    func stop() {
        stateQueue.async { [weak self] in
            self?.stopOnStateQueue()
        }
    }

    func handleWebSocketPayload(_ payload: Data) {
        stateQueue.async { [weak self] in
            guard let self, self.isRunning else { return }
            self.applyLivePayload(payload)
        }
    }

    func handleWebSocketError(_ error: QuoteServiceError) {
        stateQueue.async { [weak self] in
            guard let self, self.isRunning else { return }
            self.scheduleReconnectIfNeeded(reason: error.localizedDescription)
        }
    }
}

private extension TradeQuoteService {
    func startOnStateQueue() {
        guard !isRunning else { return }

        isRunning = true
        streamStateMachine.reset()
        cancelLiveSilenceWatchdog()

        notifyQuotes(quoteStore.currentQuotes)
        notifyState(.connecting)
        fetchTopSecurities()
        connect(scheduleFallbackTimer: true)
    }

    func stopOnStateQueue() {
        guard isRunning else { return }

        isRunning = false
        streamStateMachine.reset()
        cancelLiveSilenceWatchdog()
        webSocketClient.disconnect()
    }

    func connect(scheduleFallbackTimer: Bool) {
        switch webSocketClient.connect(symbols: symbols) {
        case .success:
            if scheduleFallbackTimer {
                scheduleFallbackActivation()
            } else if streamStateMachine.hasReceivedLiveData {
                scheduleLiveSilenceWatchdog()
            }
        case let .failure(error):
            activateFallbackIfNeeded(reason: error.localizedDescription)
        }
    }

    private func applyLivePayload(_ payload: Data) {
        guard quoteStore.apply(updates: QuoteParser.parseQuotes(from: payload)) else { return }

        streamStateMachine.markLiveDataReceived()
        scheduleLiveSilenceWatchdog()
        notifyState(.live)
        notifyQuotes(quoteStore.currentQuotes)
    }

    func scheduleFallbackActivation() {
        stateQueue.asyncAfter(deadline: .now() + Constants.fallbackTimeout) { [weak self] in
            guard let self else { return }
            guard self.isRunning, !self.streamStateMachine.hasReceivedLiveData else { return }
            self.activateFallbackIfNeeded(reason: QuoteServiceError.noLiveUpdatesWithinTimeout.localizedDescription)
        }
    }

    func activateFallbackIfNeeded(reason: String) {
        guard isRunning else { return }

        if streamStateMachine.hasReceivedLiveData {
            notifyState(.failed(reason))
            return
        }

        let fallbackMessage = String.loc.quoteServiceFallbackMessage(reason: reason)
        notifyState(.fallback(fallbackMessage))
        notifyQuotes(quoteStore.currentQuotes)
    }

    private func scheduleReconnectIfNeeded(reason: String) {
        guard isRunning else { return }
        cancelLiveSilenceWatchdog()

        switch streamStateMachine.recoveryAction(for: reason) {
        case let .failed(reason):
            notifyState(.failed(reason))
        case let .fallback(reason):
            activateFallbackIfNeeded(reason: reason)
        case let .reconnect(after: delay):
            notifyState(.connecting)
            stateQueue.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self else { return }
                guard self.isRunning else { return }
                self.connect(scheduleFallbackTimer: false)
            }
        }
    }

    func scheduleLiveSilenceWatchdog() {
        cancelLiveSilenceWatchdog()

        let watchdog = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard self.isRunning, self.streamStateMachine.hasReceivedLiveData else { return }
            self.scheduleReconnectIfNeeded(reason: QuoteServiceError.noLiveUpdatesWithinTimeout.localizedDescription)
        }

        liveSilenceWatchdog = watchdog
        stateQueue.asyncAfter(deadline: .now() + Constants.liveSilenceTimeout, execute: watchdog)
    }

    func cancelLiveSilenceWatchdog() {
        liveSilenceWatchdog?.cancel()
        liveSilenceWatchdog = nil
    }

    func fetchTopSecurities() {
        requestTopSecurities(with: .post) { [weak self] didApply in
            guard let self, !didApply else { return }
            self.requestTopSecurities(with: .get, completion: nil)
        }
    }

    func requestTopSecurities(
        with method: RequestMethod,
        completion: ((Bool) -> Void)?
    ) {
        topSecuritiesClient.fetch(using: method) { [weak self] result in
            guard let self else {
                completion?(false)
                return
            }

            self.stateQueue.async {
                guard self.isRunning else {
                    completion?(false)
                    return
                }

                switch result {
                case let .success(payload):
                    let didApply = self.applyTopSecuritiesPayload(payload)
                    completion?(didApply)
                case let .failure(error):
                    self.logTopSecuritiesFailure(error)
                    completion?(false)
                }
            }
        }
    }

    func applyTopSecuritiesPayload(_ payload: Data) -> Bool {
        let didApply = quoteStore.apply(updates: QuoteParser.parseQuotes(from: payload))
        if didApply {
            notifyQuotes(quoteStore.currentQuotes)
        }
        return didApply
    }

    func notifyState(_ state: QuoteStreamState) {
        logState(state)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.delegate?.tradeQuoteService(self, didChangeState: state)
        }
    }

    func notifyQuotes(_ quotes: [Quote]) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.delegate?.tradeQuoteService(self, didUpdate: quotes)
        }
    }

    func logState(_ state: QuoteStreamState) {
        #if DEBUG
        switch state {
        case .connecting:
            print(String.loc.quoteStreamConnectingLog)
        case .live:
            print(String.loc.quoteStreamLiveLog)
        case let .fallback(reason):
            print(String.loc.quoteStreamFallbackLog(reason: reason))
        case let .failed(reason):
            print(String.loc.quoteStreamFailedLog(reason: reason))
        }
        #endif
    }

    func logTopSecuritiesFailure(_ error: QuoteServiceError) {
        #if DEBUG
        print(error.localizedDescription)
        #endif
    }
}
