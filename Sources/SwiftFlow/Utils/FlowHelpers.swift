//
//  FlowHelpers.swift
//  SwiftFlow
//
//  High-level helper functions and store-like facade for canvas operations.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Flow Store Facade

/// High-level store-like facade for reactive flow operations
/// Provides reactive API surface for flow operations
@MainActor
public class FlowStore<Node: FlowNode, Edge: FlowEdge>: ObservableObject {
    
    // MARK: - Published State
    
    /// All nodes in the flow
    @Published public var nodes: [Node]
    
    /// All edges in the flow
    @Published public var edges: [Edge]
    
    /// Selected node IDs
    @Published public var selectedNodes: Set<UUID> = []
    
    /// Selected edge IDs
    @Published public var selectedEdges: Set<UUID> = []
    
    /// Current viewport transform
    @Published public var viewport: FlowTransform = FlowTransform()
    
    /// Whether a drag operation is active
    @Published public var isDragging: Bool = false
    
    /// Whether a connection is being created
    @Published public var isConnecting: Bool = false
    
    /// Current connection preview (if any)
    @Published public var connectionInProgress: ConnectionState?
    
    // MARK: - Initialization
    
    public init(nodes: [Node] = [], edges: [Edge] = []) {
        self.nodes = nodes
        self.edges = edges
    }
    
    // MARK: - Node Operations
    
    /// Get all nodes (reactive)
    public func getNodes() -> [Node] {
        return nodes
    }
    
    /// Set nodes array
    public func setNodes(_ newNodes: [Node]) {
        nodes = newNodes
    }
    
    /// Add a single node
    public func addNode(_ node: Node) {
        nodes.append(node)
    }
    
    /// Add multiple nodes
    public func addNodes(_ nodesToAdd: [Node]) {
        nodes.append(contentsOf: nodesToAdd)
    }
    
    /// Remove nodes by IDs
    public func removeNodes(_ ids: Set<UUID>) {
        nodes.removeAll { ids.contains($0.id) }
        // Also remove connected edges
        edges.removeAll { edge in
            ids.contains(edge.sourceNodeId) || ids.contains(edge.targetNodeId)
        }
    }
    
    /// Get a specific node by ID
    public func getNode(id: UUID) -> Node? {
        return nodes.first { $0.id == id }
    }
    
    /// Update a node
    public func updateNode(id: UUID, update: (Node) -> Node) {
        if let index = nodes.firstIndex(where: { $0.id == id }) {
            nodes[index] = update(nodes[index])
        }
    }
    
    /// Get nodes data (filtered by IDs)
    public func getNodesData(ids: Set<UUID>) -> [Node] {
        return nodes.filter { ids.contains($0.id) }
    }
    
    // MARK: - Edge Operations
    
    /// Get all edges (reactive)
    public func getEdges() -> [Edge] {
        return edges
    }
    
    /// Set edges array
    public func setEdges(_ newEdges: [Edge]) {
        edges = newEdges
    }
    
    /// Add a single edge
    public func addEdge(_ edge: Edge) {
        edges.append(edge)
    }
    
    /// Add multiple edges
    public func addEdges(_ edgesToAdd: [Edge]) {
        edges.append(contentsOf: edgesToAdd)
    }
    
    /// Remove edges by IDs
    public func removeEdges(_ ids: Set<UUID>) {
        edges.removeAll { ids.contains($0.id) }
    }
    
    /// Get a specific edge by ID
    public func getEdge(id: UUID) -> Edge? {
        return edges.first { $0.id == id }
    }
    
    /// Update an edge
    public func updateEdge(id: UUID, update: (Edge) -> Edge) {
        if let index = edges.firstIndex(where: { $0.id == id }) {
            edges[index] = update(edges[index])
        }
    }
    
    /// Get edges data (filtered by IDs)
    public func getEdgesData(ids: Set<UUID>) -> [Edge] {
        return edges.filter { ids.contains($0.id) }
    }
    
    // MARK: - Graph Queries
    
    /// Get connected edges for nodes
    public func getConnectedEdges(nodeIds: Set<UUID>) -> [Edge] {
        return edges.filter { edge in
            nodeIds.contains(edge.sourceNodeId) || nodeIds.contains(edge.targetNodeId)
        }
    }
    
    /// Get incoming nodes (upstream)
    public func getIncomers(nodeId: UUID) -> [Node] {
        guard let node = getNode(id: nodeId) else { return [] }
        return SwiftFlow.getIncomers(node: node, nodes: nodes, edges: edges)
    }
    
    /// Get outgoing nodes (downstream)
    public func getOutgoers(nodeId: UUID) -> [Node] {
        guard let node = getNode(id: nodeId) else { return [] }
        return SwiftFlow.getOutgoers(node: node, nodes: nodes, edges: edges)
    }
    
    /// Get nodes intersecting with a node
    public func getIntersectingNodes(nodeId: UUID) -> [Node] {
        guard let node = getNode(id: nodeId) else { return [] }
        return SwiftFlow.getIntersectingNodes(node: node, nodes: nodes)
    }
    
    /// Get nodes in a rectangular area
    public func getNodesInside(rect: CGRect, partially: Bool = true) -> [Node] {
        return SwiftFlow.getNodesInRect(rect: rect, nodes: nodes, partially: partially)
    }
    
    // MARK: - Selection Operations
    
    /// Select a node
    public func selectNode(_ id: UUID, additive: Bool = false) {
        if additive {
            selectedNodes.insert(id)
        } else {
            selectedNodes = [id]
            selectedEdges = []
        }
    }
    
    /// Select multiple nodes
    public func selectNodes(_ ids: Set<UUID>, additive: Bool = false) {
        if additive {
            selectedNodes.formUnion(ids)
        } else {
            selectedNodes = ids
            selectedEdges = []
        }
    }
    
    /// Select an edge
    public func selectEdge(_ id: UUID, additive: Bool = false) {
        if additive {
            selectedEdges.insert(id)
        } else {
            selectedEdges = [id]
            selectedNodes = []
        }
    }
    
    /// Select all nodes and edges
    public func selectAll() {
        selectedNodes = Set(nodes.map { $0.id })
        selectedEdges = Set(edges.map { $0.id })
    }
    
    /// Clear selection
    public func clearSelection() {
        selectedNodes = []
        selectedEdges = []
    }
    
    /// Get selected nodes
    public func getSelectedNodes() -> [Node] {
        return nodes.filter { selectedNodes.contains($0.id) }
    }
    
    /// Get selected edges
    public func getSelectedEdges() -> [Edge] {
        return edges.filter { selectedEdges.contains($0.id) }
    }
    
    // MARK: - Viewport Operations
    
    /// Set viewport transform
    public func setViewport(_ transform: FlowTransform) {
        viewport = transform
    }
    
    /// Get current viewport
    public func getViewport() -> FlowTransform {
        return viewport
    }
    
    /// Convert screen point to canvas coordinates
    public func screenToCanvas(_ point: CGPoint) -> CGPoint {
        return SwiftFlow.screenToCanvas(point: point, transform: viewport)
    }
    
    /// Convert canvas point to screen coordinates
    public func canvasToScreen(_ point: CGPoint) -> CGPoint {
        return SwiftFlow.canvasToScreen(point: point, transform: viewport)
    }
    
    // MARK: - State Export/Import
    
    /// Export flow state to dictionary
    public func toObject() -> [String: Any] {
        return [
            "nodes": nodes.map { ["id": $0.id.uuidString, "x": $0.position.x, "y": $0.position.y] },
            "edges": edges.map { ["id": $0.id.uuidString] },
            "viewport": [
                "x": viewport.offset.x,
                "y": viewport.offset.y,
                "zoom": viewport.scale
            ],
            "selectedNodes": Array(selectedNodes.map { $0.uuidString }),
            "selectedEdges": Array(selectedEdges.map { $0.uuidString })
        ]
    }
}

// MARK: - Reactive Helpers

/// Helper to observe nodes data reactively
@MainActor
public class NodesDataObserver<Node: FlowNode>: ObservableObject {
    @Published public var nodes: [Node]
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(store: FlowStore<Node, some FlowEdge>) {
        self.nodes = store.nodes
        
        store.$nodes
            .sink { [weak self] newNodes in
                self?.nodes = newNodes
            }
            .store(in: &cancellables)
    }
    
    public func get(id: UUID) -> Node? {
        return nodes.first { $0.id == id }
    }
}

/// Helper to observe edges data reactively
@MainActor
public class EdgesDataObserver<Edge: FlowEdge>: ObservableObject {
    @Published public var edges: [Edge]
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(store: FlowStore<some FlowNode, Edge>) {
        self.edges = store.edges
        
        store.$edges
            .sink { [weak self] newEdges in
                self?.edges = newEdges
            }
            .store(in: &cancellables)
    }
    
    public func get(id: UUID) -> Edge? {
        return edges.first { $0.id == id }
    }
}

/// Helper to observe viewport reactively
@MainActor
public class ViewportObserver: ObservableObject {
    @Published public var viewport: FlowTransform
    
    private var cancellables = Set<AnyCancellable>()
    
    public init<Node: FlowNode, Edge: FlowEdge>(store: FlowStore<Node, Edge>) {
        self.viewport = store.viewport
        
        store.$viewport
            .sink { [weak self] newViewport in
                self?.viewport = newViewport
            }
            .store(in: &cancellables)
    }
}

/// Helper to observe selection reactively
@MainActor
public class SelectionObserver: ObservableObject {
    @Published public var selectedNodes: Set<UUID>
    @Published public var selectedEdges: Set<UUID>
    
    private var cancellables = Set<AnyCancellable>()
    
    public init<Node: FlowNode, Edge: FlowEdge>(store: FlowStore<Node, Edge>) {
        self.selectedNodes = store.selectedNodes
        self.selectedEdges = store.selectedEdges
        
        store.$selectedNodes
            .sink { [weak self] newSelection in
                self?.selectedNodes = newSelection
            }
            .store(in: &cancellables)
        
        store.$selectedEdges
            .sink { [weak self] newSelection in
                self?.selectedEdges = newSelection
            }
            .store(in: &cancellables)
    }
    
    public var hasSelection: Bool {
        return !selectedNodes.isEmpty || !selectedEdges.isEmpty
    }
}

// MARK: - Global Utility Functions

/// Check if nodes are initialized (have dimensions)
public func areNodesInitialized<Node: FlowNode>(_ nodes: [Node]) -> Bool {
    guard !nodes.isEmpty else { return false }
    return nodes.allSatisfy { $0.width > 0 && $0.height > 0 }
}

/// Get nodes that are currently visible in viewport
public func getVisibleNodes<Node: FlowNode>(
    nodes: [Node],
    viewport: FlowTransform,
    viewportSize: CGSize,
    padding: CGFloat = 50
) -> [Node] {
    let visibleRect = CGRect(
        x: -viewport.offset.x / viewport.scale - padding,
        y: -viewport.offset.y / viewport.scale - padding,
        width: viewportSize.width / viewport.scale + padding * 2,
        height: viewportSize.height / viewport.scale + padding * 2
    )
    
    return getNodesInRect(rect: visibleRect, nodes: nodes, partially: true)
}
