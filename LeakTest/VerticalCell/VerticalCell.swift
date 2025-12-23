//
//  VerticalCell.swift
//  LeakTest
//
//  Created by Parkdaeho on 12/1/25.
//

import UIKit

class VerticalCell: UICollectionViewCell {
    static let identifier: String = "VerticalCell"
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var bottomViewHeight: NSLayoutConstraint!
    
    func setupUI(index: Int) {
        bottomViewHeight.constant = CGFloat(index + 1) * 14.0
    }
    
    func addCreatedView() -> UIView {
        let view = UIView()
        view.backgroundColor = .systemPink
        stackView.addArrangedSubview(view)
        return view
    }
}
