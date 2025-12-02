//
//  LargeTableCell.swift
//  LeakTest
//
//  Created by Parkdaeho on 12/1/25.
//

import UIKit

final class LargeTableCell: UITableViewCell {
    
    var items: [Int] = [0]
    
    static let identifier = "LargeTableCell"
    @IBOutlet weak var collectionView: ResizingHeightCollectionView!
    
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
    }
    
    @objc func fetchAsync(_ notification: Notification) {
        Task {
            try await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
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
