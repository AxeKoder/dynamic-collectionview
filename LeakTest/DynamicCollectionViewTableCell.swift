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
    
}

extension DynamicCollectionViewTableCell {
    
    /// 기본 구현: 추가 높이 없음
    func additionalHeight(for targetSize: CGSize) -> CGFloat {
        return 0
    }
    
    // MARK: - Dynamic Height Calculation
    
    /// 동적 높이 계산 (모든 아이템의 최대 높이 반영)
    func calculateDynamicHeight(targetSize: CGSize) -> CGSize {
        // 레이아웃 계산
        dynamicCollectionView.frame = CGRect(x: 0, y: 0, width: targetSize.width, height: CGFloat(MAXFLOAT))
        dynamicCollectionView.layoutIfNeeded()
        
        // 현재 레이아웃된 높이
        let currentLayoutHeight = dynamicCollectionView.collectionViewLayout.collectionViewContentSize.height
        
        let totalHeight = currentLayoutHeight + additionalHeight(for: targetSize)
        return CGSize(width: targetSize.width, height: totalHeight)
    }
}

