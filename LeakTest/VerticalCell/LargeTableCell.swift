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
    var items: [Int] = [0]
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
        applySnapshot()
        
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
    }
    
    @objc func reloadData(_ notificaiton: Notification) {
        collectionView.reloadData()
    }
    
    func configureCollectionView() {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment in
            let containerWidth = environment.container.contentSize.width
            let leadingInset: CGFloat = 16
            let spacing: CGFloat = 0
            
            // 2.5개 셀 + 2개 간격이 보이도록 계산
            // 보이는 영역 = containerWidth - leadingInset
            // 2.5 * cellWidth + 2 * spacing = containerWidth - leadingInset
            let cellWidth = (containerWidth - leadingInset - (2 * spacing)) / 2.5
            
            // 아이템 높이를 estimated로 설정하여 콘텐츠에 맞게 자동 조절
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(100)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            // 그룹 너비를 계산된 cellWidth로 설정
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(100)
            )
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = spacing
            section.contentInsets = NSDirectionalEdgeInsets.zero
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
        snapshot.appendItems([
            .a("Short text")
        ])
        dataSource.apply(snapshot, animatingDifferences: true) {
            NotificationCenter.default.post(name: NSNotification.Name("PerformBatchUpdate"), object: nil, userInfo: nil)
        }
        
    }
    
    func addTwoCells(with text: String = "New Item") {
        var snapshot = dataSource.snapshot()
        let timestamp = Date().timeIntervalSince1970
        // 고유한 식별자를 위해 timestamp 활용
        snapshot.appendItems([
            .a("\(text) - \(Int(timestamp * 1000) % 10000)")
        ])
        dataSource.apply(snapshot, animatingDifferences: true) {
            print("applyCompletion: layoutContentSize: \(self.collectionView.collectionViewLayout.collectionViewContentSize)")
            print("applyCompletion: contentViewSize: \(self.contentView.frame.size)")
            NotificationCenter.default.post(name: NSNotification.Name("PerformBatchUpdate"), object: nil, userInfo: nil)
        }
    }
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        collectionView.frame = CGRect(x: 0, y: 0, width: targetSize.width, height: CGFloat(MAXFLOAT))
        collectionView.layoutIfNeeded()
        let size = collectionView.collectionViewLayout.collectionViewContentSize
        let newSize = CGSize(width: size.width, height: size.height + buttonMore.frame.height)
        return newSize
    }
    
}


