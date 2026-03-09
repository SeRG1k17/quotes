//
//  QuoteStore.swift
//  Quotes
//
//  Created by s pugach on 9.03.26.
//

import Foundation

protocol QuoteStoring: AnyObject {
    var currentQuotes: [Quote] { get }

    @discardableResult
    func apply(updates: [PartialQuote]) -> Bool
}

final class QuoteStore: QuoteStoring {
    private enum Constants {
        static let placeholderMarket = "TRADERNET"
    }

    private let symbols: [String]
    private let symbolsSet: Set<String>
    private var quotesBySymbol: [String: Quote]

    init(symbols: [String]) {
        self.symbols = symbols
        symbolsSet = Set(symbols)
        quotesBySymbol = Self.makeInitialQuotes(symbols: symbols)
    }

    var currentQuotes: [Quote] {
        symbols.compactMap { quotesBySymbol[$0] }
    }

    @discardableResult
    func apply(updates: [PartialQuote]) -> Bool {
        guard !updates.isEmpty else { return false }

        var didChange = false
        for update in updates {
            didChange = apply(update: update) || didChange
        }

        return didChange
    }

    private func apply(update: PartialQuote) -> Bool {
        guard let symbol = update.symbol, symbolsSet.contains(symbol) else {
            return false
        }

        let currentQuote = quotesBySymbol[symbol] ?? Self.makePlaceholderQuote(symbol: symbol)
        let mergedQuote = currentQuote.merging(with: update)
        guard mergedQuote != currentQuote else {
            return false
        }

        quotesBySymbol[symbol] = mergedQuote
        return true
    }
}

private extension QuoteStore {
    static func makeInitialQuotes(symbols: [String]) -> [String: Quote] {
        var initialQuotes = Dictionary(uniqueKeysWithValues: symbols.map { ($0, makePlaceholderQuote(symbol: $0)) })
        fallbackQuotes.forEach { initialQuotes[$0.symbol] = $0 }
        return initialQuotes
    }

    static func makePlaceholderQuote(symbol: String) -> Quote {
        Quote(
            symbol: symbol,
            companyName: symbol,
            market: Constants.placeholderMarket,
            lastPrice: 0,
            absoluteChange: 0,
            percentChange: 0,
            minStep: 1
        )
    }

    static let fallbackQuotes: [Quote] = [
        Quote(symbol: "FEES", companyName: "FSK EES", market: "MCX", lastPrice: 0.21076, absoluteChange: 0.00686, percentChange: 3.37, minStep: 0.00001),
        Quote(symbol: "GAZP", companyName: "Gazprom ao", market: "MCX", lastPrice: 201.73, absoluteChange: -1.73, percentChange: -0.86, minStep: 0.01),
        Quote(symbol: "HYDR", companyName: "RusHydro", market: "MCX", lastPrice: 0.68000, absoluteChange: 0.02085, percentChange: 3.15, minStep: 0.00001),
        Quote(symbol: "MRKS", companyName: "MRSK Sib", market: "MCX", lastPrice: 0.22750, absoluteChange: -0.00050, percentChange: -0.22, minStep: 0.0001),
        Quote(symbol: "MRKZ", companyName: "MRSK SZ", market: "MCX", lastPrice: 0.05430, absoluteChange: 0.00120, percentChange: 2.26, minStep: 0.00001),
        Quote(symbol: "RSTI", companyName: "Rosseti ao", market: "MCX", lastPrice: 1.51300, absoluteChange: 0.05970, percentChange: 4.11, minStep: 0.0001),
        Quote(symbol: "RUAL", companyName: "RUSAL plc", market: "MCX", lastPrice: 31.43500, absoluteChange: 1.37035, percentChange: 4.56, minStep: 0.001),
        Quote(symbol: "SBER", companyName: "Sberbank", market: "MCX", lastPrice: 233.74900, absoluteChange: 7.21700, percentChange: 3.18, minStep: 0.001),
        Quote(symbol: "TGKA", companyName: "TGK-1", market: "MCX", lastPrice: 0.015792, absoluteChange: 0.000792, percentChange: 5.28, minStep: 0.000001),
        Quote(symbol: "VTBR", companyName: "VTB ao", market: "MCX", lastPrice: 0.043356, absoluteChange: 0.000040, percentChange: 0.09, minStep: 0.000001),
    ]
}
