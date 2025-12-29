//
//  LargeTableCell.swift
//  LeakTest
//
//  Created by Parkdaeho on 12/1/25.
//

import UIKit

enum VerticalSection {
    case main
}

enum VerticalItem: Hashable {
    case a(String)
}

final class LargeTableCell: UITableViewCell {
    static let identifier = "LargeTableCell"
    
    var cellIndex: Int = 0
    var items: [Int] = (0..<24).map { $0 }
    var dataSource: UICollectionViewDiffableDataSource<VerticalSection, VerticalItem>!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var buttonMore: UIButton!
  
    override func awakeFromNib() {
        super.awakeFromNib()
        buttonMore.clipsToBounds = true
        buttonMore.layer.cornerRadius = 6
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceVertical = false
        
        configureCollectionView()
        configureDataSource()
        
        
        // 옵저버 등록
        NotificationCenter.default.addObserver(self, selector: #selector(addItem(_:)), name: NSNotification.Name("AddItem"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData(_:)), name: NSNotification.Name("ReloadData"), object: nil)
    }
    
    @objc func addItem(_ notification: Notification) {
        fetchAsync()
    }
    
    func fetchAsync() {
        Task {
            try await Task.sleep(nanoseconds: 600_000_000)
            await MainActor.run {
                addTwoCells()
            }
        }
    }
    
    func setData(_ index: Int) {
        self.cellIndex = index
        applySnapshot()
    }
    
    @objc func reloadData(_ notificaiton: Notification) {
        collectionView.reloadData()
    }
    
    func configureCollectionView() {
        let nib = UINib(nibName: "VerticalCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: VerticalCell.identifier)
        
        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment in
            let containerWidth = environment.container.contentSize.width
            let leadingInset: CGFloat = 16
            let spacing: CGFloat = 10
            
            let cellWidth = (containerWidth - leadingInset - (2 * spacing)) / 2.0
            
            // 아이템 높이를 estimated로 설정하여 콘텐츠에 맞게 자동 조절
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(cellWidth),
                heightDimension: .estimated(100)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            // 그룹 너비를 계산된 cellWidth로 설정
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(100)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            group.interItemSpacing = .fixed(spacing)
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
            return section
        }
        collectionView.collectionViewLayout = layout
    }
    
    func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<VerticalSection, VerticalItem>(collectionView: collectionView) {
            (collectionView, indexPath, item) -> UICollectionViewCell? in
            
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: VerticalCell.identifier, for: indexPath) as? VerticalCell else { return nil }
            cell.setupUI(index: indexPath.row)
            return cell
        }
    }
    
    func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<VerticalSection, VerticalItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(
            items.map { .a("\($0)") }
        )
        dataSource.apply(snapshot, animatingDifferences: true)
        
    }
    
    func addTwoCells(with text: String = "New Item") {
        items.append(items.count)
        var snapshot = dataSource.snapshot()
        let timestamp = Date().timeIntervalSince1970
        // 고유한 식별자를 위해 timestamp 활용
        snapshot.appendItems([
            .a("\(text) - \(Int(timestamp * 1000) % 10000)")
        ])
        dataSource.apply(snapshot, animatingDifferences: true) {
            NotificationCenter.default.post(name: NSNotification.Name("PerformBatchUpdate"), object: nil, userInfo: nil)

        }
    }
    
}

// MARK: - DynamicCollectionViewTableCell Protocol
extension LargeTableCell: DynamicCollectionViewTableCell {
    
    var dynamicCollectionView: UICollectionView {
        return collectionView
    }
    
    func additionalHeight(for targetSize: CGSize) -> CGFloat {
        return buttonMore.frame.height
    }
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        return calculateDynamicHeight(targetSize: targetSize)
    }
}
