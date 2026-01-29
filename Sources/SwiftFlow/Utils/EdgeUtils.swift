//
//  EdgeUtils.swift
//  SwiftFlow
//
//  Utility functions for working with edges.
//

import Foundation

// MARK: - Connection Validation

/// Validate if a connection between two nodes/ports is valid
/// - Parameters:
///   - sourceNode: Source node ID
///   - sourcePort: Source port ID
///   - targetNode: Target node ID
///   - targetPort: Target port ID
///   - existingEdges: Array of existing edges
///   - allowSelfConnection: Whether to allow connecting a node to itself
///   - allowMultipleConnections: Whether to allow multiple connections between same ports
/// - Returns: True if connection is valid
public func isValidConnection(
    sourceNode: UUID,
    sourcePort: UUID,
    targetNode: UUID,
    targetPort: UUID,
    existingEdges: [any FlowEdge],
    allowSelfConnection: Bool = false,
    allowMultipleConnections: Bool = false
) -> Bool {
    // Check self-connection
    if !allowSelfConnection && sourceNode == targetNode {
        return false
    }
    
    // Check duplicate connection
    if !allowMultipleConnections {
        let isDuplicate = existingEdges.contains { edge in
            edge.sourceNodeId == sourceNode &&
            edge.sourcePortId == sourcePort &&
            edge.targetNodeId == targetNode &&
            edge.targetPortId == targetPort
        }
        
        if isDuplicate {
            return false
        }
    }
    
    return true
}

// MARK: - Add Edge

/// Add an edge to the edges array with validation
/// - Parameters:
///   - edge: Edge to add
///   - edges: Current edges array
///   - allowDuplicates: Whether to allow duplicate edges
/// - Returns: New edges array with edge added, or original if invalid
public func addEdge<Edge: FlowEdge>(
    _ edge: Edge,
    to edges: [Edge],
    allowDuplicates: Bool = false
) -> [Edge] {
    // Check for duplicates if not allowed
    if !allowDuplicates {
        let isDuplicate = edges.contains { existing in
            existing.sourceNodeId == edge.sourceNodeId &&
            existing.sourcePortId == edge.sourcePortId &&
            existing.targetNodeId == edge.targetNodeId &&
            existing.targetPortId == edge.targetPortId
        }
        
        if isDuplicate {
            return edges
        }
    }
    
    var result = edges
    result.append(edge)
    return result
}

// MARK: - Get Connected Edges

/// Get all edges connected to specific nodes
/// - Parameters:
///   - nodes: Array of nodes (or node IDs)
///   - edges: Array of edges to search
/// - Returns: Array of edges connected to any of the nodes
public func getConnectedEdges<Node: FlowNode, Edge: FlowEdge>(
    nodes: [Node],
    edges: [Edge]
) -> [Edge] {
    let nodeIds = Set(nodes.map { $0.id })
    
    return edges.filter { edge in
        nodeIds.contains(edge.sourceNodeId) ||
        nodeIds.contains(edge.targetNodeId)
    }
}

/// Get all edges connected to a specific node
/// - Parameters:
///   - node: Node to check
///   - edges: Array of edges to search
/// - Returns: Array of edges connected to the node
public func getConnectedEdges<Node: FlowNode, Edge: FlowEdge>(
    node: Node,
    edges: [Edge]
) -> [Edge] {
    return getConnectedEdges(nodes: [node], edges: edges)
}

// MARK: - Get Incomers/Outgoers

/// Get all nodes that have edges pointing to the given node (upstream nodes)
/// - Parameters:
///   - node: Target node
///   - nodes: Array of all nodes
///   - edges: Array of all edges
/// - Returns: Array of nodes that connect to the target node
public func getIncomers<Node: FlowNode>(
    node: Node,
    nodes: [Node],
    edges: [any FlowEdge]
) -> [Node] {
    let incomingEdges = edges.filter { $0.targetNodeId == node.id }
    let sourceNodeIds = Set(incomingEdges.map { $0.sourceNodeId })
    
    return nodes.filter { sourceNodeIds.contains($0.id) }
}

/// Get all nodes that the given node points to (downstream nodes)
/// - Parameters:
///   - node: Source node
///   - nodes: Array of all nodes
///   - edges: Array of all edges
/// - Returns: Array of nodes that the source node connects to
public func getOutgoers<Node: FlowNode>(
    node: Node,
    nodes: [Node],
    edges: [any FlowEdge]
) -> [Node] {
    let outgoingEdges = edges.filter { $0.sourceNodeId == node.id }
    let targetNodeIds = Set(outgoingEdges.map { $0.targetNodeId })
    
    return nodes.filter { targetNodeIds.contains($0.id) }
}

// MARK: - Edge Reconnection

/// Reconnect an edge to a new source or target
/// Note: This returns the edge IDs for recreation. FlowEdge protocol properties are readonly.
/// - Parameters:
///   - edge: Edge to reconnect
///   - newSourceNode: New source node ID (nil to keep current)
///   - newSourcePort: New source port ID (nil to keep current)
///   - newTargetNode: New target node ID (nil to keep current)
///   - newTargetPort: New target port ID (nil to keep current)
/// - Returns: Tuple with updated connection IDs
public func reconnectEdge(
    _ edge: any FlowEdge,
    newSourceNode: UUID? = nil,
    newSourcePort: UUID? = nil,
    newTargetNode: UUID? = nil,
    newTargetPort: UUID? = nil
) -> (sourceNodeId: UUID, sourcePortId: UUID, targetNodeId: UUID, targetPortId: UUID) {
    return (
        sourceNodeId: newSourceNode ?? edge.sourceNodeId,
        sourcePortId: newSourcePort ?? edge.sourcePortId,
        targetNodeId: newTargetNode ?? edge.targetNodeId,
        targetPortId: newTargetPort ?? edge.targetPortId
    )
}

// MARK: - Type Guards

/// Check if an element is a node
public func isNode(_ element: Any) -> Bool {
    return element is any FlowNode
}

/// Check if an element is an edge
public func isEdge(_ element: Any) -> Bool {
    return element is any FlowEdge
}
