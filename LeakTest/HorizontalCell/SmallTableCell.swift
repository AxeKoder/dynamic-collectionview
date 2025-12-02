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
  var items: [Int] = [0]
  var currentItemSize: CGSize = .init(width: 124, height: 60)
  var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
  
  @IBOutlet weak var collectionView: ResizingHeightCollectionView!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    //        collectionView.delegate = self
    //        collectionView.dataSource = self
    //        collectionView.contentInset = .zero
    //        let layout = TopAlignedCollectionViewFlowLayout()
    //        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
    //        layout.scrollDirection = .horizontal
    //        layout.minimumInteritemSpacing = 4
    //        layout.minimumLineSpacing = 4
    //        collectionView.collectionViewLayout = layout
    
    configureCollectionView()
    configureDataSource()
    applySnapshot()
    
    // 옵저버 등록
    NotificationCenter.default.addObserver(self, selector: #selector(addItem(_:)), name: NSNotification.Name("AddItem"), object: nil)
    
    NotificationCenter.default.addObserver(self, selector: #selector(removeItem(_:)), name: NSNotification.Name("RemoveItem"), object: nil)
    
    NotificationCenter.default.addObserver(self, selector: #selector(resize(_:)), name: NSNotification.Name("Resize"), object: nil)
  }
  
  func setupUI() {
//    collectionView.performBatchUpdates({})
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
    addTwoCells()
  }
  
  @objc func removeItem(_ notification: Notification) {
    removeOneCell()
  }
  
  
  func configureCollectionView() {
    let layout = UICollectionViewCompositionalLayout { sectionIndex, environment in
      let containerWidth = environment.container.contentSize.width
      let leadingInset: CGFloat = 16
      let spacing: CGFloat = 10
      
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
        widthDimension: .absolute(cellWidth),
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
      cell.setData("\(indexPath.row)")
      return cell
    }
  }
  
  func applySnapshot() {
    var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
    snapshot.appendSections([.main])
    snapshot.appendItems([
      .a("Short text"),
      .b("This is a longer block of text that should demonstrate auto-resizing behavior in BCell."),
      .a("C")
    ])
    dataSource.apply(snapshot, animatingDifferences: true)
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
    dataSource.apply(snapshot, animatingDifferences: true)
//    NotificationCenter.default.post(name: NSNotification.Name("PerformBatchUpdate"), object: nil, userInfo: nil)
  }
  
  func removeOneCell() {
    var snapshot = dataSource.snapshot()
    guard let lastItem = snapshot.itemIdentifiers.last else { return }
    snapshot.deleteItems([lastItem])
    dataSource.apply(snapshot, animatingDifferences: true)
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
