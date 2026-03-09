//
//  PartialQuote.swift
//  Quotes
//
//  Created by s pugach on 6.03.26.
//

import Foundation

struct PartialQuote {
    let symbol: String?
    let companyName: String?
    let market: String?
    let lastPrice: Decimal?
    let absoluteChange: Decimal?
    let percentChange: Decimal?
    let minStep: Decimal?
}
