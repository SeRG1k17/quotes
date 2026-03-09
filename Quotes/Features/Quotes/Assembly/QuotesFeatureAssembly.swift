//
//  QuotesFeatureAssembly.swift
//  Quotes
//
//  Created by s pugach on 9.03.26.
//

import UIKit

@MainActor
enum QuotesFeatureAssembly {
    static func makeRootViewController() -> UIViewController {
        let quoteService = TradeQuoteService(symbols: TradeQuoteUniverse.requiredSymbols)
        let mainViewModel = MainViewModel(quoteService: quoteService)
        let logoImageLoader = LogoImageLoader()
        let quoteFormattingService = QuoteFormattingService()

        return MainViewController(
            viewModel: mainViewModel,
            logoImageLoader: logoImageLoader,
            quoteFormattingService: quoteFormattingService
        )
    }
}
