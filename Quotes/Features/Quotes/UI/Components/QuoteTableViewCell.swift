//
//  QuoteTableViewCell.swift
//  Quotes
//
//  Created by s pugach on 3.03.26.
//

import SnapKit
import UIKit

@MainActor
final class QuoteTableViewCell: UITableViewCell, ReusableCell {
    enum Metrics {
        static let rowHeight: CGFloat = 73
        static let horizontalInset: CGFloat = 14
        static let iconSize: CGFloat = 18
        static let iconToTextSpacing: CGFloat = 7
        static let columnsSpacing: CGFloat = 10
        static let rightInset: CGFloat = 3
        static let topRowCenterYOffset: CGFloat = -10
        static let bottomRowCenterYOffset: CGFloat = 10
        static let percentFlashHoldDuration: TimeInterval = 2
    }

    private let logoImageView = UIImageView()
    private let fallbackIconLabel = PaddingLabel()

    private let symbolLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let percentLabel = PaddingLabel()
    private let valueLabel = UILabel()

    private let separatorView = UIView()

    private var representedSymbol = ""
    private var percentFlashResetWorkItem: DispatchWorkItem?
    private var isPercentFlashActive = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError(String.loc.initCoderNotImplemented)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        representedSymbol = ""
        resetFlashState()
        resetLogoState()
    }

    func configure(with displayModel: QuoteCellDisplayModel, logoImage: UIImage?) {
        representedSymbol = displayModel.symbol
        apply(displayModel)
        applyLogo(image: logoImage, symbol: displayModel.symbol)
    }
}

private extension QuoteTableViewCell {
    func resetFlashState() {
        percentFlashResetWorkItem?.cancel()
        percentFlashResetWorkItem = nil
        isPercentFlashActive = false
        percentLabel.backgroundColor = .color.clear
        percentLabel.textColor = QuoteDirectionAppearance.forDirection(.neutral).textColor
        percentLabel.layer.removeAllAnimations()
    }

    func resetLogoState() {
        logoImageView.image = nil
        logoImageView.isHidden = true
        fallbackIconLabel.isHidden = false
    }

    func isRepresenting(_ symbol: String) -> Bool {
        representedSymbol == symbol
    }

    func setupUI() {
        backgroundColor = .color.white
        contentView.backgroundColor = .color.white
        selectionStyle = .none
        accessoryType = .disclosureIndicator
        tintColor = .color.quoteListAccessory

        setupIconUI()
        setupLabelsUI()

        separatorView.backgroundColor = .color.quoteListSeparator

        contentView.addSubviews(
            logoImageView,
            fallbackIconLabel,
            symbolLabel,
            subtitleLabel,
            percentLabel,
            valueLabel,
            separatorView
        )

        setupConstraints()
    }

    func setupIconUI() {
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.layer.cornerRadius = Metrics.iconSize / 2
        logoImageView.layer.masksToBounds = true
        logoImageView.isHidden = true

        fallbackIconLabel.font = .systemFont(ofSize: 9, weight: .semibold)
        fallbackIconLabel.textAlignment = .center
        fallbackIconLabel.layer.cornerRadius = Metrics.iconSize / 2
        fallbackIconLabel.layer.masksToBounds = true
        fallbackIconLabel.backgroundColor = .color.quoteListFallbackIconBackground
        fallbackIconLabel.textColor = .color.quoteListFallbackIconText
        fallbackIconLabel.insets = UIEdgeInsets(top: 3, left: 5, bottom: 3, right: 5)
    }

    func setupLabelsUI() {
        symbolLabel.font = .systemFont(ofSize: 17, weight: .regular)
        symbolLabel.textColor = .color.quoteListSymbolText
        symbolLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        subtitleLabel.font = .systemFont(ofSize: 11.5, weight: .regular)
        subtitleLabel.textColor = .color.quoteListSubtitleText
        subtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        percentLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        percentLabel.textAlignment = .right
        percentLabel.layer.cornerRadius = 7
        percentLabel.layer.masksToBounds = true
        percentLabel.backgroundColor = .color.clear
        percentLabel.insets = UIEdgeInsets(top: 1, left: 7, bottom: 1, right: 7)
        percentLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        percentLabel.setContentHuggingPriority(.required, for: .horizontal)

        valueLabel.font = .systemFont(ofSize: 14, weight: .regular)
        valueLabel.textColor = .color.quoteListValueText
        valueLabel.textAlignment = .right
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)
    }

    func setupConstraints() {
        logoImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(Metrics.horizontalInset)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(Metrics.iconSize)
        }

        fallbackIconLabel.snp.makeConstraints {
            $0.edges.equalTo(logoImageView)
        }

        percentLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(Metrics.rightInset)
            $0.centerY.equalToSuperview().offset(Metrics.topRowCenterYOffset)
        }

        valueLabel.snp.makeConstraints {
            $0.trailing.equalTo(percentLabel)
            $0.centerY.equalToSuperview().offset(Metrics.bottomRowCenterYOffset)
        }

        symbolLabel.snp.makeConstraints {
            $0.leading.equalTo(logoImageView.snp.trailing).offset(Metrics.iconToTextSpacing)
            $0.trailing.lessThanOrEqualTo(percentLabel.snp.leading).offset(-Metrics.columnsSpacing)
            $0.centerY.equalTo(percentLabel.snp.centerY)
        }

        subtitleLabel.snp.makeConstraints {
            $0.leading.equalTo(symbolLabel)
            $0.trailing.lessThanOrEqualTo(valueLabel.snp.leading).offset(-Metrics.columnsSpacing)
            $0.centerY.equalTo(valueLabel.snp.centerY)
        }

        separatorView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(Metrics.horizontalInset)
            $0.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    func apply(_ displayModel: QuoteCellDisplayModel) {
        symbolLabel.text = displayModel.symbol
        subtitleLabel.text = displayModel.subtitle
        percentLabel.text = displayModel.percentText
        valueLabel.text = displayModel.valueText

        applyDirectionStyle(displayModel.direction)
        applyPriceFlash(
            flashDirection: displayModel.flashDirection,
            finalDirection: displayModel.direction,
            symbol: displayModel.symbol
        )
    }

    func applyDirectionStyle(_ direction: QuoteDirection) {
        let appearance = QuoteDirectionAppearance.forDirection(direction)
        percentLabel.textColor = isPercentFlashActive ? .color.white : appearance.textColor
    }

    func applyPriceFlash(flashDirection: QuoteDirection?, finalDirection: QuoteDirection, symbol: String) {
        guard let flashDirection else { return }

        flashPercentBadge(
            for: flashDirection,
            finalDirection: finalDirection,
            symbol: symbol
        )
    }

    func flashPercentBadge(
        for changeDirection: QuoteDirection,
        finalDirection: QuoteDirection,
        symbol: String
    ) {
        let changeAppearance = QuoteDirectionAppearance.forDirection(changeDirection)
        let finalAppearance = QuoteDirectionAppearance.forDirection(finalDirection)

        percentFlashResetWorkItem?.cancel()
        percentFlashResetWorkItem = nil
        isPercentFlashActive = true
        percentLabel.layer.removeAllAnimations()
        percentLabel.backgroundColor = changeAppearance.textColor
        percentLabel.textColor = .color.white

        let resetWorkItem = DispatchWorkItem { [weak self] in
            guard let self, self.isRepresenting(symbol) else { return }
            self.percentLabel.backgroundColor = .color.clear
            self.isPercentFlashActive = false
            self.percentFlashResetWorkItem = nil
            self.percentLabel.textColor = finalAppearance.textColor
        }

        percentFlashResetWorkItem = resetWorkItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + Metrics.percentFlashHoldDuration,
            execute: resetWorkItem
        )
    }

    func applyLogo(image: UIImage?, symbol: String) {
        fallbackIconLabel.text = String(symbol.prefix(1))

        guard let image else {
            logoImageView.image = nil
            logoImageView.isHidden = true
            fallbackIconLabel.isHidden = false
            return
        }

        logoImageView.image = image
        logoImageView.isHidden = false
        fallbackIconLabel.isHidden = true
    }
}
