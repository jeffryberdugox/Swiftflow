//
//  SelectionState.swift
//  SwiftFlow
//
//  Represents the selection state of nodes and edges.
//

import Foundation
import CoreGraphics

/// Represents the current selection state in the canvas
public struct SelectionState: Equatable, Sendable {
    /// IDs of selected nodes
    public var selectedNodes: Set<UUID>
    
    /// IDs of selected edges
    public var selectedEdges: Set<UUID>
    
    /// Active selection rectangle (for box selection)
    public var selectionRect: CGRect?
    
    /// Whether a box selection is in progress
    public var isBoxSelecting: Bool {
        selectionRect != nil
    }
    
    public init(
        selectedNodes: Set<UUID> = [],
        selectedEdges: Set<UUID> = [],
        selectionRect: CGRect? = nil
    ) {
        self.selectedNodes = selectedNodes
        self.selectedEdges = selectedEdges
        self.selectionRect = selectionRect
    }
    
    /// Check if a node is selected
    /// - Parameter nodeId: ID of the node to check
    /// - Returns: True if the node is selected
    public func isNodeSelected(_ nodeId: UUID) -> Bool {
        selectedNodes.contains(nodeId)
    }
    
    /// Check if an edge is selected
    /// - Parameter edgeId: ID of the edge to check
    /// - Returns: True if the edge is selected
    public func isEdgeSelected(_ edgeId: UUID) -> Bool {
        selectedEdges.contains(edgeId)
    }
    
    /// Whether anything is selected
    public var hasSelection: Bool {
        !selectedNodes.isEmpty || !selectedEdges.isEmpty
    }
    
    /// Total count of selected items
    public var selectionCount: Int {
        selectedNodes.count + selectedEdges.count
    }
}
