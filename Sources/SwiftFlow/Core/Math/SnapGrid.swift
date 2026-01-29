//
//  SnapGrid.swift
//  SwiftFlow
//
//  Utilities for snapping positions to a grid.
//

import Foundation
import CoreGraphics

/// Provides grid snapping functionality for node positions
public struct SnapGrid: Equatable, Sendable {
    /// Size of each grid cell
    public let size: CGFloat
    
    public init(size: CGFloat = 20) {
        self.size = max(1, size) // Ensure positive grid size
    }
    
    /// Snap a point to the nearest grid intersection
    /// - Parameter point: Point to snap
    /// - Returns: Snapped point
    public func snap(_ point: CGPoint) -> CGPoint {
        return CGPoint(
            x: round(point.x / size) * size,
            y: round(point.y / size) * size
        )
    }
    
    /// Snap a single value to the grid
    /// - Parameter value: Value to snap
    /// - Returns: Snapped value
    public func snap(_ value: CGFloat) -> CGFloat {
        return round(value / size) * size
    }
    
    /// Snap a size to the grid
    /// - Parameter size: Size to snap
    /// - Returns: Snapped size
    public func snap(_ size: CGSize) -> CGSize {
        return CGSize(
            width: snap(size.width),
            height: snap(size.height)
        )
    }
    
    /// Check if a point is on the grid
    /// - Parameter point: Point to check
    /// - Returns: True if point is on a grid intersection
    public func isOnGrid(_ point: CGPoint) -> Bool {
        let snapped = snap(point)
        return abs(snapped.x - point.x) < 0.01 && abs(snapped.y - point.y) < 0.01
    }
}

// MARK: - Multi-Node Snap Utilities

public extension SnapGrid {
    /// Calculate snap offset for multiple nodes using the first node as reference.
    /// COORDINATE SYSTEM: All positions are top-left in canvas coordinates.
    /// - Parameters:
    ///   - startPositions: Original node positions (top-left in canvas space)
    ///   - distances: Offset from cursor to each node's top-left corner.
    ///                Formula: distance = nodeTopLeft - cursorPosition
    ///                This maintains the grab point during drag.
    ///   - currentMousePos: Current mouse position in canvas coordinates
    /// - Returns: Adjusted offset that snaps the reference node to grid
    func calculateMultiNodeSnapOffset(
        startPositions: [UUID: CGPoint],
        distances: [UUID: CGSize],
        currentMousePos: CGPoint
    ) -> CGSize {
        // Use the first node as reference
        guard let (refId, refStartPos) = startPositions.first else {
            return .zero
        }

        // Get offset for reference node (distance from cursor to node's top-left)
        let refDistance = distances[refId] ?? .zero

        // COORDINATE FIX: Calculate reference node's top-left position
        // Since distance = nodeTopLeft - cursor, we have:
        // nodeTopLeft = cursor + distance
        let refNewPos = CGPoint(
            x: currentMousePos.x + refDistance.width,
            y: currentMousePos.y + refDistance.height
        )

        // Snap that top-left position to grid
        let snappedRefPos = snap(refNewPos)

        // Return the offset needed to move from start position to snapped position
        return CGSize(
            width: snappedRefPos.x - refStartPos.x,
            height: snappedRefPos.y - refStartPos.y
        )
    }
}
