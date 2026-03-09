//
//  MainViewController.swift
//  Quotes
//
//  Created by s pugach on 3.03.26.
//

import SnapKit
import UIKit

@MainActor
final class MainViewController: UIViewController {
    private let viewModel: MainViewModeling
    private let logoImageLoader: LogoImageLoading
    private let quoteFormattingService: QuoteFormattingServicing
    private lazy var quotesTableDataSource = QuotesTableDataSource(
        tableView: tableView,
        logoImageLoader: logoImageLoader,
        quoteFormattingService: quoteFormattingService
    )

    private let tableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = .color.quoteListSeparator
        tableView.separatorInset = UIEdgeInsets(
            top: 0,
            left: QuoteTableViewCell.Metrics.horizontalInset,
            bottom: 0,
            right: 0
        )
        tableView.backgroundColor = .color.white
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = .zero
        tableView.rowHeight = QuoteTableViewCell.Metrics.rowHeight
        return tableView
    }()
    private let streamStateContainerView = UIView()
    private let streamStateLabel = PaddingLabel()
    private var streamStateHeightConstraint: Constraint?

    init(
        viewModel: MainViewModeling,
        logoImageLoader: LogoImageLoading,
        quoteFormattingService: QuoteFormattingServicing
    ) {
        self.viewModel = viewModel
        self.logoImageLoader = logoImageLoader
        self.quoteFormattingService = quoteFormattingService
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError(String.loc.initCoderNotImplemented)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupStreamStateView()
        setupTableView()
        bindViewModel()
        _ = quotesTableDataSource
        viewModel.start()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    deinit {
        viewModel.stop()
    }

    private func setupView() {
        view.backgroundColor = .color.white
    }

    private func setupTableView() {
        view.addSubview(tableView)

        tableView.snp.makeConstraints {
            $0.top.equalTo(streamStateContainerView.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func bindViewModel() {
        viewModel.onQuotesUpdate = { [weak self] quotes in
            self?.quotesTableDataSource.updateQuotes(quotes)
        }
        viewModel.onStateChange = { [weak self] state in
            self?.applyStreamState(state)
        }
    }
    
    private func setupStreamStateView() {
        streamStateContainerView.clipsToBounds = true
        streamStateContainerView.isHidden = true
        streamStateLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        streamStateLabel.textAlignment = .center
        streamStateLabel.textColor = .color.white
        streamStateLabel.numberOfLines = 1
        streamStateLabel.lineBreakMode = .byTruncatingTail
        streamStateLabel.insets = UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 12)

        view.addSubview(streamStateContainerView)
        streamStateContainerView.addSubview(streamStateLabel)

        streamStateContainerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
            streamStateHeightConstraint = $0.height.equalTo(0).constraint
        }

        streamStateLabel.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    private func applyStreamState(_ state: QuoteStreamState) {
        switch state {
        case .connecting:
            setStreamState(message: String.loc.streamConnecting, backgroundColor: .color.quoteNeutral)
        case .live:
            hideStreamState()
        case let .fallback(reason):
            setStreamState(message: String.loc.streamFallback(reason: reason), backgroundColor: .color.quoteNeutral)
        case let .failed(reason):
            setStreamState(message: String.loc.streamFailed(reason: reason), backgroundColor: .color.quoteDown)
        }
    }

    private func setStreamState(message: String, backgroundColor: UIColor) {
        streamStateContainerView.isHidden = false
        streamStateContainerView.backgroundColor = backgroundColor
        streamStateLabel.text = message
        streamStateHeightConstraint?.update(offset: 28)

        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }

    private func hideStreamState() {
        streamStateHeightConstraint?.update(offset: 0)
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.view.layoutIfNeeded()
        } completion: { [weak self] _ in
            self?.streamStateContainerView.isHidden = true
            self?.streamStateLabel.text = nil
        }
    }
}
