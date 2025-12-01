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
    @IBOutlet weak var stackViewWidth: NSLayoutConstraint!
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func setData(_ title: String) {
        stackViewWidth.constant = UIScreen.main.bounds.size.width / 2.3
        titleLabel.text = title
        blackView.isHidden = (Int(title) ?? 0) % 3 == 1
        yellowView.isHidden = (Int(title) ?? 0) % 2 == 1
    }
    
    @IBAction func removeLast(_ sender: Any) {
        guard let last = stackView.arrangedSubviews.last else {
            return
        }
        last.removeFromSuperview()
    }
}
