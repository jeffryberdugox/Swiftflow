//
//  NodeUtils.swift
//  SwiftFlow
//
//  Utility functions for working with nodes.
//

import Foundation

// MARK: - Node Intersection

/// Check if a node intersects with a given rect
/// - Parameters:
///   - node: Node to check
///   - rect: Rectangle to check intersection with
/// - Returns: True if node intersects with rect
public func isNodeIntersecting<Node: FlowNode>(
    node: Node,
    rect: CGRect
) -> Bool {
    let nodeRect = CGRect(
        x: node.position.x,
        y: node.position.y,
        width: node.width,
        height: node.height
    )
    
    return nodeRect.intersects(rect)
}

/// Get all nodes that intersect with a given node
/// - Parameters:
///   - node: Node to check
///   - nodes: Array of all nodes to check against
/// - Returns: Array of nodes that intersect with the given node
public func getIntersectingNodes<Node: FlowNode>(
    node: Node,
    nodes: [Node]
) -> [Node] {
    let nodeRect = CGRect(
        x: node.position.x,
        y: node.position.y,
        width: node.width,
        height: node.height
    )
    
    return nodes.filter { otherNode in
        guard otherNode.id != node.id else { return false }
        
        let otherRect = CGRect(
            x: otherNode.position.x,
            y: otherNode.position.y,
            width: otherNode.width,
            height: otherNode.height
        )
        
        return nodeRect.intersects(otherRect)
    }
}

/// Get all nodes within a rectangular selection area
/// - Parameters:
///   - rect: Selection rectangle
///   - nodes: Array of all nodes
///   - partially: Whether to include partially intersecting nodes (default: true)
/// - Returns: Array of nodes within the selection area
public func getNodesInRect<Node: FlowNode>(
    rect: CGRect,
    nodes: [Node],
    partially: Bool = true
) -> [Node] {
    return nodes.filter { node in
        let nodeRect = CGRect(
            x: node.position.x,
            y: node.position.y,
            width: node.width,
            height: node.height
        )
        
        if partially {
            return nodeRect.intersects(rect)
        } else {
            return rect.contains(nodeRect)
        }
    }
}

// MARK: - Node Addition

/// Add a node to the nodes array
/// - Parameters:
///   - node: Node to add
///   - nodes: Current nodes array
/// - Returns: New nodes array with node added
public func addNode<Node: FlowNode>(
    _ node: Node,
    to nodes: [Node]
) -> [Node] {
    var result = nodes
    result.append(node)
    return result
}

/// Add multiple nodes to the nodes array
/// - Parameters:
///   - nodesToAdd: Nodes to add
///   - nodes: Current nodes array
/// - Returns: New nodes array with nodes added
public func addNodes<Node: FlowNode>(
    _ nodesToAdd: [Node],
    to nodes: [Node]
) -> [Node] {
    var result = nodes
    result.append(contentsOf: nodesToAdd)
    return result
}

// MARK: - Node Update

/// Update a node in the nodes array
/// - Parameters:
///   - id: ID of node to update
///   - update: Function that receives the current node and returns updated node
///   - nodes: Current nodes array
/// - Returns: New nodes array with node updated
public func updateNode<Node: FlowNode>(
    id: UUID,
    with update: (Node) -> Node,
    in nodes: [Node]
) -> [Node] {
    var result = nodes
    
    if let index = result.firstIndex(where: { $0.id == id }) {
        result[index] = update(result[index])
    }
    
    return result
}

/// Delete nodes from the nodes array
/// - Parameters:
///   - nodeIds: IDs of nodes to delete
///   - nodes: Current nodes array
/// - Returns: New nodes array with nodes removed
public func deleteNodes<Node: FlowNode>(
    ids nodeIds: Set<UUID>,
    from nodes: [Node]
) -> [Node] {
    return nodes.filter { !nodeIds.contains($0.id) }
}

// MARK: - Node Queries

/// Get a node by ID
/// - Parameters:
///   - id: Node ID
///   - nodes: Array of nodes to search
/// - Returns: Node if found, nil otherwise
public func getNode<Node: FlowNode>(
    id: UUID,
    from nodes: [Node]
) -> Node? {
    return nodes.first { $0.id == id }
}

/// Get multiple nodes by IDs
/// - Parameters:
///   - ids: Set of node IDs
///   - nodes: Array of nodes to search
/// - Returns: Array of found nodes
public func getNodes<Node: FlowNode>(
    ids: Set<UUID>,
    from nodes: [Node]
) -> [Node] {
    return nodes.filter { ids.contains($0.id) }
}

// MARK: - Cycle Detection

/// Check if adding an edge would create a cycle in the graph
/// - Parameters:
///   - sourceNode: Source node ID
///   - targetNode: Target node ID
///   - edges: Current edges array
/// - Returns: True if adding the edge would create a cycle
public func wouldCreateCycle(
    from sourceNode: UUID,
    to targetNode: UUID,
    edges: [any FlowEdge]
) -> Bool {
    // A cycle is created if target node already has a path to source node
    return hasPath(from: targetNode, to: sourceNode, edges: edges)
}

/// Check if there's a path from one node to another
/// - Parameters:
///   - from: Starting node ID
///   - to: Target node ID
///   - edges: Edges array
/// - Returns: True if a path exists
public func hasPath(
    from startNode: UUID,
    to targetNode: UUID,
    edges: [any FlowEdge]
) -> Bool {
    var visited = Set<UUID>()
    var queue: [UUID] = [startNode]
    
    while !queue.isEmpty {
        let current = queue.removeFirst()
        
        if current == targetNode {
            return true
        }
        
        if visited.contains(current) {
            continue
        }
        
        visited.insert(current)
        
        // Add all outgoing nodes to queue
        let outgoing = edges
            .filter { $0.sourceNodeId == current }
            .map { $0.targetNodeId }
        
        queue.append(contentsOf: outgoing)
    }
    
    return false
}
