//
//  DynamicHeightCollectionView.swift
//  LeakTest
//
//  Created by Parkdaeho on 11/28/25.
//

import UIKit

final class ResizingHeightCollectionView: UICollectionView {
    override func layoutSubviews() {
        super.layoutSubviews()
        if !__CGSizeEqualToSize(bounds.size, self.intrinsicContentSize) {
            self.invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
         return collectionViewLayout.collectionViewContentSize
    }
}

final class DynamicHeightCollectionView: UICollectionView {
    var maxHeight: CGFloat = 0

    override func layoutSubviews() {
        super.layoutSubviews()
        if !__CGSizeEqualToSize(bounds.size, self.intrinsicContentSize) {
            self.invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        // return collectionViewLayout.collectionViewContentSize
        let heights = visibleCells.map { $0.frame.size.height }
        maxHeight = heights.max() ?? 0
        return .init(
            width: collectionViewLayout.collectionViewContentSize.width,
            height: maxHeight
        )
    }
}

final class TopAlignedCollectionViewFlowLayout: UICollectionViewFlowLayout {

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let superAttributes = super.layoutAttributesForElements(in: rect) else { return nil }
        let attributes = NSArray(array: superAttributes, copyItems: true) as! [UICollectionViewLayoutAttributes]

        // Group attributes by line (if you have multiple lines in a horizontal layout)
        // For a single-line horizontal layout, this step might be simpler.
        var attributesByLine: [CGFloat: [UICollectionViewLayoutAttributes]] = [:]
        for attribute in attributes {
            if attribute.representedElementCategory == .cell {
                let lineY = attribute.frame.minY // Assuming horizontal scrolling, group by Y position
                if attributesByLine[lineY] == nil {
                    attributesByLine[lineY] = []
                }
                attributesByLine[lineY]?.append(attribute)
            }
        }

        // Adjust the Y position for top alignment within each line
        for (_, lineAttributes) in attributesByLine {
//            let minY = lineAttributes.reduce(CGFloat.greatestFiniteMagnitude) { min($0, $1.frame.minY) } // Find the top-most cell in the line

            for attribute in lineAttributes {
//                let deltaY = minY - attribute.frame.minY // Calculate difference to align to top
                attribute.frame.origin.y = 0
            }
        }

        return attributes
    }
}

