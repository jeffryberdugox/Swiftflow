//
//  DragState.swift
//  SwiftFlow
//
//  Represents the state of a node drag operation.
//

import Foundation
import CoreGraphics

/// Represents the state of an active drag operation on one or more nodes.
public struct DragState: Equatable, Sendable {
    /// IDs of nodes being dragged
    public var draggedNodes: Set<UUID>
    
    /// Original positions (top-left) of nodes when drag started (key: node ID).
    /// All positions are in canvas coordinates.
    public var startPositions: [UUID: CGPoint]
    
    /// Offset from cursor to each node's top-left corner (canvas coordinates).
    /// CRITICAL: This maintains the grab point relative to the node.
    /// Formula: offset = nodeTopLeft - cursorPosition
    /// Example: If you click near the top-left, offset will be small; if you click near center, offset will be ~(width/2, height/2)
    public var distances: [UUID: CGSize]
    
    /// Current drag offset from start position
    public var currentOffset: CGSize
    
    /// Whether the drag has moved beyond the threshold
    public var hasMoved: Bool
    
    /// Starting point of the drag in canvas coordinates
    public var startPoint: CGPoint
    
    public init(
        draggedNodes: Set<UUID>,
        startPositions: [UUID: CGPoint],
        distances: [UUID: CGSize] = [:],
        currentOffset: CGSize = .zero,
        hasMoved: Bool = false,
        startPoint: CGPoint = .zero
    ) {
        self.draggedNodes = draggedNodes
        self.startPositions = startPositions
        self.distances = distances
        self.currentOffset = currentOffset
        self.hasMoved = hasMoved
        self.startPoint = startPoint
    }
    
    /// Calculate the new position (top-left) for a node.
    /// Uses the offset from cursor to node's top-left for accurate positioning.
    /// Formula: newTopLeft = currentCursor + offset
    /// - Parameter nodeId: ID of the node
    /// - Returns: New position or nil if node is not being dragged
    public func newPosition(for nodeId: UUID) -> CGPoint? {
        guard let startPosition = startPositions[nodeId] else { return nil }
        
        // If distances are available, use them for correct positioning
        if let distance = distances[nodeId] {
            // Current cursor position in canvas coords
            let currentMousePos = CGPoint(
                x: startPoint.x + currentOffset.width,
                y: startPoint.y + currentOffset.height
            )
            
            // Node top-left = cursor + offset (where offset = topLeft - cursor)
            return CGPoint(
                x: currentMousePos.x + distance.width,
                y: currentMousePos.y + distance.height
            )
        }
        
        // Fallback to simple offset (less accurate)
        return CGPoint(
            x: startPosition.x + currentOffset.width,
            y: startPosition.y + currentOffset.height
        )
    }
    
    /// Calculate all new positions for dragged nodes
    /// - Returns: Dictionary mapping node IDs to their new positions
    public func allNewPositions() -> [UUID: CGPoint] {
        var positions: [UUID: CGPoint] = [:]
        
        for nodeId in draggedNodes {
            if let newPos = newPosition(for: nodeId) {
                positions[nodeId] = newPos
            }
        }
        
        return positions
    }
}
