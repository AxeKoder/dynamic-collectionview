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
    var items: [Int] = []
    var currentItemSize: CGSize = .init(width: 124, height: 60)
    var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    var maxCellHeight: CGFloat = 0
    
    enum Constant {
        static let cellWidth: CGFloat = 224
    }
    
    
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
        
        // 옵저버 등록
        NotificationCenter.default.addObserver(self, selector: #selector(addItem(_:)), name: NSNotification.Name("AddItem"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(removeItem(_:)), name: NSNotification.Name("RemoveItem"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(resize(_:)), name: NSNotification.Name("Resize"), object: nil)
    }
    
    func setupUI() {
        if self.items.isEmpty {
            fetchItems()
        }
    }
    
    private func fetchItems() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            self.items = (0..<100).map { $0 }
            self.applySnapshot()
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
        removeOneCell()
    }
    
    private func fetchAddItems() {
        Task {
            try await Task.sleep(nanoseconds: 40_000_000)
            addTwoCells()
        }
    }
    
    func configureCollectionView() {
        // XIB 등록 - 이 코드가 없으면 Storyboard cell을 사용하려고 시도함
        let nib = UINib(nibName: "BCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: BCell.identifier)
        
        let layout = UICollectionViewCompositionalLayout { _, _ in
            let hGap: CGFloat = 10
            let spacing: CGFloat = 10
            
            // 아이템 높이를 estimated로 설정하여 콘텐츠에 맞게 자동 조절
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(100)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            // 그룹 너비를 계산된 cellWidth로 설정
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .absolute(Constant.cellWidth),
                heightDimension: .estimated(100)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .groupPaging
            section.interGroupSpacing = spacing
            section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: hGap, bottom: 16, trailing: hGap)
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
        dataSource.apply(snapshot, animatingDifferences: true) {
            NotificationCenter.default.post(name: NSNotification.Name("PerformBatchUpdate"), object: nil, userInfo: nil)
        }
    }
    
    /// 2개의 셀을 동일한 텍스트(사이즈)로 추가하는 메소드
    func addTwoCells(with text: String = "New Item") {
        items.append(items.count)
        applySnapshot()
    }
    
    func removeOneCell() {
        var snapshot = dataSource.snapshot()
        guard let lastItem = snapshot.itemIdentifiers.last else { return }
        snapshot.deleteItems([lastItem])
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

// MARK: - DynamicCollectionViewTableCell Protocol
extension SmallTableCell: DynamicCollectionViewTableCell {
    
    var dynamicCollectionView: UICollectionView {
        return collectionView
    }
    
    func additionalHeight(for targetSize: CGSize) -> CGFloat {
        return titleLabel.frame.height + buttonMore.frame.height
    }
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        return calculateDynamicHeight(targetSize: targetSize)
    }
}
