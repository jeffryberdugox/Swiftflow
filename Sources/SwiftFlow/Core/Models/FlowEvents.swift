//
//  FlowEvents.swift
//  SwiftFlow
//
//  Typed event structures for canvas interactions.
//

import Foundation
import SwiftUI

// MARK: - Node Events

/// Event fired when a node is dragged
public struct NodeDragEvent: Equatable, Sendable {
    /// The node being dragged
    public let nodeId: UUID
    
    /// Current position of the node
    public let position: CGPoint
    
    /// Delta from previous position
    public let delta: CGSize
    
    /// Whether the drag is currently active
    public let isDragging: Bool
    
    /// Timestamp of the event
    public let timestamp: Date
    
    public init(
        nodeId: UUID,
        position: CGPoint,
        delta: CGSize,
        isDragging: Bool,
        timestamp: Date = Date()
    ) {
        self.nodeId = nodeId
        self.position = position
        self.delta = delta
        self.isDragging = isDragging
        self.timestamp = timestamp
    }
}

/// Event fired when a node is clicked
public struct NodeMouseEvent: Equatable, Sendable {
    /// The node that was clicked
    public let nodeId: UUID
    
    /// Mouse position in canvas coordinates
    public let position: CGPoint
    
    /// Type of mouse event
    public let eventType: MouseEventType
    
    /// Modifier keys pressed during event
    public let modifiers: EventModifiers
    
    /// Timestamp of the event
    public let timestamp: Date
    
    public init(
        nodeId: UUID,
        position: CGPoint,
        eventType: MouseEventType,
        modifiers: EventModifiers = [],
        timestamp: Date = Date()
    ) {
        self.nodeId = nodeId
        self.position = position
        self.eventType = eventType
        self.modifiers = modifiers
        self.timestamp = timestamp
    }
}

/// Event fired when a node is resized
public struct NodeResizeEvent: Equatable, Sendable {
    /// The node being resized
    public let nodeId: UUID
    
    /// New size of the node
    public let size: CGSize
    
    /// Previous size of the node
    public let previousSize: CGSize
    
    /// Resize anchor point
    public let anchor: ResizeAnchor
    
    /// Whether the resize is currently active
    public let isResizing: Bool
    
    /// Timestamp of the event
    public let timestamp: Date
    
    public init(
        nodeId: UUID,
        size: CGSize,
        previousSize: CGSize,
        anchor: ResizeAnchor,
        isResizing: Bool,
        timestamp: Date = Date()
    ) {
        self.nodeId = nodeId
        self.size = size
        self.previousSize = previousSize
        self.anchor = anchor
        self.isResizing = isResizing
        self.timestamp = timestamp
    }
}

// MARK: - Edge Events

/// Event fired when an edge is clicked
public struct EdgeMouseEvent: Equatable, Sendable {
    /// The edge that was clicked
    public let edgeId: UUID
    
    /// Mouse position in canvas coordinates
    public let position: CGPoint
    
    /// Type of mouse event
    public let eventType: MouseEventType
    
    /// Modifier keys pressed during event
    public let modifiers: EventModifiers
    
    /// Timestamp of the event
    public let timestamp: Date
    
    public init(
        edgeId: UUID,
        position: CGPoint,
        eventType: MouseEventType,
        modifiers: EventModifiers = [],
        timestamp: Date = Date()
    ) {
        self.edgeId = edgeId
        self.position = position
        self.eventType = eventType
        self.modifiers = modifiers
        self.timestamp = timestamp
    }
}

/// Event fired when an edge is updated (reconnected)
public struct EdgeUpdateEvent: Sendable {
    /// The edge being updated
    public let edgeId: UUID
    
    /// Old source node and port
    public let oldSource: (nodeId: UUID, portId: UUID)
    
    /// Old target node and port
    public let oldTarget: (nodeId: UUID, portId: UUID)
    
    /// New source node and port (if changed)
    public let newSource: (nodeId: UUID, portId: UUID)?
    
    /// New target node and port (if changed)
    public let newTarget: (nodeId: UUID, portId: UUID)?
    
    /// Timestamp of the event
    public let timestamp: Date
    
    public init(
        edgeId: UUID,
        oldSource: (nodeId: UUID, portId: UUID),
        oldTarget: (nodeId: UUID, portId: UUID),
        newSource: (nodeId: UUID, portId: UUID)?,
        newTarget: (nodeId: UUID, portId: UUID)?,
        timestamp: Date = Date()
    ) {
        self.edgeId = edgeId
        self.oldSource = oldSource
        self.oldTarget = oldTarget
        self.newSource = newSource
        self.newTarget = newTarget
        self.timestamp = timestamp
    }
}

// Manual Equatable conformance since tuples don't conform automatically
extension EdgeUpdateEvent: Equatable {
    public static func == (lhs: EdgeUpdateEvent, rhs: EdgeUpdateEvent) -> Bool {
        return lhs.edgeId == rhs.edgeId &&
               lhs.oldSource.nodeId == rhs.oldSource.nodeId &&
               lhs.oldSource.portId == rhs.oldSource.portId &&
               lhs.oldTarget.nodeId == rhs.oldTarget.nodeId &&
               lhs.oldTarget.portId == rhs.oldTarget.portId &&
               lhs.newSource?.nodeId == rhs.newSource?.nodeId &&
               lhs.newSource?.portId == rhs.newSource?.portId &&
               lhs.newTarget?.nodeId == rhs.newTarget?.nodeId &&
               lhs.newTarget?.portId == rhs.newTarget?.portId &&
               lhs.timestamp == rhs.timestamp
    }
}

// MARK: - Connection Events

/// Event fired when a connection starts
public struct ConnectionStartEvent: Equatable, Sendable {
    /// Source node
    public let sourceNodeId: UUID
    
    /// Source port
    public let sourcePortId: UUID
    
    /// Starting position
    public let position: CGPoint
    
    /// Port position (side of node)
    public let portPosition: PortPosition
    
    /// Whether starting from input or output
    public let isFromInput: Bool
    
    /// Timestamp of the event
    public let timestamp: Date
    
    public init(
        sourceNodeId: UUID,
        sourcePortId: UUID,
        position: CGPoint,
        portPosition: PortPosition,
        isFromInput: Bool,
        timestamp: Date = Date()
    ) {
        self.sourceNodeId = sourceNodeId
        self.sourcePortId = sourcePortId
        self.position = position
        self.portPosition = portPosition
        self.isFromInput = isFromInput
        self.timestamp = timestamp
    }
}

/// Event fired when a connection ends
public struct ConnectionEndEvent: Equatable, Sendable {
    /// Source node
    public let sourceNodeId: UUID
    
    /// Source port
    public let sourcePortId: UUID
    
    /// Target node (if connected)
    public let targetNodeId: UUID?
    
    /// Target port (if connected)
    public let targetPortId: UUID?
    
    /// Final position
    public let position: CGPoint
    
    /// Whether connection was successful
    public let wasSuccessful: Bool
    
    /// Timestamp of the event
    public let timestamp: Date
    
    public init(
        sourceNodeId: UUID,
        sourcePortId: UUID,
        targetNodeId: UUID?,
        targetPortId: UUID?,
        position: CGPoint,
        wasSuccessful: Bool,
        timestamp: Date = Date()
    ) {
        self.sourceNodeId = sourceNodeId
        self.sourcePortId = sourcePortId
        self.targetNodeId = targetNodeId
        self.targetPortId = targetPortId
        self.position = position
        self.wasSuccessful = wasSuccessful
        self.timestamp = timestamp
    }
}

// MARK: - Canvas Events

/// Event fired when the canvas is clicked
public struct CanvasMouseEvent: Equatable, Sendable {
    /// Mouse position in canvas coordinates
    public let position: CGPoint
    
    /// Mouse position in screen coordinates
    public let screenPosition: CGPoint
    
    /// Type of mouse event
    public let eventType: MouseEventType
    
    /// Modifier keys pressed during event
    public let modifiers: EventModifiers
    
    /// Timestamp of the event
    public let timestamp: Date
    
    public init(
        position: CGPoint,
        screenPosition: CGPoint,
        eventType: MouseEventType,
        modifiers: EventModifiers = [],
        timestamp: Date = Date()
    ) {
        self.position = position
        self.screenPosition = screenPosition
        self.eventType = eventType
        self.modifiers = modifiers
        self.timestamp = timestamp
    }
}

/// Event fired when the viewport changes
public struct ViewportChangeEvent: Equatable, Sendable {
    /// Current transform
    public let transform: FlowTransform
    
    /// Previous transform
    public let previousTransform: FlowTransform
    
    /// Viewport size
    public let viewportSize: CGSize
    
    /// Change type
    public let changeType: ViewportChangeType
    
    /// Timestamp of the event
    public let timestamp: Date
    
    public init(
        transform: FlowTransform,
        previousTransform: FlowTransform,
        viewportSize: CGSize,
        changeType: ViewportChangeType,
        timestamp: Date = Date()
    ) {
        self.transform = transform
        self.previousTransform = previousTransform
        self.viewportSize = viewportSize
        self.changeType = changeType
        self.timestamp = timestamp
    }
}

// MARK: - Selection Events

/// Event fired when selection changes
public struct SelectionChangeEvent: Equatable, Sendable {
    /// Currently selected node IDs
    public let selectedNodes: Set<UUID>
    
    /// Currently selected edge IDs
    public let selectedEdges: Set<UUID>
    
    /// Previously selected node IDs
    public let previousSelectedNodes: Set<UUID>
    
    /// Previously selected edge IDs
    public let previousSelectedEdges: Set<UUID>
    
    /// Timestamp of the event
    public let timestamp: Date
    
    public init(
        selectedNodes: Set<UUID>,
        selectedEdges: Set<UUID>,
        previousSelectedNodes: Set<UUID>,
        previousSelectedEdges: Set<UUID>,
        timestamp: Date = Date()
    ) {
        self.selectedNodes = selectedNodes
        self.selectedEdges = selectedEdges
        self.previousSelectedNodes = previousSelectedNodes
        self.previousSelectedEdges = previousSelectedEdges
        self.timestamp = timestamp
    }
}

// MARK: - Supporting Types

/// Type of mouse event
public enum MouseEventType: Equatable, Sendable, Hashable {
    case click
    case doubleClick
    case contextMenu
    case hover
    case hoverEnd
}

/// Type of viewport change
public enum ViewportChangeType: Equatable, Sendable, Hashable {
    case zoom
    case pan
    case fit
    case reset
}

// MARK: - Event Handlers Type Aliases

/// Handler for node drag events
public typealias NodeDragHandler = (NodeDragEvent) -> Void

/// Handler for node mouse events
public typealias NodeMouseHandler = (NodeMouseEvent) -> Void

/// Handler for node resize events
public typealias NodeResizeHandler = (NodeResizeEvent) -> Void

/// Handler for edge mouse events
public typealias EdgeMouseHandler = (EdgeMouseEvent) -> Void

/// Handler for edge update events
public typealias EdgeUpdateHandler = (EdgeUpdateEvent) -> Void

/// Handler for connection start events
public typealias ConnectionStartHandler = (ConnectionStartEvent) -> Void

/// Handler for connection end events
public typealias ConnectionEndHandler = (ConnectionEndEvent) -> Void

/// Handler for canvas mouse events
public typealias CanvasMouseHandler = (CanvasMouseEvent) -> Void

/// Handler for viewport change events
public typealias ViewportChangeHandler = (ViewportChangeEvent) -> Void

/// Handler for selection change events
public typealias SelectionChangeHandler = (SelectionChangeEvent) -> Void
