//
//  CanvasCommand.swift
//  SwiftFlow
//
//  Atomic operations that can be performed on the canvas.
//  Used for the command pattern enabling undo/redo functionality.
//

import Foundation
import CoreGraphics

// MARK: - CanvasCommand

/// Represents an atomic operation that can be performed on the canvas.
/// Commands are the primary interface for modifying canvas state through the controller.
///
/// # Usage
/// ```swift
/// // Execute a single command
/// controller.perform(.zoom(to: 1.5, anchor: .viewportCenter))
///
/// // Execute multiple commands as a transaction
/// controller.transaction("Move nodes") {
///     .moveNodes(ids: selectedIds, delta: CGSize(width: 100, height: 0))
///     .select(nodeIds: selectedIds, edgeIds: [], additive: false)
/// }
/// ```
///
/// # Undo/Redo
/// Commands marked as `isUndoable` will be recorded in the undo stack.
/// Viewport and selection changes are typically not undoable.
public enum CanvasCommand: Equatable, Sendable {
    
    // MARK: - Viewport Commands
    
    /// Set the transform directly
    case setTransform(FlowTransform)
    
    /// Zoom to a specific scale at an anchor point
    case zoom(to: CGFloat, anchor: ScreenPoint)
    
    /// Zoom by a factor at an anchor point
    case zoomBy(factor: CGFloat, anchor: ScreenPoint)
    
    /// Pan by a delta
    case pan(by: CGSize)
    
    /// Pan to center a specific canvas point in the viewport
    case panToCenter(CanvasPoint)
    
    /// Fit all nodes in the viewport
    case fitView(padding: CGFloat)
    
    /// Fit specific nodes in the viewport
    case fitNodes(ids: Set<UUID>, padding: CGFloat)
    
    /// Reset to identity transform
    case resetView
    
    // MARK: - Selection Commands
    
    /// Select nodes and/or edges
    case select(nodeIds: Set<UUID>, edgeIds: Set<UUID>, additive: Bool)
    
    /// Select all nodes
    case selectAll
    
    /// Clear all selection
    case clearSelection
    
    /// Toggle selection of a node
    case toggleNodeSelection(UUID)
    
    /// Toggle selection of an edge
    case toggleEdgeSelection(UUID)
    
    // MARK: - Node Commands
    
    /// Move nodes by a delta
    case moveNodes(ids: Set<UUID>, delta: CGSize)
    
    /// Move a single node to a specific position
    case moveNodeTo(id: UUID, position: CanvasPoint)
    
    /// Resize a node
    case resizeNode(id: UUID, newSize: CGSize, anchor: ResizeAnchor)

    /// Resize a node by scale factor (uniform scaling, preserves aspect ratio)
    case resizeNodeByScale(id: UUID, scaleFactor: CGFloat, anchor: ResizeAnchor)

    /// Resize a node to a specific width (preserves aspect ratio)
    case resizeNodeToWidth(id: UUID, newWidth: CGFloat, anchor: ResizeAnchor)

    /// Delete specific nodes (and their connected edges)
    case deleteNodes(ids: Set<UUID>)
    
    /// Set the parent of a node (for nested nodes)
    case setNodeParent(id: UUID, parentId: UUID?)
    
    /// Set the z-index of a node
    case setNodeZIndex(id: UUID, zIndex: Double)
    
    /// Bring nodes to front
    case bringToFront(ids: Set<UUID>)
    
    /// Send nodes to back
    case sendToBack(ids: Set<UUID>)
    
    // MARK: - Edge Commands
    
    /// Create a new edge/connection
    case createEdge(sourceNode: UUID, sourcePort: UUID, targetNode: UUID, targetPort: UUID)
    
    /// Delete specific edges
    case deleteEdges(ids: Set<UUID>)
    
    // MARK: - Compound Commands
    
    /// Delete currently selected nodes and edges
    case deleteSelection
    
    /// Duplicate selected nodes
    case duplicate(nodeIds: Set<UUID>)
    
    /// Copy selected nodes to clipboard
    case copy(nodeIds: Set<UUID>)
    
    /// Cut selected nodes (copy + delete)
    case cut(nodeIds: Set<UUID>)
    
    /// Paste from clipboard at position
    case paste(at: CanvasPoint?)
    
    // MARK: - Properties
    
    /// Whether this command should be recorded for undo/redo.
    /// Viewport and selection changes are typically not undoable.
    public var isUndoable: Bool {
        switch self {
        // Viewport changes are not undoable
        case .setTransform, .zoom, .zoomBy, .pan, .panToCenter,
             .fitView, .fitNodes, .resetView:
            return false
            
        // Selection changes are not undoable
        case .select, .selectAll, .clearSelection,
             .toggleNodeSelection, .toggleEdgeSelection:
            return false
            
        // All other operations are undoable
        default:
            return true
        }
    }
    
    /// Human-readable name for the undo menu.
    /// Returns nil for non-undoable commands.
    public var undoName: String? {
        switch self {
        case .moveNodes, .moveNodeTo:
            return "Move"
        case .resizeNode, .resizeNodeByScale, .resizeNodeToWidth:
            return "Resize"
        case .deleteNodes, .deleteSelection, .deleteEdges:
            return "Delete"
        case .createEdge:
            return "Connect"
        case .duplicate:
            return "Duplicate"
        case .copy:
            return "Copy"
        case .cut:
            return "Cut"
        case .paste:
            return "Paste"
        case .setNodeParent:
            return "Change Parent"
        case .setNodeZIndex, .bringToFront, .sendToBack:
            return "Change Order"
        default:
            return nil
        }
    }
    
    /// Whether this command affects nodes
    public var affectsNodes: Bool {
        switch self {
        case .moveNodes, .moveNodeTo, .resizeNode, .resizeNodeByScale, .resizeNodeToWidth, .deleteNodes,
             .setNodeParent, .setNodeZIndex, .bringToFront, .sendToBack,
             .deleteSelection, .duplicate, .cut, .paste:
            return true
        default:
            return false
        }
    }
    
    /// Whether this command affects edges
    public var affectsEdges: Bool {
        switch self {
        case .createEdge, .deleteEdges, .deleteSelection, .deleteNodes:
            return true
        default:
            return false
        }
    }
    
    /// Whether this command affects the viewport
    public var affectsViewport: Bool {
        switch self {
        case .setTransform, .zoom, .zoomBy, .pan, .panToCenter,
             .fitView, .fitNodes, .resetView:
            return true
        default:
            return false
        }
    }
    
    /// Whether this command affects selection
    public var affectsSelection: Bool {
        switch self {
        case .select, .selectAll, .clearSelection,
             .toggleNodeSelection, .toggleEdgeSelection,
             .deleteSelection, .deleteNodes, .deleteEdges:
            return true
        default:
            return false
        }
    }
}

// MARK: - Command Result

/// Result of executing a command
public struct CommandResult: Equatable, Sendable {
    
    /// Whether the command was executed successfully
    public let success: Bool
    
    /// Optional error message if the command failed
    public let error: String?
    
    /// IDs of nodes that were affected
    public let affectedNodeIds: Set<UUID>
    
    /// IDs of edges that were affected
    public let affectedEdgeIds: Set<UUID>
    
    /// The inverse command for undo (if applicable)
    public let inverseCommand: CanvasCommand?
    
    // MARK: - Initialization
    
    public init(
        success: Bool,
        error: String? = nil,
        affectedNodeIds: Set<UUID> = [],
        affectedEdgeIds: Set<UUID> = [],
        inverseCommand: CanvasCommand? = nil
    ) {
        self.success = success
        self.error = error
        self.affectedNodeIds = affectedNodeIds
        self.affectedEdgeIds = affectedEdgeIds
        self.inverseCommand = inverseCommand
    }
    
    // MARK: - Factory Methods
    
    /// Create a successful result
    public static func succeeded(
        affectedNodeIds: Set<UUID> = [],
        affectedEdgeIds: Set<UUID> = [],
        inverseCommand: CanvasCommand? = nil
    ) -> CommandResult {
        CommandResult(
            success: true,
            affectedNodeIds: affectedNodeIds,
            affectedEdgeIds: affectedEdgeIds,
            inverseCommand: inverseCommand
        )
    }
    
    /// Create a failed result
    public static func failed(_ error: String) -> CommandResult {
        CommandResult(success: false, error: error)
    }
    
    /// No-op result (command did nothing but didn't fail)
    public static let noOp = CommandResult(success: true)
}

// MARK: - CustomStringConvertible

extension CanvasCommand: CustomStringConvertible {
    public var description: String {
        switch self {
        case .setTransform(let transform):
            return "setTransform(scale: \(String(format: "%.2f", transform.scale)))"
        case .zoom(let scale, _):
            return "zoom(to: \(String(format: "%.2f", scale)))"
        case .zoomBy(let factor, _):
            return "zoomBy(factor: \(String(format: "%.2f", factor)))"
        case .pan(let delta):
            return "pan(by: \(String(format: "%.1f, %.1f", delta.width, delta.height)))"
        case .panToCenter(let point):
            return "panToCenter(\(point))"
        case .fitView(let padding):
            return "fitView(padding: \(String(format: "%.0f", padding)))"
        case .fitNodes(let ids, _):
            return "fitNodes(count: \(ids.count))"
        case .resetView:
            return "resetView"
        case .select(let nodeIds, let edgeIds, let additive):
            return "select(nodes: \(nodeIds.count), edges: \(edgeIds.count), additive: \(additive))"
        case .selectAll:
            return "selectAll"
        case .clearSelection:
            return "clearSelection"
        case .toggleNodeSelection(let id):
            return "toggleNodeSelection(\(id.uuidString.prefix(8)))"
        case .toggleEdgeSelection(let id):
            return "toggleEdgeSelection(\(id.uuidString.prefix(8)))"
        case .moveNodes(let ids, let delta):
            return "moveNodes(count: \(ids.count), delta: \(String(format: "%.1f, %.1f", delta.width, delta.height)))"
        case .moveNodeTo(let id, let position):
            return "moveNodeTo(\(id.uuidString.prefix(8)), \(position))"
        case .resizeNode(let id, let size, _):
            return "resizeNode(\(id.uuidString.prefix(8)), size: \(String(format: "%.0f x %.0f", size.width, size.height)))"
        case .resizeNodeByScale(let id, let scaleFactor, _):
            return "resizeNodeByScale(\(id.uuidString.prefix(8)), scale: \(String(format: "%.2f", scaleFactor)))"
        case .resizeNodeToWidth(let id, let newWidth, _):
            return "resizeNodeToWidth(\(id.uuidString.prefix(8)), width: \(String(format: "%.0f", newWidth)))"
        case .deleteNodes(let ids):
            return "deleteNodes(count: \(ids.count))"
        case .setNodeParent(let id, let parentId):
            return "setNodeParent(\(id.uuidString.prefix(8)), parent: \(parentId?.uuidString.prefix(8) ?? "nil"))"
        case .setNodeZIndex(let id, let zIndex):
            return "setNodeZIndex(\(id.uuidString.prefix(8)), z: \(String(format: "%.1f", zIndex)))"
        case .bringToFront(let ids):
            return "bringToFront(count: \(ids.count))"
        case .sendToBack(let ids):
            return "sendToBack(count: \(ids.count))"
        case .createEdge(let sourceNode, _, let targetNode, _):
            return "createEdge(\(sourceNode.uuidString.prefix(8)) -> \(targetNode.uuidString.prefix(8)))"
        case .deleteEdges(let ids):
            return "deleteEdges(count: \(ids.count))"
        case .deleteSelection:
            return "deleteSelection"
        case .duplicate(let ids):
            return "duplicate(count: \(ids.count))"
        case .copy(let ids):
            return "copy(count: \(ids.count))"
        case .cut(let ids):
            return "cut(count: \(ids.count))"
        case .paste(let position):
            return "paste(at: \(position?.description ?? "default"))"
        }
    }
}
