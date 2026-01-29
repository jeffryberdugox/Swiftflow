//
//  FlowEdge.swift
//  SwiftFlow
//
//  Protocol defining the requirements for an edge (connection) in the flow canvas.
//

import Foundation

/// Protocol that defines the requirements for an edge connecting two nodes.
/// Edges represent connections between output ports and input ports.
public protocol FlowEdge: Identifiable where ID == UUID {
    /// Unique identifier for the edge
    var id: UUID { get }
    
    /// ID of the source node (where the connection starts)
    var sourceNodeId: UUID { get }
    
    /// ID of the port on the source node
    var sourcePortId: UUID { get }
    
    /// ID of the target node (where the connection ends)
    var targetNodeId: UUID { get }
    
    /// ID of the port on the target node
    var targetPortId: UUID { get }
}

// MARK: - EdgeType

/// Visual style for rendering edges
public enum EdgeType: String, CaseIterable, Sendable {
    /// Smooth bezier curve
    case bezier
    
    /// Orthogonal path with rounded corners
    case smoothStep
    
    /// Direct straight line
    case straight
}

// MARK: - StyledFlowEdge Protocol

/// Protocol extension to add custom styling to edges
public protocol StyledFlowEdge: FlowEdge {
    var style: EdgeStyleConfig? { get set }
}

// Default implementation
public extension StyledFlowEdge {
    var style: EdgeStyleConfig? {
        get { nil }
        set { }
    }
}
