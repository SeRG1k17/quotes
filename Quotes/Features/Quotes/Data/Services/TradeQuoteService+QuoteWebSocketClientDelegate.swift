//
//  TradeQuoteService+QuoteWebSocketClientDelegate.swift
//  Quotes
//
//  Created by s pugach on 9.03.26.
//

import Foundation

extension TradeQuoteService: QuoteWebSocketClientDelegate {
    func quoteWebSocketClient(_ client: QuoteWebSocketClienting, didReceive payload: Data) {
        handleWebSocketPayload(payload)
    }

    func quoteWebSocketClient(_ client: QuoteWebSocketClienting, didFailWith error: QuoteServiceError) {
        handleWebSocketError(error)
    }
}
