//
//  QuotesTableDataSource.swift
//  Quotes
//
//  Created by s pugach on 6.03.26.
//

import UIKit

@MainActor
final class QuotesTableDataSource {
    private enum Section {
        case main
    }

    private let tableView: UITableView
    private let logoImageLoader: LogoImageLoading
    private let displayModelBuilder: QuoteCellDisplayModelBuilding
    private let stateStore = QuoteTableStateStore()
    private lazy var dataSource = makeDataSource()

    init(
        tableView: UITableView,
        logoImageLoader: LogoImageLoading,
        quoteFormattingService: QuoteFormattingServicing
    ) {
        self.tableView = tableView
        self.logoImageLoader = logoImageLoader
        displayModelBuilder = QuoteCellDisplayModelBuilder(quoteFormattingService: quoteFormattingService)
        configureTableView()
        _ = dataSource
    }

    deinit {
        stateStore.cancelAllLogoLoads()
    }

    func updateQuotes(_ quotes: [Quote]) {
        let orderedSymbols = stateStore.applyQuotes(quotes)

        applySnapshot(with: orderedSymbols, animatingDifferences: true)
        reconfigureRows(for: orderedSymbols)
        requestMissingLogos(for: orderedSymbols)
        stateStore.cancelUnusedLogoLoads(keeping: Set(orderedSymbols))
    }
}

private extension QuotesTableDataSource {
    private func configureTableView() {
        tableView.register(QuoteTableViewCell.self)
    }

    private func makeDataSource() -> UITableViewDiffableDataSource<Section, String> {
        UITableViewDiffableDataSource<Section, String>(tableView: tableView) { [weak self] tableView, indexPath, symbol in
            guard
                let self,
                let rowData = self.stateStore.rowData(for: symbol)
            else {
                return UITableViewCell()
            }

            let displayModel = self.displayModelBuilder.makeDisplayModel(
                quote: rowData.quote,
                previousQuote: rowData.previousQuote
            )
            let cell = tableView.dequeueReusableCell(QuoteTableViewCell.self, for: indexPath)
            cell.configure(with: displayModel, logoImage: rowData.logoImage)
            return cell
        }
    }

    private func applySnapshot(with symbols: [String], animatingDifferences: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, String>()
        snapshot.appendSections([.main])
        snapshot.appendItems(symbols, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }

    private func reconfigureRows(for symbols: [String]) {
        guard !symbols.isEmpty else { return }

        var snapshot = dataSource.snapshot()
        let existingSymbols = symbols.filter { snapshot.indexOfItem($0) != nil }
        guard !existingSymbols.isEmpty else { return }

        snapshot.reconfigureItems(existingSymbols)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func requestMissingLogos(for symbols: [String]) {
        for symbol in stateStore.missingLogoSymbols(in: symbols) {
            let task = logoImageLoader.loadLogo(for: symbol) { [weak self] image in
                DispatchQueue.main.async {
                    guard let self else { return }
                    guard self.stateStore.handleLogoLoadCompletion(for: symbol, image: image) else { return }
                    self.reconfigureRows(for: [symbol])
                }
            }
            stateStore.setLogoTask(task, for: symbol)
        }
    }
}
