//
//  BCell.swift
//  LeakTest
//
//  Created by Parkdaeho on 12/1/25.
//

import UIKit

final class BCell: UICollectionViewCell {
    static let identifier = "BCell"
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var blackView: UIView!
    @IBOutlet weak var yellowView: UIView!
    
    private var index = 0
    lazy var subview: UIView = {
        let subview = UIView()
        subview.backgroundColor = .orange
        return subview
    }()
    
    lazy var subviewHeightConstraint: NSLayoutConstraint = {
        return subview.heightAnchor.constraint(equalToConstant: CGFloat(index) * 30.0)
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func setData(_ index: Int) {
        self.index = index
        let title = String(index)
        titleLabel.text = title
        blackView.isHidden = true
        yellowView.isHidden = true
        
        stackView.addArrangedSubview(subview)
        subviewHeightConstraint.constant = CGFloat(index) * 30.0
        subviewHeightConstraint.isActive = true
    }
    
    
    @IBAction func removeLast(_ sender: Any) {
        guard let last = stackView.arrangedSubviews.last else {
            return
        }
        last.isHidden = true
    }
}
