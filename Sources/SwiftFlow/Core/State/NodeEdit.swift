//
//  NodeEdit.swift
//  SwiftFlow
//
//  Describes atomic changes to nodes.
//  Used by CanvasEnvironment to apply batch updates.
//

import Foundation
import CoreGraphics

// MARK: - NodeEdit

/// Describes an atomic change to a node.
/// Used by the controller to communicate modifications to the data layer.
///
/// # Usage
/// ```swift
/// // In CanvasEnvironment.applyNodeEdits:
/// for edit in edits {
///     switch edit {
///     case .move(let id, let position):
///         nodes[id]?.position = position
///     case .resize(let id, let size):
///         nodes[id]?.width = size.width
///         nodes[id]?.height = size.height
///     // ... handle other cases
///     }
/// }
/// ```
public enum NodeEdit: Equatable, Sendable {
    
    /// Move a node to a new position
    case move(id: UUID, to: CGPoint)
    
    /// Resize a node
    case resize(id: UUID, size: CGSize)
    
    /// Delete a node
    case delete(id: UUID)
    
    /// Add a new node at a position
    /// Note: The actual node creation is typically handled by the user's data layer
    case add(id: UUID, position: CGPoint, data: [String: AnyHashableSendable])
    
    /// Update a data field on a node
    case updateData(id: UUID, key: String, value: AnyHashableSendable)
    
    /// Set the parent of a node (for nested nodes)
    case setParent(id: UUID, parentId: UUID?)
    
    /// Set the z-index of a node
    case setZIndex(id: UUID, zIndex: Double)
    
    // MARK: - Properties
    
    /// The ID of the node affected by this edit
    public var nodeId: UUID {
        switch self {
        case .move(let id, _),
             .resize(let id, _),
             .delete(let id),
             .add(let id, _, _),
             .updateData(let id, _, _),
             .setParent(let id, _),
             .setZIndex(let id, _):
            return id
        }
    }
    
    /// Human-readable description of the edit type
    public var editType: String {
        switch self {
        case .move: return "move"
        case .resize: return "resize"
        case .delete: return "delete"
        case .add: return "add"
        case .updateData: return "updateData"
        case .setParent: return "setParent"
        case .setZIndex: return "setZIndex"
        }
    }
}

// MARK: - EdgeEdit

/// Describes an atomic change to an edge.
/// Used by the controller to communicate modifications to the data layer.
public enum EdgeEdit: Equatable, Sendable {
    
    /// Create a new edge/connection
    case create(
        id: UUID,
        sourceNode: UUID,
        sourcePort: UUID,
        targetNode: UUID,
        targetPort: UUID
    )
    
    /// Delete an edge
    case delete(id: UUID)
    
    /// Update the style of an edge
    case updateStyle(id: UUID, style: EdgeStyleConfig)
    
    // MARK: - Properties
    
    /// The ID of the edge affected by this edit
    public var edgeId: UUID {
        switch self {
        case .create(let id, _, _, _, _),
             .delete(let id),
             .updateStyle(let id, _):
            return id
        }
    }
    
    /// Human-readable description of the edit type
    public var editType: String {
        switch self {
        case .create: return "create"
        case .delete: return "delete"
        case .updateStyle: return "updateStyle"
        }
    }
}

// MARK: - AnyHashableSendable

/// Type-erased hashable sendable value for use in edits.
/// Wraps any Hashable & Sendable value.
public struct AnyHashableSendable: Hashable, Sendable {
    
    private let value: AnyHashable
    
    /// Creates an instance wrapping the given value.
    public init<T: Hashable & Sendable>(_ value: T) {
        self.value = AnyHashable(value)
    }
    
    /// The wrapped value as the specified type.
    public func value<T>(as type: T.Type) -> T? {
        value.base as? T
    }
    
    /// The wrapped value as Any.
    public var base: Any {
        value.base
    }
}

// MARK: - Batch Edit Helpers

public extension Array where Element == NodeEdit {
    
    /// All node IDs affected by these edits
    var affectedNodeIds: Set<UUID> {
        Set(map { $0.nodeId })
    }
    
    /// Filter edits for a specific node
    func edits(for nodeId: UUID) -> [NodeEdit] {
        filter { $0.nodeId == nodeId }
    }
    
    /// Get all move edits
    var moveEdits: [(id: UUID, position: CGPoint)] {
        compactMap { edit in
            if case .move(let id, let position) = edit {
                return (id, position)
            }
            return nil
        }
    }
    
    /// Get all delete edits
    var deleteIds: Set<UUID> {
        Set(compactMap { edit in
            if case .delete(let id) = edit {
                return id
            }
            return nil
        })
    }
}

public extension Array where Element == EdgeEdit {
    
    /// All edge IDs affected by these edits
    var affectedEdgeIds: Set<UUID> {
        Set(map { $0.edgeId })
    }
    
    /// Get all delete edits
    var deleteIds: Set<UUID> {
        Set(compactMap { edit in
            if case .delete(let id) = edit {
                return id
            }
            return nil
        })
    }
}

// MARK: - CustomStringConvertible

extension NodeEdit: CustomStringConvertible {
    public var description: String {
        switch self {
        case .move(let id, let position):
            return "NodeEdit.move(\(id.uuidString.prefix(8)), to: \(String(format: "%.1f, %.1f", position.x, position.y)))"
        case .resize(let id, let size):
            return "NodeEdit.resize(\(id.uuidString.prefix(8)), size: \(String(format: "%.0f x %.0f", size.width, size.height)))"
        case .delete(let id):
            return "NodeEdit.delete(\(id.uuidString.prefix(8)))"
        case .add(let id, let position, _):
            return "NodeEdit.add(\(id.uuidString.prefix(8)), at: \(String(format: "%.1f, %.1f", position.x, position.y)))"
        case .updateData(let id, let key, _):
            return "NodeEdit.updateData(\(id.uuidString.prefix(8)), key: \(key))"
        case .setParent(let id, let parentId):
            return "NodeEdit.setParent(\(id.uuidString.prefix(8)), parent: \(parentId?.uuidString.prefix(8) ?? "nil"))"
        case .setZIndex(let id, let zIndex):
            return "NodeEdit.setZIndex(\(id.uuidString.prefix(8)), z: \(String(format: "%.1f", zIndex)))"
        }
    }
}

extension EdgeEdit: CustomStringConvertible {
    public var description: String {
        switch self {
        case .create(let id, let sourceNode, _, let targetNode, _):
            return "EdgeEdit.create(\(id.uuidString.prefix(8)), \(sourceNode.uuidString.prefix(8)) -> \(targetNode.uuidString.prefix(8)))"
        case .delete(let id):
            return "EdgeEdit.delete(\(id.uuidString.prefix(8)))"
        case .updateStyle(let id, _):
            return "EdgeEdit.updateStyle(\(id.uuidString.prefix(8)))"
        }
    }
}
