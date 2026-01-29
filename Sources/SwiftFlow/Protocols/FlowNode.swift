//
//  FlowNode.swift
//  SwiftFlow
//
//  Protocol defining the requirements for a node in the flow canvas.
//

import Foundation
import CoreGraphics
import SwiftUI

/// Protocol that defines the requirements for a node in the flow canvas.
/// Conforming types can be rendered and interacted with in the canvas view.
///
/// # Coordinate System
/// - `position`: The **top-left corner** of the node in canvas coordinates
/// - `bounds`: The full rectangle from top-left (position.x, position.y) to (position.x + width, position.y + height)
/// - `center`: The center point calculated as (position.x + width/2, position.y + height/2)
public protocol FlowNode: Identifiable where ID == UUID {
    /// Unique identifier for the node
    var id: UUID { get }

    /// Position of the node's **top-left corner** in canvas coordinates.
    /// This is the anchor point for the node - all other positions (center, ports) are calculated from this.
    /// **For nested nodes**: This position is **relative** to the parent node's position.
    /// **For root nodes**: This position is **absolute** in canvas coordinates.
    var position: CGPoint { get set }

    /// Width of the node view
    var width: CGFloat { get set }

    /// Height of the node view
    var height: CGFloat { get set }

    /// Whether the node can be dragged by the user
    var isDraggable: Bool { get }

    /// Whether the node can be selected
    var isSelectable: Bool { get }

    /// Whether the node can be resized by the user
    var isResizable: Bool { get }

    /// Input ports on this node (connection targets)
    var inputPorts: [any FlowPort] { get }

    /// Output ports on this node (connection sources)
    var outputPorts: [any FlowPort] { get }

    // MARK: - Nested Nodes Support

    /// ID of the parent node if this is a child node.
    /// Set to nil for root-level nodes.
    var parentId: UUID? { get set }

    /// Movement constraints for this node.
    /// - `.parent`: Node is constrained within parent's bounds
    /// - `.coordinates(rect)`: Node is constrained to specific rectangle
    /// - `nil`: No constraints (default)
    var extent: NodeExtent? { get set }

    /// Whether the parent node should automatically expand when this child node is dragged near the edge.
    /// Only applies when this node has a parent.
    var expandParent: Bool { get }

    /// Z-index for layering. Higher values appear on top.
    /// For child nodes, the z-index is automatically adjusted to appear above their parent.
    var zIndex: Double { get set }
}

// MARK: - Default Implementations

public extension FlowNode {
    /// Default width for nodes
    var width: CGFloat { 200 }

    /// Default height for nodes
    var height: CGFloat { 100 }

    /// Nodes are draggable by default
    var isDraggable: Bool { true }

    /// Nodes are selectable by default
    var isSelectable: Bool { true }

    /// Nodes are resizable by default
    var isResizable: Bool { true }

    /// No parent by default (root node)
    var parentId: UUID? {
        get { nil }
        set { }
    }

    /// No movement constraints by default
    var extent: NodeExtent? {
        get { nil }
        set { }
    }

    /// Don't expand parent by default
    var expandParent: Bool { false }

    /// Default z-index
    var zIndex: Double {
        get { 0 }
        set { }
    }
    
    /// Bounding rectangle of the node in canvas coordinates.
    /// Origin is at top-left (position), extends to (position.x + width, position.y + height).
    var bounds: CGRect {
        CGRect(
            x: position.x,
            y: position.y,
            width: width,
            height: height
        )
    }
    
    /// Center point of the node in canvas coordinates.
    /// Calculated from top-left position.
    var center: CGPoint {
        CGPoint(
            x: position.x + width / 2,
            y: position.y + height / 2
        )
    }
    
    /// Top-left corner of the node (same as position).
    /// Provided for semantic clarity when working with coordinate conversions.
    var topLeft: CGPoint { position }
}

// MARK: - Type-Erased FlowNode Wrapper

/// Type-erased wrapper for FlowNode to use in environment
public struct AnyFlowNode: FlowNode {
    public let id: UUID
    public var position: CGPoint
    public var width: CGFloat
    public var height: CGFloat
    public let isDraggable: Bool
    public let isSelectable: Bool
    public let isResizable: Bool
    public let inputPorts: [any FlowPort]
    public let outputPorts: [any FlowPort]
    public var parentId: UUID?
    public var extent: NodeExtent?
    public let expandParent: Bool
    public var zIndex: Double

    public init<N: FlowNode>(_ node: N) {
        self.id = node.id
        self.position = node.position
        self.width = node.width
        self.height = node.height
        self.isDraggable = node.isDraggable
        self.isSelectable = node.isSelectable
        self.isResizable = node.isResizable
        self.inputPorts = node.inputPorts
        self.outputPorts = node.outputPorts
        self.parentId = node.parentId
        self.extent = node.extent
        self.expandParent = node.expandParent
        self.zIndex = node.zIndex
    }
}

// MARK: - Environment Key for Nodes

/// Environment key for passing flow nodes to child views
private struct FlowNodesKey: EnvironmentKey {
    static let defaultValue: [AnyFlowNode] = []
}

public extension EnvironmentValues {
    /// The flow nodes available in the current canvas context
    var flowNodes: [AnyFlowNode] {
        get { self[FlowNodesKey.self] }
        set { self[FlowNodesKey.self] = newValue }
    }
}
