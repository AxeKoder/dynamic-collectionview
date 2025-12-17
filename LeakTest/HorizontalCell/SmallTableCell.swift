//
//  SmallTableCell.swift
//  LeakTest
//
//  Created by Parkdaeho on 12/1/25.
//

import UIKit

enum Section {
  case main
}

enum Item: Hashable {
  case a(String)
  case b(String)
}

final class SmallTableCell: UITableViewCell {
    static let identifier = "SmallTableCell"
    var items: [Int] = (0..<5).map { $0 }
    var currentItemSize: CGSize = .init(width: 124, height: 60)
    var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    var maxCellHeight: CGFloat = 0
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var buttonMore: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        buttonMore.clipsToBounds = true
        buttonMore.layer.cornerRadius = buttonMore.frame.height / 2.0
        
        collectionView.alwaysBounceVertical = false
        collectionView.showsVerticalScrollIndicator = false
        
        configureCollectionView()
        configureDataSource()
        applySnapshot()
        
        // 옵저버 등록
        NotificationCenter.default.addObserver(self, selector: #selector(addItem(_:)), name: NSNotification.Name("AddItem"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(removeItem(_:)), name: NSNotification.Name("RemoveItem"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(resize(_:)), name: NSNotification.Name("Resize"), object: nil)
    }
    
    func setupUI() {
        collectionView.layoutSubviews()
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
        removeOneCell()
    }
    
    private func fetchAddItems() {
        Task {
            try await Task.sleep(nanoseconds: 400_000_000)
            await MainActor.run {
                addTwoCells()
            }
        }
    }
    
    func configureCollectionView() {
        // XIB 등록 - 이 코드가 없으면 Storyboard cell을 사용하려고 시도함
        let nib = UINib(nibName: "BCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: BCell.identifier)
        
        let layout = UICollectionViewCompositionalLayout { _, _ in
            let leadingInset: CGFloat = 16
            let spacing: CGFloat = 10
            
            // 아이템 높이를 estimated로 설정하여 콘텐츠에 맞게 자동 조절
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(100)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            // 그룹 너비를 계산된 cellWidth로 설정
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(0.38),
                heightDimension: .estimated(100)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            section.interGroupSpacing = spacing
            section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: leadingInset, bottom: 16, trailing: 16)
            return section
        }
        collectionView.collectionViewLayout = layout
    }
    
    func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) {
            (collectionView, indexPath, item) -> UICollectionViewCell? in
            
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: BCell.identifier, for: indexPath) as? BCell else { return nil }
            cell.setData(indexPath.row)
            return cell
        }
    }
    
    func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(
            items.map {
                Item.a("\($0)")
            }
        )
        dataSource.apply(snapshot, animatingDifferences: false) {
            self.collectionView.layoutSubviews()
        }
    }
    
    /// 2개의 셀을 동일한 텍스트(사이즈)로 추가하는 메소드
    func addTwoCells(with text: String = "New Item") {
        var snapshot = dataSource.snapshot()
        let timestamp = Date().timeIntervalSince1970
        // 고유한 식별자를 위해 timestamp 활용
        snapshot.appendItems([
            .a("\(text) - \(Int(timestamp * 1000) % 10000)"),
            .a("\(text) - \(Int(timestamp * 1000) % 10000 + 1)")
        ])
        dataSource.apply(snapshot, animatingDifferences: true) {
            self.collectionView.layoutSubviews()
            NotificationCenter.default.post(name: NSNotification.Name("PerformBatchUpdate"), object: nil, userInfo: nil)
        }
    }
    
    func removeOneCell() {
        var snapshot = dataSource.snapshot()
        guard let lastItem = snapshot.itemIdentifiers.last else { return }
        snapshot.deleteItems([lastItem])
        dataSource.apply(snapshot, animatingDifferences: true) {
            NotificationCenter.default.post(name: NSNotification.Name("PerformBatchUpdate"), object: nil, userInfo: nil)
        }
    }
}

// MARK: - DynamicCollectionViewTableCell Protocol
extension SmallTableCell: DynamicCollectionViewTableCell {
    
    var collectionViewVerticalInsets: CGFloat {
        return 32.0
    }
    
    var dynamicCollectionView: UICollectionView {
        return collectionView
    }
    
    func additionalHeight(for targetSize: CGSize) -> CGFloat {
        return titleLabel.frame.height + buttonMore.frame.height
    }
    
    func calculateCellWidth(targetSize: CGSize) -> CGFloat {
        // 레이아웃과 동일한 로직: 0.38 fractionalWidth
        return targetSize.width * 0.38
    }
    
    func measureCellHeight(at index: Int, cellWidth: CGFloat) -> CGFloat? {
        return measureCellHeightFromNib(nibName: "BCell", cellWidth: cellWidth) { (cell: BCell) in
            cell.setData(index)
        }
    }
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        return calculateDynamicHeight(targetSize: targetSize)
    }
}
