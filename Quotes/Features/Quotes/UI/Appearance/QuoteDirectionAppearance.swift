//
//  QuoteDirectionAppearance.swift
//  Quotes
//
//  Created by s pugach on 9.03.26.
//

import UIKit

struct QuoteDirectionAppearance {
    let textColor: UIColor
    let flashColor: UIColor?

    static func forDirection(_ direction: QuoteDirection) -> QuoteDirectionAppearance {
        switch direction {
        case .up:
            return .up
        case .down:
            return .down
        case .neutral:
            return .neutral
        }
    }

    private static let up = QuoteDirectionAppearance(
        textColor: .color.quoteUp,
        flashColor: .color.quoteUpFlash
    )
    private static let down = QuoteDirectionAppearance(
        textColor: .color.quoteDown,
        flashColor: .color.quoteDownFlash
    )
    private static let neutral = QuoteDirectionAppearance(
        textColor: .color.quoteNeutral,
        flashColor: nil
    )
}
