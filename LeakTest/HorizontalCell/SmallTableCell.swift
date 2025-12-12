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
    var items: [Int] = (0..<6).map { $0 }
    var currentItemSize: CGSize = .init(width: 124, height: 60)
    var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var buttonMore: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        buttonMore.clipsToBounds = true
        buttonMore.layer.cornerRadius = buttonMore.frame.height / 2.0
        
        // 세로 스크롤 비활성화 (가로 스크롤은 orthogonalScrollingBehavior로 처리)
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
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        let yPos = collectionView.frame.origin.y
        
        // 레이아웃 계산
        collectionView.frame = CGRect(x: 0, y: 0, width: targetSize.width, height: CGFloat(MAXFLOAT))
        collectionView.layoutIfNeeded()
        
        // 현재 레이아웃된 높이
        let currentLayoutHeight = collectionView.collectionViewLayout.collectionViewContentSize.height
        
        // 모든 아이템의 최대 높이 계산
        var maxCalculatedHeight: CGFloat = currentLayoutHeight
        
        // contentInsets 반영 (top: 16, bottom: 16)
        let verticalInsets: CGFloat = 16 + 16
        
        // snapshot에서 아이템 개수 확인
        if let snapshot = dataSource?.snapshot() {
            let itemCount = snapshot.numberOfItems(inSection: .main)
            
            // 첫 번째 셀의 기본 높이 측정 (index=0일 때)
            if itemCount > 0, let firstCell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) {
                let firstCellHeight = firstCell.frame.height
                
                let baseCellHeight = firstCellHeight
                
                // 모든 인덱스에 대해 높이 계산
                var maxCellHeight: CGFloat = 0
                for index in 0..<itemCount {
                    let calculatedHeight = baseCellHeight + CGFloat(index) * 30.0
                    maxCellHeight = max(maxCellHeight, calculatedHeight)
                }
                
                // 최대 셀 높이 + contentInsets
                maxCalculatedHeight = max(maxCalculatedHeight, maxCellHeight + verticalInsets)
            } else {
                // 첫 번째 셀이 없으면 layoutAttributes로 기본 높이 추정
                if let layoutAttributes = collectionView.layoutAttributesForItem(at: IndexPath(item: 0, section: 0)) {
                    let baseCellHeight = layoutAttributes.frame.height
                    
                    var maxCellHeight: CGFloat = 0
                    for index in 0..<itemCount {
                        let calculatedHeight = baseCellHeight + CGFloat(index) * 30.0
                        maxCellHeight = max(maxCellHeight, calculatedHeight)
                    }
                    
                    // 최대 셀 높이 + contentInsets
                    maxCalculatedHeight = max(maxCalculatedHeight, maxCellHeight + verticalInsets)
                }
            }
        }
        
        let newSize = CGSize(width: targetSize.width, height: yPos + maxCalculatedHeight + buttonMore.frame.height)
        return newSize
    }
}
