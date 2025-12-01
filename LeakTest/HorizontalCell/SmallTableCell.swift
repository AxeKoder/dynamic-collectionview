//
//  SmallTableCell.swift
//  LeakTest
//
//  Created by Parkdaeho on 12/1/25.
//

import UIKit

final class SmallTableCell: UITableViewCell {
    static let identifier = "SmallTableCell"
    var items: [Int] = [0, 1, 2]
    var currentItemSize: CGSize = .init(width: 124, height: 60)
    
    @IBOutlet weak var collectionView: DynamicHeightCollectionView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = .zero
        let layout = TopAlignedCollectionViewFlowLayout()
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4
        collectionView.collectionViewLayout = layout
        
        // 옵저버 등록
        NotificationCenter.default.addObserver(self, selector: #selector(addItem(_:)), name: NSNotification.Name("AddItem"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(removeItem(_:)), name: NSNotification.Name("RemoveItem"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(resize(_:)), name: NSNotification.Name("Resize"), object: nil)
    }
    
    func setupUI() {
        collectionView.reloadData()
    }
    
    private func fetchAddItems() {
        Task {
            try await Task.sleep(nanoseconds: 400_000_000)
            self.items.append(contentsOf: (0..<10).map { $0 + self.items.count })
            await MainActor.run {
                self.collectionView.reloadData()
                NotificationCenter.default.post(name: NSNotification.Name("PerformBatchUpdate"), object: nil, userInfo: nil)
            }
        }
    }
    
    @objc func resize(_ notification: Notification) {
        currentItemSize = .init(
            width: currentItemSize.width * 0.96,
            height: currentItemSize.height * 0.96
        )
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize = currentItemSize
        NotificationCenter.default.post(name: NSNotification.Name("PerformBatchUpdate"), object: nil, userInfo: nil)
    }
    
    @objc func addItem(_ notification: Notification) {
        fetchAddItems()
    }
    
    @objc func removeItem(_ notification: Notification) {
        items.removeLast()
        collectionView.reloadData()
    }
}

extension SmallTableCell: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: BCell.identifier,
            for: indexPath
        ) as? BCell else {
            return .init()
        }
        cell.setData("\(items[indexPath.row])")
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        print("cell.frame = \(cell.frame)")
    }
}
