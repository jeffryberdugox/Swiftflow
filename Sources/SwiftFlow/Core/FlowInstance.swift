//
//  FlowInstance.swift
//  SwiftFlow
//
//  Central API object for programmatic control of the flow.
//

import Foundation
import SwiftUI

/// Central API object for controlling the flow programmatically
@MainActor
public class FlowInstance<Node: FlowNode, Edge: FlowEdge>: ObservableObject {
    
    // MARK: - Managers
    
    public let panZoomManager: PanZoomManager
    public let dragManager: DragManager
    public let selectionManager: SelectionManager
    public let connectionManager: ConnectionManager
    
    // MARK: - State Bindings
    
    @Binding private var nodes: [Node]
    @Binding private var edges: [Edge]
    
    // MARK: - Initialization
    
    public init(
        nodes: Binding<[Node]>,
        edges: Binding<[Edge]>,
        panZoomManager: PanZoomManager,
        dragManager: DragManager,
        selectionManager: SelectionManager,
        connectionManager: ConnectionManager
    ) {
        self._nodes = nodes
        self._edges = edges
        self.panZoomManager = panZoomManager
        self.dragManager = dragManager
        self.selectionManager = selectionManager
        self.connectionManager = connectionManager
    }
    
    // MARK: - Node Methods
    
    /// Get all nodes
    public func getNodes() -> [Node] {
        return nodes
    }
    
    /// Set nodes array
    public func setNodes(_ newNodes: [Node]) {
        nodes = newNodes
    }
    
    /// Set nodes using an update function
    public func setNodes(_ update: ([Node]) -> [Node]) {
        nodes = update(nodes)
    }
    
    /// Add a single node
    public func addNode(_ node: Node) {
        nodes.append(node)
    }
    
    /// Add multiple nodes
    public func addNodes(_ nodesToAdd: [Node]) {
        nodes.append(contentsOf: nodesToAdd)
    }
    
    /// Get a node by ID
    public func getNode(id: UUID) -> Node? {
        return nodes.first { $0.id == id }
    }
    
    /// Update a node
    public func updateNode(id: UUID, update: (Node) -> Node) {
        if let index = nodes.firstIndex(where: { $0.id == id }) {
            nodes[index] = update(nodes[index])
        }
    }
    
    /// Delete nodes by IDs
    public func deleteNodes(ids: Set<UUID>) {
        nodes.removeAll { ids.contains($0.id) }
        
        // Also remove connected edges
        edges.removeAll { edge in
            ids.contains(edge.sourceNodeId) || ids.contains(edge.targetNodeId)
        }
    }
    
    // MARK: - Edge Methods
    
    /// Get all edges
    public func getEdges() -> [Edge] {
        return edges
    }
    
    /// Set edges array
    public func setEdges(_ newEdges: [Edge]) {
        edges = newEdges
    }
    
    /// Set edges using an update function
    public func setEdges(_ update: ([Edge]) -> [Edge]) {
        edges = update(edges)
    }
    
    /// Add a single edge
    public func addEdge(_ edge: Edge) {
        edges.append(edge)
    }
    
    /// Add multiple edges
    public func addEdges(_ edgesToAdd: [Edge]) {
        edges.append(contentsOf: edgesToAdd)
    }
    
    /// Get an edge by ID
    public func getEdge(id: UUID) -> Edge? {
        return edges.first { $0.id == id }
    }
    
    /// Update an edge
    public func updateEdge(id: UUID, update: (Edge) -> Edge) {
        if let index = edges.firstIndex(where: { $0.id == id }) {
            edges[index] = update(edges[index])
        }
    }
    
    /// Delete edges by IDs
    public func deleteEdges(ids: Set<UUID>) {
        edges.removeAll { ids.contains($0.id) }
    }
    
    /// Delete elements (nodes and edges)
    public func deleteElements(nodeIds: Set<UUID> = [], edgeIds: Set<UUID> = []) {
        if !nodeIds.isEmpty {
            deleteNodes(ids: nodeIds)
        }
        
        if !edgeIds.isEmpty {
            deleteEdges(ids: edgeIds)
        }
    }
    
    // MARK: - Utility Methods
    
    /// Get edges connected to specific nodes
    public func getConnectedEdges(nodeIds: Set<UUID>) -> [Edge] {
        return edges.filter { edge in
            nodeIds.contains(edge.sourceNodeId) || nodeIds.contains(edge.targetNodeId)
        }
    }
    
    /// Get incoming nodes for a node (upstream)
    public func getIncomers(nodeId: UUID) -> [Node] {
        guard let node = getNode(id: nodeId) else { return [] }
        return SwiftFlow.getIncomers(node: node, nodes: nodes, edges: edges)
    }
    
    /// Get outgoing nodes for a node (downstream)
    public func getOutgoers(nodeId: UUID) -> [Node] {
        guard let node = getNode(id: nodeId) else { return [] }
        return SwiftFlow.getOutgoers(node: node, nodes: nodes, edges: edges)
    }
    
    /// Get nodes intersecting with a node
    public func getIntersectingNodes(nodeId: UUID) -> [Node] {
        guard let node = getNode(id: nodeId) else { return [] }
        return SwiftFlow.getIntersectingNodes(node: node, nodes: nodes)
    }
    
    /// Check if a node intersects with a rectangle
    public func isNodeIntersecting(nodeId: UUID, rect: CGRect) -> Bool {
        guard let node = getNode(id: nodeId) else { return false }
        return SwiftFlow.isNodeIntersecting(node: node, rect: rect)
    }
    
    /// Get nodes within a rectangular area
    public func getNodesInRect(_ rect: CGRect, partially: Bool = true) -> [Node] {
        return SwiftFlow.getNodesInRect(rect: rect, nodes: nodes, partially: partially)
    }
    
    // MARK: - Viewport Methods
    
    /// Zoom in
    public func zoomIn(factor: CGFloat = 1.2) {
        panZoomManager.zoomIn(factor: factor)
    }
    
    /// Zoom out
    public func zoomOut(factor: CGFloat = 0.8) {
        panZoomManager.zoomOut(factor: factor)
    }
    
    /// Zoom to a specific level
    public func zoomTo(scale: CGFloat) {
        let currentScale = panZoomManager.transform.scale
        let factor = scale / currentScale
        let center = CGPoint(
            x: panZoomManager.viewportSize.width / 2,
            y: panZoomManager.viewportSize.height / 2
        )
        panZoomManager.zoom(by: factor, at: center)
    }
    
    /// Fit all nodes in view
    public func fitView(padding: CGFloat = 50) {
        panZoomManager.fitNodes(nodes, padding: padding)
    }
    
    /// Fit specific nodes in view
    public func fitNodes(_ nodeIds: Set<UUID>, padding: CGFloat = 50) {
        let nodesToFit = nodes.filter { nodeIds.contains($0.id) }
        panZoomManager.fitNodes(nodesToFit, padding: padding)
    }
    
    /// Get current viewport
    public func getViewport() -> FlowTransform {
        return panZoomManager.transform
    }
    
    /// Set viewport
    public func setViewport(_ transform: FlowTransform) {
        panZoomManager.transform = transform
    }
    
    // MARK: - Selection Methods
    
    /// Get selected node IDs
    public func getSelectedNodes() -> Set<UUID> {
        return selectionManager.selectedNodes
    }
    
    /// Get selected edge IDs
    public func getSelectedEdges() -> Set<UUID> {
        return selectionManager.selectedEdges
    }
    
    /// Select nodes
    public func selectNodes(_ nodeIds: Set<UUID>, addToSelection: Bool = false) {
        if !addToSelection {
            selectionManager.clearSelection()
        }
        for id in nodeIds {
            selectionManager.selectNode(id)
        }
    }
    
    /// Select edges
    public func selectEdges(_ edgeIds: Set<UUID>, addToSelection: Bool = false) {
        if !addToSelection {
            selectionManager.clearSelection()
        }
        for id in edgeIds {
            selectionManager.selectEdge(id)
        }
    }
    
    /// Clear selection
    public func clearSelection() {
        selectionManager.clearSelection()
    }
    
    // MARK: - Export/Import
    
    /// Export flow to dictionary (for JSON serialization)
    /// Note: Only works if Node and Edge conform to Codable
    public func toObject() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["transform"] = [
            "offsetX": panZoomManager.transform.offset.x,
            "offsetY": panZoomManager.transform.offset.y,
            "scale": panZoomManager.transform.scale
        ]
        // Nodes and edges need to be serialized by the app
        return dict
    }
}

// MARK: - Convenience Extension

public extension CanvasView {
    /// Get the FlowInstance for programmatic control
    func flowInstance() -> FlowInstance<Node, Edge> {
        return FlowInstance(
            nodes: $nodes,
            edges: $edges,
            panZoomManager: panZoomManager,
            dragManager: dragManager,
            selectionManager: selectionManager,
            connectionManager: connectionManager
        )
    }
}
