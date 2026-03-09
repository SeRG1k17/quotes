//
//  MainViewModel+TradeQuoteServiceDelegate.swift
//  Quotes
//
//  Created by s pugach on 9.03.26.
//

import Foundation

extension MainViewModel: TradeQuoteServiceDelegate {
    func tradeQuoteService(_ service: TradeQuoteServicing, didUpdate quotes: [Quote]) {
        onQuotesUpdate?(quotes)
    }

    func tradeQuoteService(_ service: TradeQuoteServicing, didChangeState state: QuoteStreamState) {
        onStateChange?(state)
    }
}
