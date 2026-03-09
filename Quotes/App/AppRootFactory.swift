//
//  AppRootFactory.swift
//  Quotes
//
//  Created by s pugach on 9.03.26.
//

import UIKit

@MainActor
enum AppRootFactory {
    static func makeRootViewController() -> UIViewController {
        let quotesRoot = QuotesFeatureAssembly.makeRootViewController()
        return UINavigationController(rootViewController: quotesRoot)
    }
}
