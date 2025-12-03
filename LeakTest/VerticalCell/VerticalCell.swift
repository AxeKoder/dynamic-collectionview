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
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    func setupUI(index: Int) {
        (0..<index).forEach {
            if $0 < stackView.arrangedSubviews.count {
                stackView.arrangedSubviews[$0].isHidden = false
            }
        }
    }
    
    func addCreatedView() -> UIView {
        let view = UIView()
        view.backgroundColor = .systemPink
        stackView.addArrangedSubview(view)
        return view
    }
}
