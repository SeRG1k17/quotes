//
//  ColorAsset.swift
//  Quotes
//
//  Created by s pugach on 9.03.26.
//

import UIKit

extension UIColor {
    static let color = ColorAsset()
}

struct ColorAsset {
    let clear = UIColor.clear
    let white = UIColor.white
    let quoteUp = UIColor(red: 106 / 255, green: 186 / 255, blue: 70 / 255, alpha: 1)
    let quoteDown = UIColor(red: 238 / 255, green: 76 / 255, blue: 101 / 255, alpha: 1)
    let quoteNeutral = UIColor(red: 157 / 255, green: 161 / 255, blue: 169 / 255, alpha: 1)
    let quoteUpFlash = UIColor(red: 106 / 255, green: 186 / 255, blue: 70 / 255, alpha: 0.2)
    let quoteDownFlash = UIColor(red: 238 / 255, green: 76 / 255, blue: 101 / 255, alpha: 0.2)
    let quoteListAccessory = UIColor(red: 193 / 255, green: 197 / 255, blue: 205 / 255, alpha: 1)
    let quoteListSeparator = UIColor(red: 234 / 255, green: 236 / 255, blue: 240 / 255, alpha: 1)
    let quoteListFallbackIconBackground = UIColor(red: 237 / 255, green: 240 / 255, blue: 244 / 255, alpha: 1)
    let quoteListFallbackIconText = UIColor(red: 105 / 255, green: 112 / 255, blue: 122 / 255, alpha: 1)
    let quoteListSymbolText = UIColor(red: 45 / 255, green: 49 / 255, blue: 55 / 255, alpha: 1)
    let quoteListSubtitleText = UIColor(red: 156 / 255, green: 161 / 255, blue: 170 / 255, alpha: 1)
    let quoteListValueText = UIColor(red: 44 / 255, green: 47 / 255, blue: 52 / 255, alpha: 1)
}
