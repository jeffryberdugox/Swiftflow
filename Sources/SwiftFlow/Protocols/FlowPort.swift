//
//  FlowPort.swift
//  SwiftFlow
//
//  Protocol defining the requirements for a port (connection point) on a node.
//

import Foundation
import CoreGraphics

/// Protocol that defines the requirements for a port on a node.
/// Ports are the connection points where edges attach to nodes.
///
/// # Port Positioning
/// Ports use a flexible layout system with presets and custom offsets:
/// - `layout`: Full control with PortLayout (presets + offsets)
/// - `position`: Side-based positioning used for edge direction calculation
public protocol FlowPort: Identifiable where ID == UUID {
    /// Unique identifier for the port
    var id: UUID { get }
    
    /// Position of the port relative to the node (top, bottom, left, right).
    /// Used for edge path direction calculation.
    var position: PortPosition { get }
    
    /// Layout defining the port's position with presets and offsets.
    /// If not implemented, defaults to a preset based on `position`.
    var layout: PortLayout { get }
}

// MARK: - Default Implementations

public extension FlowPort {
    /// Default layout based on the port's position.
    /// Maps PortPosition to a PortLayout preset.
    var layout: PortLayout {
        return PortLayout.default(for: position)
    }
}

// MARK: - PortPosition

/// Defines which side of a node a port is located on
public enum PortPosition: String, Codable, Sendable, CaseIterable {
    case top
    case bottom
    case left
    case right
    
    /// The opposite position (used for determining edge curvature)
    public var opposite: PortPosition {
        switch self {
        case .top: return .bottom
        case .bottom: return .top
        case .left: return .right
        case .right: return .left
        }
    }
    
    /// Direction vector for this position
    public var directionVector: CGPoint {
        switch self {
        case .top: return CGPoint(x: 0, y: -1)
        case .bottom: return CGPoint(x: 0, y: 1)
        case .left: return CGPoint(x: -1, y: 0)
        case .right: return CGPoint(x: 1, y: 0)
        }
    }
    
    /// Whether this position is horizontal (left or right)
    public var isHorizontal: Bool {
        self == .left || self == .right
    }
    
    /// Whether this position is vertical (top or bottom)
    public var isVertical: Bool {
        self == .top || self == .bottom
    }
}

// MARK: - Port Position Calculation

/// Calculates the absolute position of a port given its node (generic version)
public func calculatePortPosition<Node: FlowNode>(
    port: any FlowPort,
    on node: Node,
    isInput: Bool
) -> CGPoint {
    calculatePortPositionImpl(port: port, nodePosition: node.position, nodeWidth: node.width, nodeHeight: node.height)
}

/// Calculates the absolute position of a port given its node (existential version)
public func calculatePortPosition(
    port: any FlowPort,
    on node: any FlowNode,
    isInput: Bool
) -> CGPoint {
    calculatePortPositionImpl(port: port, nodePosition: node.position, nodeWidth: node.width, nodeHeight: node.height)
}

/// Internal implementation for port position calculation.
/// COORDINATE SYSTEM: nodePosition is the TOP-LEFT corner of the node (not center).
/// Returns absolute position in canvas coordinates.
private func calculatePortPositionImpl(
    port: any FlowPort,
    nodePosition: CGPoint,
    nodeWidth: CGFloat,
    nodeHeight: CGFloat
) -> CGPoint {
    // Use the layout system for precise positioning
    let nodeSize = CGSize(width: nodeWidth, height: nodeHeight)
    let localPosition = port.layout.position(nodeSize: nodeSize)
    
    // Convert from node-local to canvas coordinates
    return CGPoint(
        x: nodePosition.x + localPosition.x,
        y: nodePosition.y + localPosition.y
    )
}
