//
//  SelectionManager.swift
//  SwiftFlow
//
//  Manages node and edge selection state.
//

import Foundation
import SwiftUI
import Combine

/// Manages selection state for nodes and edges
@MainActor
public class SelectionManager: ObservableObject {
    // MARK: - Published Properties
    
    /// IDs of currently selected nodes
    @Published public private(set) var selectedNodes: Set<UUID> = []
    
    /// IDs of currently selected edges
    @Published public private(set) var selectedEdges: Set<UUID> = []
    
    // MARK: - Configuration
    
    /// Whether multi-selection is enabled
    public var enableMultiSelection: Bool
    
    // MARK: - Callbacks
    
    /// Called when selection changes
    public var onSelectionChanged: ((Set<UUID>, Set<UUID>) -> Void)?
    
    // MARK: - Initialization
    
    public init(enableMultiSelection: Bool = true) {
        self.enableMultiSelection = enableMultiSelection
    }
    
    // MARK: - Node Selection
    
    /// Select a node
    /// - Parameters:
    ///   - nodeId: ID of the node to select
    ///   - additive: If true, add to existing selection. If false, replace selection.
    public func selectNode(_ nodeId: UUID, additive: Bool = false) {
        if additive && enableMultiSelection {
            selectedNodes.insert(nodeId)
        } else {
            selectedNodes = [nodeId]
            selectedEdges = []
        }
        notifySelectionChanged()
    }
    
    /// Select multiple nodes
    /// - Parameters:
    ///   - nodeIds: IDs of nodes to select
    ///   - additive: If true, add to existing selection. If false, replace selection.
    public func selectNodes(_ nodeIds: Set<UUID>, additive: Bool = false) {
        if additive && enableMultiSelection {
            selectedNodes.formUnion(nodeIds)
        } else {
            selectedNodes = nodeIds
            selectedEdges = []
        }
        notifySelectionChanged()
    }
    
    /// Deselect a node
    /// - Parameter nodeId: ID of the node to deselect
    public func deselectNode(_ nodeId: UUID) {
        selectedNodes.remove(nodeId)
        notifySelectionChanged()
    }
    
    /// Toggle selection of a node
    /// - Parameter nodeId: ID of the node to toggle
    public func toggleNodeSelection(_ nodeId: UUID) {
        if selectedNodes.contains(nodeId) {
            if enableMultiSelection {
                selectedNodes.remove(nodeId)
            }
        } else {
            if enableMultiSelection {
                selectedNodes.insert(nodeId)
            } else {
                selectedNodes = [nodeId]
                selectedEdges = []
            }
        }
        notifySelectionChanged()
    }
    
    /// Check if a node is selected
    /// - Parameter nodeId: ID of the node to check
    /// - Returns: True if the node is selected
    public func isNodeSelected(_ nodeId: UUID) -> Bool {
        selectedNodes.contains(nodeId)
    }
    
    // MARK: - Edge Selection
    
    /// Select an edge
    /// - Parameters:
    ///   - edgeId: ID of the edge to select
    ///   - additive: If true, add to existing selection. If false, replace selection.
    public func selectEdge(_ edgeId: UUID, additive: Bool = false) {
        if additive && enableMultiSelection {
            selectedEdges.insert(edgeId)
        } else {
            selectedEdges = [edgeId]
            selectedNodes = []
        }
        notifySelectionChanged()
    }
    
    /// Check if an edge is selected
    /// - Parameter edgeId: ID of the edge to check
    /// - Returns: True if the edge is selected
    public func isEdgeSelected(_ edgeId: UUID) -> Bool {
        selectedEdges.contains(edgeId)
    }
    
    // MARK: - Clear Selection
    
    /// Clear all selections
    public func clearSelection() {
        guard !selectedNodes.isEmpty || !selectedEdges.isEmpty else { return }
        selectedNodes = []
        selectedEdges = []
        notifySelectionChanged()
    }
    
    /// Clear node selection only
    public func clearNodeSelection() {
        guard !selectedNodes.isEmpty else { return }
        selectedNodes = []
        notifySelectionChanged()
    }
    
    /// Clear edge selection only
    public func clearEdgeSelection() {
        guard !selectedEdges.isEmpty else { return }
        selectedEdges = []
        notifySelectionChanged()
    }
    
    // MARK: - Box Selection
    
    /// Select all nodes within a rectangle
    /// - Parameters:
    ///   - rect: Selection rectangle in canvas coordinates
    ///   - nodes: All nodes to check
    ///   - additive: If true, add to existing selection
    public func selectNodesInRect<Node: FlowNode>(
        _ rect: CGRect,
        nodes: [Node],
        additive: Bool = false
    ) {
        let nodesInRect = nodes.filter { node in
            rect.intersects(node.bounds)
        }
        
        let nodeIds = Set(nodesInRect.map(\.id))
        selectNodes(nodeIds, additive: additive)
    }
    
    // MARK: - Helpers
    
    /// Whether anything is selected
    public var hasSelection: Bool {
        !selectedNodes.isEmpty || !selectedEdges.isEmpty
    }
    
    /// Total count of selected items
    public var selectionCount: Int {
        selectedNodes.count + selectedEdges.count
    }
    
    /// Whether only a single node is selected
    public var hasSingleNodeSelected: Bool {
        selectedNodes.count == 1 && selectedEdges.isEmpty
    }
    
    /// Get the single selected node ID (if only one is selected)
    public var singleSelectedNodeId: UUID? {
        hasSingleNodeSelected ? selectedNodes.first : nil
    }
    
    // MARK: - Private
    
    private func notifySelectionChanged() {
        onSelectionChanged?(selectedNodes, selectedEdges)
    }
}
