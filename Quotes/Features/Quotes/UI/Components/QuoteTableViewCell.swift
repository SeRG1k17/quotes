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
        static let rowHeight: CGFloat = 60
        static let horizontalInset: CGFloat = 14
        static let iconSize: CGFloat = 24
        static let iconToTextSpacing: CGFloat = 7
        static let columnsSpacing: CGFloat = 10
        static let rightInset: CGFloat = 3
        static let contentVerticalInset: CGFloat = 7
        static let rowsSpacing: CGFloat = 3
        static let badgeHorizontalPadding: CGFloat = 1
        static let badgeVerticalPadding: CGFloat = 1
        static let flashHoldDuration: TimeInterval = 2
    }

    private let logoImageView = UIImageView()
    private let fallbackIconLabel = PaddingLabel()

    private let symbolLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let percentLabel = PaddingLabel()
    private let valueLabel = UILabel()

    private var representedSymbol = ""
    private var flashResetWorkItem: DispatchWorkItem?
    private var isFlashActive = false

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
        flashResetWorkItem?.cancel()
        flashResetWorkItem = nil
        isFlashActive = false
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

        contentView.addSubviews(
            logoImageView,
            fallbackIconLabel,
            symbolLabel,
            subtitleLabel,
            percentLabel,
            valueLabel
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

        percentLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        percentLabel.textAlignment = .center
        percentLabel.layer.cornerRadius = 7
        percentLabel.layer.masksToBounds = true
        percentLabel.backgroundColor = .color.clear
        percentLabel.insets = UIEdgeInsets(
            top: Metrics.badgeVerticalPadding,
            left: Metrics.badgeHorizontalPadding,
            bottom: Metrics.badgeVerticalPadding,
            right: Metrics.badgeHorizontalPadding
        )
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
            $0.top.equalToSuperview().inset(Metrics.contentVerticalInset)
        }

        valueLabel.snp.makeConstraints {
            $0.trailing.equalTo(percentLabel)
            $0.bottom.equalToSuperview().inset(Metrics.contentVerticalInset)
            $0.top.greaterThanOrEqualTo(percentLabel.snp.bottom).offset(Metrics.rowsSpacing)
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
        percentLabel.textColor = isFlashActive ? .color.white : appearance.textColor
    }

    func applyPriceFlash(flashDirection: QuoteDirection?, finalDirection: QuoteDirection, symbol: String) {
        guard let flashDirection else { return }

        flashChangeBadge(
            for: flashDirection,
            finalDirection: finalDirection,
            symbol: symbol
        )
    }

    func flashChangeBadge(
        for changeDirection: QuoteDirection,
        finalDirection: QuoteDirection,
        symbol: String
    ) {
        let changeAppearance = QuoteDirectionAppearance.forDirection(changeDirection)
        let finalAppearance = QuoteDirectionAppearance.forDirection(finalDirection)

        flashResetWorkItem?.cancel()
        flashResetWorkItem = nil
        isFlashActive = true
        percentLabel.layer.removeAllAnimations()
        percentLabel.backgroundColor = changeAppearance.textColor
        percentLabel.textColor = .color.white

        let resetWorkItem = DispatchWorkItem { [weak self] in
            guard let self, self.isRepresenting(symbol) else { return }
            self.percentLabel.backgroundColor = .color.clear
            self.isFlashActive = false
            self.flashResetWorkItem = nil
            self.percentLabel.textColor = finalAppearance.textColor
        }

        flashResetWorkItem = resetWorkItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + Metrics.flashHoldDuration,
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
