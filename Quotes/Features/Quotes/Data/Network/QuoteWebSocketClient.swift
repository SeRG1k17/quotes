//
//  QuoteWebSocketClient.swift
//  Quotes
//
//  Created by s pugach on 9.03.26.
//

import Foundation

protocol QuoteWebSocketClientDelegate: AnyObject {
    func quoteWebSocketClient(_ client: QuoteWebSocketClienting, didReceive payload: Data)
    func quoteWebSocketClient(_ client: QuoteWebSocketClienting, didFailWith error: QuoteServiceError)
}

protocol QuoteWebSocketClienting: AnyObject {
    var delegate: QuoteWebSocketClientDelegate? { get set }

    func connect(symbols: [String]) -> Result<Void, QuoteServiceError>
    func disconnect()
}

final class QuoteWebSocketClient: QuoteWebSocketClienting {
    weak var delegate: QuoteWebSocketClientDelegate?

    private let session: URLSession
    private let socketEndpoint: URL?
    private let callbackQueue: DispatchQueue
    private var webSocketTask: URLSessionWebSocketTask?

    init(
        session: URLSession,
        socketEndpoint: URL?,
        callbackQueue: DispatchQueue
    ) {
        self.session = session
        self.socketEndpoint = socketEndpoint
        self.callbackQueue = callbackQueue
    }

    func connect(symbols: [String]) -> Result<Void, QuoteServiceError> {
        guard let socketEndpoint else {
            return .failure(.invalidSocketEndpoint)
        }

        disconnect()

        let task = session.webSocketTask(with: socketEndpoint)
        webSocketTask = task
        task.resume()

        sendSubscription(symbols: symbols, using: task)
        receiveNextMessage(using: task)
        return .success(())
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
}

private extension QuoteWebSocketClient {
    func sendSubscription(symbols: [String], using task: URLSessionWebSocketTask) {
        guard
            let payload = QuoteParser.subscriptionMessage(symbols: symbols),
            let message = String(data: payload, encoding: .utf8)
        else {
            notifyFailure(.subscriptionPayloadEncoding)
            return
        }

        task.send(.string(message)) { [weak self] error in
            guard let self, let error else { return }
            guard self.webSocketTask === task else { return }
            self.notifyFailure(.socketSend(error))
        }
    }

    func receiveNextMessage(using task: URLSessionWebSocketTask) {
        task.receive { [weak self] result in
            guard let self else { return }
            guard self.webSocketTask === task else { return }

            switch result {
            case let .success(message):
                if let payload = messagePayload(message) {
                    notifyPayload(payload)
                }
                receiveNextMessage(using: task)
            case let .failure(error):
                webSocketTask = nil
                notifyFailure(.socketReceive(error))
            }
        }
    }

    func messagePayload(_ message: URLSessionWebSocketTask.Message) -> Data? {
        switch message {
        case let .data(data):
            return data
        case let .string(string):
            return Data(string.utf8)
        @unknown default:
            return nil
        }
    }

    func notifyPayload(_ payload: Data) {
        callbackQueue.async { [weak self] in
            guard let self else { return }
            self.delegate?.quoteWebSocketClient(self, didReceive: payload)
        }
    }

    func notifyFailure(_ error: QuoteServiceError) {
        callbackQueue.async { [weak self] in
            guard let self else { return }
            self.delegate?.quoteWebSocketClient(self, didFailWith: error)
        }
    }
}
