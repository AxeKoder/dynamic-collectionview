//
//  SmallTableCell.swift
//  LeakTest
//
//  Created by Parkdaeho on 12/1/25.
//

import UIKit

final class SmallTableCell: UITableViewCell {
    static let identifier = "SmallTableCell"
    var items: [Int] = [0]
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
        collectionView.performBatchUpdates({})
    }
    
    private func fetchAddItems() {
        Task {
            try await Task.sleep(nanoseconds: 400_000_000)
            await MainActor.run {
                performInsert()
            }
        }
    }
    
    private func performInsert() {
        let startIndex = self.items.count
        self.collectionView.performBatchUpdates({
            let newItems = (0..<3).map { $0 + self.items.count }
            self.items.insert(contentsOf: newItems, at: startIndex)
            let indexPaths = (0..<newItems.count).map {
                IndexPath(item: startIndex + $0, section: 0)
            }
            self.collectionView.insertItems(at: indexPaths)
        })
        NotificationCenter.default.post(name: NSNotification.Name("PerformBatchUpdate"), object: nil, userInfo: nil)
    }
    
    private func reloadInserting() {
        let startIndex = self.items.count
        let newItems = (0..<12).map { $0 + self.items.count }
        items.insert(contentsOf: newItems, at: startIndex)
        collectionView.reloadData()
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
        guard !items.isEmpty else { return }
        let removeIndex = items.count - 1
        collectionView.performBatchUpdates({
            items.remove(at: removeIndex)
            collectionView.deleteItems(at: [
                .init(item: removeIndex, section: 0)
            ])
        })
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
}
