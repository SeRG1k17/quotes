//
//  QuoteParser.swift
//  Quotes
//
//  Created by s pugach on 3.03.26.
//

import Foundation

enum QuoteParser {
    private static let nestedPayloadKeys = ["data", "payload", "quotes", "items", "results", "q"]

    static func parseQuotes(from data: Data) -> [PartialQuote] {
        guard let json = try? JSONSerialization.jsonObject(with: data) else {
            return []
        }

        return parseQuotes(from: json)
    }

    static func subscriptionMessage(symbols: [String]) -> Data? {
        try? JSONSerialization.data(withJSONObject: ["quotes", symbols])
    }
}

private extension QuoteParser {
    private static func parseQuotes(from json: Any) -> [PartialQuote] {
        if let quote = partialQuote(from: json) {
            return [quote]
        }

        if let dictionary = json as? [String: Any] {
            return parseQuotes(from: dictionary)
        }

        if let array = json as? [Any] {
            return parseQuotes(from: array)
        }

        return []
    }

    private static func parseQuotes(from dictionary: [String: Any]) -> [PartialQuote] {
        var collectedQuotes: [PartialQuote] = []

        for key in nestedPayloadKeys {
            if let nested = dictionary[key] {
                collectedQuotes.append(contentsOf: parseQuotes(from: nested))
            }
        }

        if let quote = partialQuote(from: dictionary) {
            collectedQuotes.append(quote)
        }

        return collectedQuotes
    }

    private static func parseQuotes(from array: [Any]) -> [PartialQuote] {
        if
            let first = array.first as? String,
            (first.lowercased() == "quotes" || first.lowercased() == "q"),
            array.count > 1
        {
            return parseQuotes(from: array[1])
        }

        return array.flatMap(parseQuotes(from:))
    }

    private static func partialQuote(from json: Any) -> PartialQuote? {
        guard let dictionary = json as? [String: Any] else {
            return nil
        }

        let symbol = stringValue(in: dictionary, keys: ["symbol", "secid", "ticker", "code", "s"])
        let companyName = stringValue(in: dictionary, keys: ["companyName", "shortName", "short_name", "name", "title", "description"])
        let market = stringValue(in: dictionary, keys: ["market", "board", "marketName", "group", "ltr", "exchange"])
        let lastPrice = decimalValue(in: dictionary, keys: ["lastPrice", "last", "price", "ltp", "value", "c"])
        let absoluteChange = decimalValue(in: dictionary, keys: ["absoluteChange", "change", "chg", "delta", "pc"])
        let percentChange = decimalValue(in: dictionary, keys: ["percentChange", "changePercent", "percent", "chg_pct", "change_prc", "pcp"])
        let minStep = decimalValue(in: dictionary, keys: ["min_step", "minStep", "step"])

        let hasPayload = [symbol, companyName, market].contains { $0 != nil }
            || [lastPrice, absoluteChange, percentChange, minStep].contains { $0 != nil }
        guard hasPayload else {
            return nil
        }

        return PartialQuote(
            symbol: symbol,
            companyName: companyName,
            market: market,
            lastPrice: lastPrice,
            absoluteChange: absoluteChange,
            percentChange: percentChange,
            minStep: minStep
        )
    }

    private static func stringValue(in dictionary: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = dictionary[key] as? String, !value.isEmpty {
                return value
            }
        }

        if keys.contains("symbol"),
           let value = dictionary["c"] as? String,
           !value.isEmpty
        {
            return value
        }

        return nil
    }

    private static func decimalValue(in dictionary: [String: Any], keys: [String]) -> Decimal? {
        for key in keys {
            guard let value = dictionary[key] else { continue }

            if let decimal = value as? Decimal {
                return decimal
            }

            if let number = value as? NSNumber {
                return number.decimalValue
            }

            if let string = value as? String, let decimal = Decimal(string: string.replacingOccurrences(of: ",", with: ".")) {
                return decimal
            }
        }

        return nil
    }
}
