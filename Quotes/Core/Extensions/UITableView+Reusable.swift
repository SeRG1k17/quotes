//
//  UITableView+Reusable.swift
//  Quotes
//
//  Created by s pugach on 9.03.26.
//

import UIKit

protocol ReusableCell: AnyObject {
    static var reuseIdentifier: String { get }
}

extension ReusableCell where Self: UITableViewCell {
    static var reuseIdentifier: String {
        String(describing: Self.self)
    }
}

extension UITableView {
    func register<Cell: UITableViewCell>(_ cellType: Cell.Type) where Cell: ReusableCell {
        register(cellType, forCellReuseIdentifier: cellType.reuseIdentifier)
    }

    func dequeueReusableCell<Cell: UITableViewCell>(
        _ cellType: Cell.Type,
        for indexPath: IndexPath
    ) -> Cell where Cell: ReusableCell {
        guard let cell = dequeueReusableCell(withIdentifier: cellType.reuseIdentifier, for: indexPath) as? Cell else {
            fatalError("Failed to dequeue cell with identifier \(cellType.reuseIdentifier)")
        }
        return cell
    }
}
