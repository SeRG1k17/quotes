//
//  QuoteTableStateStore.swift
//  Quotes
//
//  Created by s pugach on 6.03.26.
//

import UIKit

struct QuoteTableRowData {
    let quote: Quote
    let previousQuote: Quote?
    let logoImage: UIImage?
}

final class QuoteTableStateStore {
    private var orderedSymbols: [String] = []
    private var quotesBySymbol: [String: Quote] = [:]
    private var previousQuotesBySymbol: [String: Quote] = [:]
    private var logoImagesBySymbol: [String: UIImage] = [:]
    private var logoTasksBySymbol: [String: URLSessionDataTask] = [:]

    func applyQuotes(_ quotes: [Quote]) -> [String] {
        previousQuotesBySymbol = quotesBySymbol
        quotesBySymbol = Dictionary(uniqueKeysWithValues: quotes.map { ($0.symbol, $0) })
        orderedSymbols = quotes.map(\.symbol)
        return orderedSymbols
    }

    func rowData(for symbol: String) -> QuoteTableRowData? {
        guard let quote = quotesBySymbol[symbol] else { return nil }
        return QuoteTableRowData(
            quote: quote,
            previousQuote: previousQuotesBySymbol[symbol],
            logoImage: logoImagesBySymbol[symbol]
        )
    }

    func missingLogoSymbols(in symbols: [String]) -> [String] {
        symbols.filter { logoImagesBySymbol[$0] == nil && logoTasksBySymbol[$0] == nil }
    }

    func setLogoTask(_ task: URLSessionDataTask?, for symbol: String) {
        logoTasksBySymbol[symbol] = task
    }

    @discardableResult
    func handleLogoLoadCompletion(for symbol: String, image: UIImage?) -> Bool {
        logoTasksBySymbol[symbol] = nil
        guard let image else { return false }

        logoImagesBySymbol[symbol] = image
        return true
    }

    func cancelUnusedLogoLoads(keeping symbols: Set<String>) {
        let staleSymbols = logoTasksBySymbol.keys.filter { !symbols.contains($0) }
        staleSymbols.forEach { symbol in
            logoTasksBySymbol[symbol]?.cancel()
            logoTasksBySymbol[symbol] = nil
        }

        logoImagesBySymbol = logoImagesBySymbol.filter { symbols.contains($0.key) }
    }

    func cancelAllLogoLoads() {
        logoTasksBySymbol.values.forEach { $0.cancel() }
        logoTasksBySymbol.removeAll()
    }
}
