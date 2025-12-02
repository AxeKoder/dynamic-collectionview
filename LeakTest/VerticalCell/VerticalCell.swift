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
    @IBOutlet weak var stackViewWidth: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    func setupUI(index: Int) {
        stackViewWidth.constant = UIScreen.main.bounds.width
        stackView.arrangedSubviews.enumerated().forEach { i, item in
            if i > 0 {
                item.isHidden = i > index
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
