//
//  Quote.swift
//  Quotes
//
//  Created by s pugach on 3.03.26.
//

import Foundation

struct Quote: Hashable {
    let symbol: String
    let companyName: String
    let market: String
    let lastPrice: Decimal
    let absoluteChange: Decimal
    let percentChange: Decimal
    let minStep: Decimal?

    var direction: QuoteDirection {
        if percentChange > 0 || absoluteChange > 0 {
            return .up
        }

        if percentChange < 0 || absoluteChange < 0 {
            return .down
        }

        return .neutral
    }

    func merging(with update: PartialQuote) -> Quote {
        Quote(
            symbol: update.symbol ?? symbol,
            companyName: update.companyName ?? companyName,
            market: update.market ?? market,
            lastPrice: update.lastPrice ?? lastPrice,
            absoluteChange: update.absoluteChange ?? absoluteChange,
            percentChange: update.percentChange ?? percentChange,
            minStep: update.minStep ?? minStep
        )
    }
}
