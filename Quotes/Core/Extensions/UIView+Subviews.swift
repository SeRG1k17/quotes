//
//  UIView+Subviews.swift
//  Quotes
//
//  Created by s pugach on 9.03.26.
//

import UIKit

extension UIView {
    func addSubviews(_ views: UIView...) {
        views.forEach(addSubview)
    }
}
