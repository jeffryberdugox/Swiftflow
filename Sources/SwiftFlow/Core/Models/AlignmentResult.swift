//
//  AlignmentResult.swift
//  SwiftFlow
//
//  Result of alignment calculation for helper lines.
//

import Foundation
import CoreGraphics

/// Result of alignment calculation during node dragging.
public struct AlignmentResult: Equatable, Sendable {
    
    /// Horizontal guide lines (Y positions in canvas coordinates)
    public var horizontalGuides: [CGFloat]
    
    /// Vertical guide lines (X positions in canvas coordinates)
    public var verticalGuides: [CGFloat]
    
    /// Snap offset to apply if snapToGuides is enabled
    public var snapOffset: CGSize
    
    /// Whether any alignment was detected
    public var hasAlignment: Bool {
        !horizontalGuides.isEmpty || !verticalGuides.isEmpty
    }
    
    // MARK: - Initialization
    
    public init(
        horizontalGuides: [CGFloat] = [],
        verticalGuides: [CGFloat] = [],
        snapOffset: CGSize = .zero
    ) {
        self.horizontalGuides = horizontalGuides
        self.verticalGuides = verticalGuides
        self.snapOffset = snapOffset
    }
    
    /// Empty result (no alignment detected)
    public static let empty = AlignmentResult()
}
