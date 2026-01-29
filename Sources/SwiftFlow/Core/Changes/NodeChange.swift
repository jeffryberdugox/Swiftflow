//
//  NodeChange.swift
//  SwiftFlow
//
//  Represents changes that can be applied to nodes.
//

import Foundation

/// Types of changes that can be applied to nodes
public enum NodeChange<Node: FlowNode>: Sendable {
    /// Node was added
    case add(node: Node)
    
    /// Node was removed
    case remove(id: UUID)
    
    /// Node position changed
    case position(id: UUID, position: CGPoint)
    
    /// Node dimensions changed
    case dimensions(id: UUID, width: CGFloat, height: CGFloat)
    
    /// Node selection changed
    case select(id: UUID, selected: Bool)
    
    /// Node was dragged
    case drag(id: UUID, isDragging: Bool)
    
    /// Node data changed (generic update)
    case update(id: UUID, node: Node)
    
    /// Node was reset (clear all changes)
    case reset
}

/// Types of changes that can be applied to edges
public enum EdgeChange<Edge: FlowEdge>: Sendable {
    /// Edge was added
    case add(edge: Edge)
    
    /// Edge was removed  
    case remove(id: UUID)
    
    /// Edge selection changed
    case select(id: UUID, selected: Bool)
    
    /// Edge was updated
    case update(id: UUID, edge: Edge)
    
    /// Edge was reset
    case reset
}

// MARK: - Apply Changes

/// Apply node changes to an array of nodes
/// - Parameters:
///   - changes: Array of changes to apply
///   - nodes: Current nodes array
/// - Returns: New nodes array with changes applied
public func applyNodeChanges<Node: FlowNode>(
    _ changes: [NodeChange<Node>],
    to nodes: [Node]
) -> [Node] {
    var result = nodes
    
    for change in changes {
        switch change {
        case .add(let node):
            result.append(node)
            
        case .remove(let id):
            result.removeAll { $0.id == id }
            
        case .position(let id, let position):
            // Position changes should be handled by updating the node itself
            // FlowNode properties are computed/readonly, so we trigger a refresh
            if let index = result.firstIndex(where: { $0.id == id }) {
                result[index] = result[index] // Trigger refresh
            }
            
        case .dimensions(let id, let width, let height):
            // Dimension changes should be handled by updating the node itself
            // FlowNode properties are computed/readonly, so we trigger a refresh
            if let index = result.firstIndex(where: { $0.id == id }) {
                result[index] = result[index] // Trigger refresh
            }
            
        case .select(let id, let selected):
            // Selection is typically handled externally via SelectionManager
            // but this allows for programmatic selection changes
            if let index = result.firstIndex(where: { $0.id == id }) {
                result[index] = result[index] // Trigger update
            }
            
        case .drag(let id, _):
            // Drag state is handled by DragManager
            if let index = result.firstIndex(where: { $0.id == id }) {
                result[index] = result[index] // Trigger update
            }
            
        case .update(let id, let node):
            if let index = result.firstIndex(where: { $0.id == id }) {
                result[index] = node
            }
            
        case .reset:
            result.removeAll()
        }
    }
    
    return result
}

/// Apply edge changes to an array of edges
/// - Parameters:
///   - changes: Array of changes to apply
///   - edges: Current edges array
/// - Returns: New edges array with changes applied
public func applyEdgeChanges<Edge: FlowEdge>(
    _ changes: [EdgeChange<Edge>],
    to edges: [Edge]
) -> [Edge] {
    var result = edges
    
    for change in changes {
        switch change {
        case .add(let edge):
            result.append(edge)
            
        case .remove(let id):
            result.removeAll { $0.id == id }
            
        case .select(let id, _):
            // Selection handled externally
            if let index = result.firstIndex(where: { $0.id == id }) {
                result[index] = result[index] // Trigger update
            }
            
        case .update(let id, let edge):
            if let index = result.firstIndex(where: { $0.id == id }) {
                result[index] = edge
            }
            
        case .reset:
            result.removeAll()
        }
    }
    
    return result
}
