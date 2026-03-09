//
//  L10n.swift
//  Quotes
//
//  Created by s pugach on 9.03.26.
//

import Foundation

extension String {
    static let loc = L10n()
}

struct L10n {
    let initCoderNotImplemented = "init(coder:) has not been implemented"

    let streamConnecting = "Connecting to live stream..."
    func streamFallback(reason: String) -> String {
        reason == quoteServiceNoInternet ? reason : "Fallback mode: \(reason)"
    }
    func streamFailed(reason: String) -> String {
        reason == quoteServiceNoInternet ? reason : "Live stream failed: \(reason)"
    }

    let quoteFormattingServiceNotConfigured = "QuoteFormattingService is not configured"
    func quoteSubtitle(market: String, companyName: String) -> String { "\(market) | \(companyName)" }
    func quoteValue(price: String, absoluteChange: String) -> String { "\(price) (\(absoluteChange))" }

    let quoteServiceInvalidSocketEndpoint = "Invalid socket endpoint"
    let quoteServiceSubscriptionPayloadEncoding = "Failed to encode subscription payload"
    let quoteServiceNoInternet = "No internet connection"
    func quoteServiceSocketSendFailed(reason: String) -> String {
        reason == quoteServiceNoInternet ? reason : "Socket send failed: \(reason)"
    }
    func quoteServiceSocketReceiveFailed(reason: String) -> String {
        reason == quoteServiceNoInternet ? reason : "Socket receive failed: \(reason)"
    }
    func quoteServiceTopSecuritiesTransportFailed(reason: String) -> String {
        reason == quoteServiceNoInternet ? reason : "Top securities transport failed: \(reason)"
    }
    func quoteServiceTopSecuritiesHTTPStatus(_ statusCode: Int) -> String { "Top securities HTTP status: \(statusCode)" }
    let quoteServiceTopSecuritiesEmptyPayload = "Top securities response is empty"
    let quoteServiceNoLiveUpdatesWithinTimeout = "No live updates yet"
    let quoteServiceFallbackReason = "Demo data"
    func quoteServiceFallbackMessage(reason: String) -> String { "\(quoteServiceFallbackReason) (\(reason))" }

    let quoteStreamConnectingLog = "Quote stream: connecting"
    let quoteStreamLiveLog = "Quote stream: live"
    func quoteStreamFallbackLog(reason: String) -> String { "Quote stream: fallback (\(reason))" }
    func quoteStreamFailedLog(reason: String) -> String { "Quote stream: failed (\(reason))" }
}
