//
//  QuoteCellDisplayModelBuilder.swift
//  Quotes
//
//  Created by s pugach on 9.03.26.
//

import Foundation

protocol QuoteCellDisplayModelBuilding {
    func makeDisplayModel(quote: Quote, previousQuote: Quote?) -> QuoteCellDisplayModel
}

final class QuoteCellDisplayModelBuilder: QuoteCellDisplayModelBuilding {
    private let quoteFormattingService: QuoteFormattingServicing

    init(quoteFormattingService: QuoteFormattingServicing) {
        self.quoteFormattingService = quoteFormattingService
    }

    func makeDisplayModel(quote: Quote, previousQuote: Quote?) -> QuoteCellDisplayModel {
        QuoteCellDisplayModel(
            symbol: quote.symbol,
            subtitle: String.loc.quoteSubtitle(market: quote.market, companyName: quote.companyName),
            percentText: quoteFormattingService.percentChange(quote.percentChange),
            valueText: String.loc.quoteValue(
                price: quoteFormattingService.price(quote.lastPrice, minStep: quote.minStep),
                absoluteChange: quoteFormattingService.absoluteChange(quote.absoluteChange, minStep: quote.minStep)
            ),
            direction: quote.direction,
            flashDirection: flashDirection(currentQuote: quote, previousQuote: previousQuote)
        )
    }
}

private extension QuoteCellDisplayModelBuilder {
    func flashDirection(currentQuote: Quote, previousQuote: Quote?) -> QuoteDirection? {
        guard let previousQuote else { return nil }

        let comparedFields: [(Decimal, Decimal)] = [
            (currentQuote.lastPrice, previousQuote.lastPrice),
            (currentQuote.percentChange, previousQuote.percentChange),
            (currentQuote.absoluteChange, previousQuote.absoluteChange)
        ]

        for (lhs, rhs) in comparedFields {
            if lhs > rhs { return .up }
            if lhs < rhs { return .down }
        }

        return nil
    }
}
