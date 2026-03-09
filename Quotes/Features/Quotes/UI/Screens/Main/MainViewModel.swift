//
//  MainViewModel.swift
//  Quotes
//
//  Created by s pugach on 6.03.26.
//

import Foundation

protocol MainViewModeling: AnyObject {
    var onQuotesUpdate: (([Quote]) -> Void)? { get set }
    var onStateChange: ((QuoteStreamState) -> Void)? { get set }

    func start()
    func stop()
}

final class MainViewModel: MainViewModeling {
    var onQuotesUpdate: (([Quote]) -> Void)?
    var onStateChange: ((QuoteStreamState) -> Void)?

    private let quoteService: TradeQuoteServicing

    init(quoteService: TradeQuoteServicing) {
        self.quoteService = quoteService
        self.quoteService.delegate = self
    }

    deinit {
        if quoteService.delegate === self {
            quoteService.delegate = nil
        }
    }

    func start() {
        quoteService.start()
    }

    func stop() {
        quoteService.stop()
    }
}
