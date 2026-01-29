//
//  CanvasTransaction.swift
//  SwiftFlow
//
//  Groups multiple commands into a single undoable operation.
//  Enables batch updates and compound undo/redo.
//

import Foundation

// MARK: - CanvasTransaction

/// Groups multiple commands into a single undoable operation.
/// All commands in a transaction are executed atomically and undone/redone together.
///
/// # Usage
/// ```swift
/// // Using the transaction API
/// controller.transaction("Auto Layout") {
///     .moveNodes(ids: [node1], delta: CGSize(width: 100, height: 0))
///     .moveNodes(ids: [node2], delta: CGSize(width: 200, height: 0))
///     .moveNodes(ids: [node3], delta: CGSize(width: 300, height: 0))
/// }
///
/// // Single undo reverts all three moves
/// controller.undo()
/// ```
public struct CanvasTransaction: Equatable, Sendable, Identifiable {
    
    /// Unique identifier for this transaction
    public let id: UUID
    
    /// Human-readable name for undo/redo menu
    public let name: String
    
    /// Commands in this transaction (in execution order)
    public let commands: [CanvasCommand]
    
    /// Timestamp when the transaction was created
    public let timestamp: Date
    
    /// Inverse commands for undo (in reverse order)
    public var inverseCommands: [CanvasCommand]
    
    // MARK: - Initialization
    
    /// Creates a transaction with the specified name and commands.
    public init(name: String, commands: [CanvasCommand]) {
        self.id = UUID()
        self.name = name
        self.commands = commands
        self.timestamp = Date()
        self.inverseCommands = []
    }
    
    /// Creates a transaction with pre-computed inverse commands.
    public init(
        id: UUID = UUID(),
        name: String,
        commands: [CanvasCommand],
        timestamp: Date = Date(),
        inverseCommands: [CanvasCommand]
    ) {
        self.id = id
        self.name = name
        self.commands = commands
        self.timestamp = timestamp
        self.inverseCommands = inverseCommands
    }
    
    // MARK: - Properties
    
    /// Whether this transaction contains any undoable commands
    public var isUndoable: Bool {
        commands.contains { $0.isUndoable }
    }
    
    /// Whether this transaction is empty
    public var isEmpty: Bool {
        commands.isEmpty
    }
    
    /// Number of commands in this transaction
    public var count: Int {
        commands.count
    }
    
    /// IDs of all nodes affected by this transaction
    public var affectedNodeIds: Set<UUID> {
        var ids = Set<UUID>()
        for command in commands {
            switch command {
            case .moveNodes(let nodeIds, _),
                 .deleteNodes(let nodeIds),
                 .duplicate(let nodeIds),
                 .copy(let nodeIds),
                 .cut(let nodeIds),
                 .fitNodes(let nodeIds, _),
                 .bringToFront(let nodeIds),
                 .sendToBack(let nodeIds):
                ids.formUnion(nodeIds)
            case .moveNodeTo(let id, _),
                 .resizeNode(let id, _, _),
                 .setNodeParent(let id, _),
                 .setNodeZIndex(let id, _),
                 .toggleNodeSelection(let id):
                ids.insert(id)
            case .select(let nodeIds, _, _):
                ids.formUnion(nodeIds)
            default:
                break
            }
        }
        return ids
    }
    
    /// IDs of all edges affected by this transaction
    public var affectedEdgeIds: Set<UUID> {
        var ids = Set<UUID>()
        for command in commands {
            switch command {
            case .deleteEdges(let edgeIds):
                ids.formUnion(edgeIds)
            case .toggleEdgeSelection(let id):
                ids.insert(id)
            case .select(_, let edgeIds, _):
                ids.formUnion(edgeIds)
            default:
                break
            }
        }
        return ids
    }
}

// MARK: - TransactionBuilder

/// Result builder for creating transactions with a DSL-like syntax.
///
/// # Usage
/// ```swift
/// controller.transaction("My Transaction") {
///     .moveNodes(ids: ids, delta: delta)
///     .select(nodeIds: ids, edgeIds: [], additive: false)
/// }
/// ```
@resultBuilder
public struct TransactionBuilder {
    
    /// Build a block of commands
    public static func buildBlock(_ commands: CanvasCommand...) -> [CanvasCommand] {
        commands
    }
    
    /// Build an optional command
    public static func buildOptional(_ command: [CanvasCommand]?) -> [CanvasCommand] {
        command ?? []
    }
    
    /// Build an if-else statement
    public static func buildEither(first commands: [CanvasCommand]) -> [CanvasCommand] {
        commands
    }
    
    /// Build an if-else statement (else branch)
    public static func buildEither(second commands: [CanvasCommand]) -> [CanvasCommand] {
        commands
    }
    
    /// Build an array of commands
    public static func buildArray(_ components: [[CanvasCommand]]) -> [CanvasCommand] {
        components.flatMap { $0 }
    }
    
    /// Build from a single expression
    public static func buildExpression(_ command: CanvasCommand) -> [CanvasCommand] {
        [command]
    }
    
    /// Build from an array expression
    public static func buildExpression(_ commands: [CanvasCommand]) -> [CanvasCommand] {
        commands
    }
    
    /// Build final result
    public static func buildFinalResult(_ commands: [CanvasCommand]) -> [CanvasCommand] {
        commands
    }
}

// MARK: - CustomStringConvertible

extension CanvasTransaction: CustomStringConvertible {
    public var description: String {
        let cmdDescriptions = commands.prefix(3).map { $0.description }
        let suffix = commands.count > 3 ? ", ... (\(commands.count) total)" : ""
        return "Transaction(\"\(name)\", commands: [\(cmdDescriptions.joined(separator: ", "))\(suffix)])"
    }
}
