//
//  QuoteCellDisplayModel.swift
//  Quotes
//
//  Created by s pugach on 9.03.26.
//

import Foundation

struct QuoteCellDisplayModel {
    let symbol: String
    let subtitle: String
    let percentText: String
    let valueText: String
    let direction: QuoteDirection
    let flashDirection: QuoteDirection?
}
