//
//  ActionContext.swift
//  SwiftFlow
//
//  Context and result types for canvas action handlers.
//

import Foundation

// MARK: - Action Result

/// Result of an action handler indicating whether the action was handled
public enum ActionResult: Sendable {
    /// Action was handled, stop propagation to default handler
    case handled
    
    /// Action was not handled, use default implementation
    case notHandled
}

// MARK: - Canvas Action Context

/// Context passed to action handlers with current canvas state
public struct CanvasActionContext<Node: FlowNode, Edge: FlowEdge>: Sendable where Node: Sendable, Edge: Sendable {
    
    /// Currently selected node IDs
    public let selectedNodeIds: Set<UUID>
    
    /// Currently selected edge IDs
    public let selectedEdgeIds: Set<UUID>
    
    /// All nodes in the canvas
    public let nodes: [Node]
    
    /// All edges in the canvas
    public let edges: [Edge]
    
    /// Nodes currently in clipboard (for paste operations)
    public let clipboardNodes: [Node]
    
    /// Edges currently in clipboard (for paste operations)
    public let clipboardEdges: [Edge]
    
    /// Whether there is data in the clipboard
    public var hasClipboardData: Bool {
        !clipboardNodes.isEmpty
    }
    
    /// Whether there are selected nodes
    public var hasSelection: Bool {
        !selectedNodeIds.isEmpty
    }
    
    /// Get selected nodes
    public var selectedNodes: [Node] {
        nodes.filter { selectedNodeIds.contains($0.id) }
    }
    
    /// Get selected edges
    public var selectedEdges: [Edge] {
        edges.filter { selectedEdgeIds.contains($0.id) }
    }
    
    // MARK: - Initialization
    
    public init(
        selectedNodeIds: Set<UUID>,
        selectedEdgeIds: Set<UUID>,
        nodes: [Node],
        edges: [Edge],
        clipboardNodes: [Node] = [],
        clipboardEdges: [Edge] = []
    ) {
        self.selectedNodeIds = selectedNodeIds
        self.selectedEdgeIds = selectedEdgeIds
        self.nodes = nodes
        self.edges = edges
        self.clipboardNodes = clipboardNodes
        self.clipboardEdges = clipboardEdges
    }
}

// MARK: - Type Aliases

/// Type alias for action handler closures
public typealias CanvasActionHandler<Node: FlowNode, Edge: FlowEdge> =
    @MainActor (CanvasAction, CanvasActionContext<Node, Edge>) -> ActionResult
