//
//  LargeTableCell.swift
//  LeakTest
//
//  Created by Parkdaeho on 12/1/25.
//

import UIKit

final class LargeTableCell: UITableViewCell {
    
    var items: [Int] = [0]
    var isMoreVisible: Bool = false
    
    static let identifier = "LargeTableCell"
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var buttonMore: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.dataSource = self
        collectionView.delegate = self
        let layout = UICollectionViewFlowLayout()
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 4
        layout.minimumInteritemSpacing = 4
        collectionView.collectionViewLayout = layout
        
//        // 옵저버 등록
//        NotificationCenter.default.addObserver(self, selector: #selector(fetchAsync(_:)), name: NSNotification.Name("AddItem"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData(_:)), name: NSNotification.Name("ReloadData"), object: nil)
        
        // 옵저버 등록
        NotificationCenter.default.addObserver(self, selector: #selector(addItem(_:)), name: NSNotification.Name("AddItem"), object: nil)
    }
    
    @objc func addItem(_ notification: Notification) {
        fetchAsync()
    }
    
    func fetchAsync() {
        Task {
            try await Task.sleep(nanoseconds: 400_000_000)
            await MainActor.run {
                self.buttonMore.isHidden.toggle()
                self.collectionView.performBatchUpdates({
                    self.items.append(contentsOf: (0..<1).map { $0 + self.items.count })
                    self.collectionView.insertItems(at: [
                        IndexPath(item: self.items.count - 1, section: 0)
                    ])
                })
                Task {
                    await MainActor.run {
                        NotificationCenter.default.post(name: NSNotification.Name("PerformBatchUpdate"), object: nil, userInfo: nil)
                    }
                }
            }
        }
    }
    
    @objc func reloadData(_ notificaiton: Notification) {
        collectionView.reloadData()
    }
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        collectionView.frame = CGRect(x: 0, y: 0, width: targetSize.width, height: CGFloat(MAXFLOAT))
        collectionView.layoutIfNeeded()
        let size = collectionView.collectionViewLayout.collectionViewContentSize
        let newSize = CGSize(width: size.width, height: size.height + stackView.frame.height)
        return newSize
    }
}

extension LargeTableCell: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: VerticalCell.identifier,
            for: indexPath
        ) as? VerticalCell else {
            return .init()
        }
        cell.setupUI(index: indexPath.row)
        return cell
    }
    
}
