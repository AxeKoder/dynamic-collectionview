//
//  DynamicCollectionViewTableCell.swift
//  LeakTest
//
//  Created by Parkdaeho on 12/17/25.
//

import UIKit

/// CollectionView를 포함한 TableViewCell의 동적 높이 계산을 지원하는 프로토콜
protocol DynamicCollectionViewTableCell: UITableViewCell {
    /// 높이를 계산할 collectionView
    var dynamicCollectionView: UICollectionView { get }
    
    /// collectionView 외에 추가로 계산해야 할 높이 (버튼, 여백 등)
    /// - Parameter targetSize: 타겟 사이즈
    /// - Returns: 추가 높이
    func additionalHeight(for targetSize: CGSize) -> CGFloat
    
    /// 그룹(셀) 너비를 계산하는 메서드
    /// - Parameter targetSize: 타겟 사이즈
    /// - Returns: 셀의 너비
    func calculateCellWidth(targetSize: CGSize) -> CGFloat
    
    /// contentInsets의 vertical 값 (top + bottom)
    var collectionViewVerticalInsets: CGFloat { get }
    
    /// 특정 인덱스의 셀 높이를 측정하는 메서드
    /// - Parameters:
    ///   - index: 셀 인덱스
    ///   - cellWidth: 셀의 너비
    /// - Returns: 측정된 셀 높이 (측정 불가 시 nil)
    func measureCellHeight(at index: Int, cellWidth: CGFloat) -> CGFloat?
}

extension DynamicCollectionViewTableCell {
    
    // MARK: - Default Implementations
    var collectionViewVerticalInsets: CGFloat {
        return 0
    }
    
    /// 기본 구현: 추가 높이 없음
    func additionalHeight(for targetSize: CGSize) -> CGFloat {
        return 0
    }
    
    /// 기본 구현: 전체 너비 사용
    func calculateCellWidth(targetSize: CGSize) -> CGFloat {
        return targetSize.width
    }
    
    // MARK: - Helper Methods
    
    /// XIB에서 셀을 로드하고 높이를 측정하는 헬퍼 메서드
    /// - Parameters:
    ///   - nibName: XIB 파일 이름
    ///   - cellWidth: 셀의 너비
    ///   - configure: 셀에 데이터를 설정하는 클로저
    /// - Returns: 측정된 셀 높이
    func measureCellHeightFromNib<T: UICollectionViewCell>(
        nibName: String,
        cellWidth: CGFloat,
        configure: (T) -> Void
    ) -> CGFloat? {
        guard let cells = Bundle.main.loadNibNamed(nibName, owner: nil, options: nil),
              let cell = cells.first as? T else {
            return nil
        }
        
        // 셀 설정
        cell.frame = CGRect(origin: .zero, size: CGSize(width: cellWidth, height: 1))
        configure(cell)
        cell.layoutIfNeeded()
        
        // 높이 측정
        let size = cell.systemLayoutSizeFitting(
            CGSize(width: cellWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        
        return size.height
    }
    
    // MARK: - Dynamic Height Calculation
    
    /// 동적 높이 계산 (모든 아이템의 최대 높이 반영)
    func calculateDynamicHeight(targetSize: CGSize) -> CGSize {
        // 레이아웃 계산
        dynamicCollectionView.frame = CGRect(x: 0, y: 0, width: targetSize.width, height: CGFloat(MAXFLOAT))
        dynamicCollectionView.layoutIfNeeded()
        
        // 현재 레이아웃된 높이
        let currentLayoutHeight = dynamicCollectionView.collectionViewLayout.collectionViewContentSize.height
        
        // 모든 아이템의 최대 높이 계산
        var maxCalculatedHeight: CGFloat = 0
        if dynamicCollectionView.numberOfSections > 0 {
            let itemCount = dynamicCollectionView.numberOfItems(inSection: 0)
            maxCalculatedHeight = calculateMaxHeight(
                itemCount: itemCount,
                currentHeight: currentLayoutHeight,
                targetSize: targetSize
            )
        }
        
        let totalHeight = maxCalculatedHeight + additionalHeight(for: targetSize)
        return CGSize(width: targetSize.width, height: totalHeight)
    }
    
    private func calculateMaxHeight(itemCount: Int, currentHeight: CGFloat, targetSize: CGSize) -> CGFloat {
        guard itemCount > 0 else { return currentHeight }
        
        var maxCalculatedHeight = currentHeight
        var maxCellHeight: CGFloat = 0
        
        let cellWidth = calculateCellWidth(targetSize: targetSize)
        
        // 모든 인덱스에 대해 실제 셀 높이 측정
        for index in 0..<itemCount {
            if let measuredHeight = measureCellHeight(at: index, cellWidth: cellWidth) {
                maxCellHeight = max(maxCellHeight, measuredHeight)
            }
        }
        
        // 최대 셀 높이 + contentInsets
        if maxCellHeight > 0 {
            maxCalculatedHeight = max(maxCalculatedHeight, maxCellHeight + collectionViewVerticalInsets)
        }
        
        return maxCalculatedHeight
    }
}

