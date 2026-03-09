//
//  QuoteFormattingService.swift
//  Quotes
//
//  Created by s pugach on 3.03.26.
//

import Foundation

protocol QuoteFormattingServicing {
    func price(_ value: Decimal, minStep: Decimal?) -> String
    func absoluteChange(_ value: Decimal, minStep: Decimal?) -> String
    func percentChange(_ value: Decimal) -> String
}

final class QuoteFormattingService: QuoteFormattingServicing {
    private struct FormatterCacheKey: Hashable {
        let minFractionDigits: Int
        let maxFractionDigits: Int
        let positivePrefix: String?
    }

    private let cacheLock = NSLock()
    private var formatterCache: [FormatterCacheKey: NumberFormatter] = [:]
    private let percentFormatter: NumberFormatter

    init() {
        percentFormatter = Self.makeDecimalFormatter(
            minFractionDigits: 2,
            maxFractionDigits: 2,
            positivePrefix: "+"
        )
    }

    func price(_ value: Decimal, minStep: Decimal?) -> String {
        let step = Self.validatedStep(minStep)
        let rounded = Self.roundedToStep(value, step: step)
        let digits = Self.fractionDigits(for: step)
        let formatter = cachedDecimalFormatter(
            minFractionDigits: digits,
            maxFractionDigits: digits,
            positivePrefix: nil
        )

        let formatted = formatter.string(from: NSDecimalNumber(decimal: rounded))
            ?? "\(rounded)"
        return Self.groupFractionalPart(in: formatted)
    }

    func absoluteChange(_ value: Decimal, minStep: Decimal?) -> String {
        let step = Self.validatedStep(minStep)
        let rounded = Self.roundedToStep(value, step: step)
        let digits = Self.fractionDigits(for: step)
        let formatter = cachedDecimalFormatter(
            minFractionDigits: digits,
            maxFractionDigits: digits,
            positivePrefix: "+"
        )

        let formatted = formatter.string(from: NSDecimalNumber(decimal: rounded))
            ?? "\(rounded)"
        return Self.groupFractionalPart(in: formatted)
    }

    func percentChange(_ value: Decimal) -> String {
        let formattedValue = percentFormatter.string(from: NSDecimalNumber(decimal: value))
            ?? "\(value)"
        return "\(formattedValue)%"
    }

    private func cachedDecimalFormatter(
        minFractionDigits: Int,
        maxFractionDigits: Int,
        positivePrefix: String?
    ) -> NumberFormatter {
        let cacheKey = FormatterCacheKey(
            minFractionDigits: minFractionDigits,
            maxFractionDigits: maxFractionDigits,
            positivePrefix: positivePrefix
        )

        cacheLock.lock()
        defer { cacheLock.unlock() }

        if let formatter = formatterCache[cacheKey] {
            return formatter
        }

        let formatter = Self.makeDecimalFormatter(
            minFractionDigits: minFractionDigits,
            maxFractionDigits: maxFractionDigits,
            positivePrefix: positivePrefix
        )
        formatterCache[cacheKey] = formatter
        return formatter
    }
}

private extension QuoteFormattingService {
    static func validatedStep(_ step: Decimal?) -> Decimal {
        guard let step, step > 0 else {
            return 1
        }
        return step
    }

    static func roundedToStep(_ value: Decimal, step: Decimal) -> Decimal {
        let normalized = value / step
        var rounded = Decimal()
        var source = normalized
        NSDecimalRound(&rounded, &source, 0, .plain)
        return rounded * step
    }

    static func fractionDigits(for step: Decimal) -> Int {
        let string = NSDecimalNumber(decimal: step).stringValue
        guard let separatorIndex = string.firstIndex(of: ".") else { return 0 }
        return string.distance(from: string.index(after: separatorIndex), to: string.endIndex)
    }

    static func makeDecimalFormatter(
        minFractionDigits: Int,
        maxFractionDigits: Int,
        positivePrefix: String?
    ) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = minFractionDigits
        formatter.maximumFractionDigits = maxFractionDigits
        formatter.positivePrefix = positivePrefix
        return formatter
    }

    static func groupFractionalPart(in value: String) -> String {
        let signPrefix: String
        let unsignedValue: String

        if value.hasPrefix("+") || value.hasPrefix("-") {
            signPrefix = String(value.prefix(1))
            unsignedValue = String(value.dropFirst())
        } else {
            signPrefix = ""
            unsignedValue = value
        }

        let components = unsignedValue.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        guard components.count == 2 else {
            return signPrefix + unsignedValue
        }

        let integerPart = String(components[0])
        let fractionalPart = String(components[1])
        guard fractionalPart.count > 3 else {
            return signPrefix + unsignedValue
        }

        var groupedChunks: [String] = []
        var startIndex = fractionalPart.startIndex
        while startIndex < fractionalPart.endIndex {
            let endIndex = fractionalPart.index(
                startIndex,
                offsetBy: 3,
                limitedBy: fractionalPart.endIndex
            ) ?? fractionalPart.endIndex
            groupedChunks.append(String(fractionalPart[startIndex..<endIndex]))
            startIndex = endIndex
        }

        return "\(signPrefix)\(integerPart).\(groupedChunks.joined(separator: " "))"
    }
}
