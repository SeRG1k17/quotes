//
//  PaddingLabel.swift
//  Quotes
//
//  Created by s pugach on 5.03.26.
//

import UIKit

final class PaddingLabel: UILabel {
    var insets = UIEdgeInsets.zero

    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let insetBounds = bounds.inset(by: insets)
        let textRect = super.textRect(forBounds: insetBounds, limitedToNumberOfLines: numberOfLines)

        let inverseInsets = UIEdgeInsets(
            top: -insets.top,
            left: -insets.left,
            bottom: -insets.bottom,
            right: -insets.right
        )
        return textRect.inset(by: inverseInsets)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + insets.left + insets.right,
            height: size.height + insets.top + insets.bottom
        )
    }
}
