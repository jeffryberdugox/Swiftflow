//
//  UndoStack.swift
//  SwiftFlow
//
//  Manages undo/redo history for canvas operations.
//  Stores transactions and provides undo/redo functionality.
//

import Foundation
import Combine

// MARK: - UndoStack

/// Manages undo/redo history for canvas operations.
/// Stores transactions and provides navigation through history.
///
/// # Usage
/// ```swift
/// let undoStack = UndoStack(maxHistorySize: 50)
///
/// // Push a transaction
/// undoStack.push(transaction)
///
/// // Undo/redo
/// if undoStack.canUndo {
///     let transaction = undoStack.popUndo()
///     // Execute inverse commands
/// }
///
/// // Check state
/// print("Undo: \(undoStack.undoName ?? "None")")
/// print("Redo: \(undoStack.redoName ?? "None")")
/// ```
@MainActor
public class UndoStack: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Stack of transactions that can be undone (most recent last)
    @Published public private(set) var undoHistory: [CanvasTransaction] = []
    
    /// Stack of transactions that can be redone (most recent last)
    @Published public private(set) var redoHistory: [CanvasTransaction] = []
    
    // MARK: - Configuration
    
    /// Maximum number of transactions to keep in history
    public let maxHistorySize: Int
    
    // MARK: - Initialization
    
    /// Creates an undo stack with the specified history size.
    /// - Parameter maxHistorySize: Maximum number of transactions to keep. Default is 50.
    public init(maxHistorySize: Int = 50) {
        self.maxHistorySize = max(1, maxHistorySize)
    }
    
    // MARK: - State
    
    /// Whether there are transactions to undo
    public var canUndo: Bool {
        !undoHistory.isEmpty
    }
    
    /// Whether there are transactions to redo
    public var canRedo: Bool {
        !redoHistory.isEmpty
    }
    
    /// Name of the transaction that would be undone
    public var undoName: String? {
        undoHistory.last?.name
    }
    
    /// Name of the transaction that would be redone
    public var redoName: String? {
        redoHistory.last?.name
    }
    
    /// Number of transactions in undo history
    public var undoCount: Int {
        undoHistory.count
    }
    
    /// Number of transactions in redo history
    public var redoCount: Int {
        redoHistory.count
    }
    
    // MARK: - Operations
    
    /// Push a transaction onto the undo stack.
    /// Clears the redo stack since we're creating a new branch in history.
    /// - Parameter transaction: The transaction to push
    public func push(_ transaction: CanvasTransaction) {
        guard transaction.isUndoable else { return }
        
        undoHistory.append(transaction)
        redoHistory.removeAll()
        
        // Trim history if needed
        trimHistory()
    }
    
    /// Pop the most recent transaction from the undo stack.
    /// Moves it to the redo stack.
    /// - Returns: The transaction to undo, or nil if nothing to undo
    public func popUndo() -> CanvasTransaction? {
        guard let transaction = undoHistory.popLast() else {
            return nil
        }
        
        redoHistory.append(transaction)
        return transaction
    }
    
    /// Pop the most recent transaction from the redo stack.
    /// Moves it back to the undo stack.
    /// - Returns: The transaction to redo, or nil if nothing to redo
    public func popRedo() -> CanvasTransaction? {
        guard let transaction = redoHistory.popLast() else {
            return nil
        }
        
        undoHistory.append(transaction)
        return transaction
    }
    
    /// Clear all history (both undo and redo)
    public func clear() {
        undoHistory.removeAll()
        redoHistory.removeAll()
    }
    
    /// Clear only the redo history
    public func clearRedo() {
        redoHistory.removeAll()
    }
    
    // MARK: - Batch Operations
    
    /// Begin a batch operation that will group multiple pushes into one transaction.
    /// Call `endBatch` to finalize.
    private var batchCommands: [CanvasCommand]?
    private var batchName: String?
    
    /// Start batching commands into a single transaction.
    /// - Parameter name: Name for the batched transaction
    public func beginBatch(name: String) {
        batchCommands = []
        batchName = name
    }
    
    /// Add a command to the current batch.
    /// - Parameter command: Command to add
    public func addToBatch(_ command: CanvasCommand) {
        batchCommands?.append(command)
    }
    
    /// End the batch and push the combined transaction.
    /// - Returns: The created transaction, or nil if batch was empty
    @discardableResult
    public func endBatch() -> CanvasTransaction? {
        guard let commands = batchCommands,
              let name = batchName,
              !commands.isEmpty else {
            batchCommands = nil
            batchName = nil
            return nil
        }
        
        let transaction = CanvasTransaction(name: name, commands: commands)
        batchCommands = nil
        batchName = nil
        
        push(transaction)
        return transaction
    }
    
    /// Cancel the current batch without pushing
    public func cancelBatch() {
        batchCommands = nil
        batchName = nil
    }
    
    /// Whether a batch is currently in progress
    public var isBatching: Bool {
        batchCommands != nil
    }
    
    // MARK: - Private
    
    private func trimHistory() {
        while undoHistory.count > maxHistorySize {
            undoHistory.removeFirst()
        }
    }
}

// MARK: - UndoStackSnapshot

/// A snapshot of the undo stack state for comparison
@MainActor
public struct UndoStackSnapshot: Equatable {
    public let undoCount: Int
    public let redoCount: Int
    public let lastUndoId: UUID?
    public let lastRedoId: UUID?
    
    public init(from stack: UndoStack) {
        self.undoCount = stack.undoCount
        self.redoCount = stack.redoCount
        self.lastUndoId = stack.undoHistory.last?.id
        self.lastRedoId = stack.redoHistory.last?.id
    }
}

// MARK: - Debug Description

extension UndoStack {
    /// Debug description showing current stack state
    public var debugDescription: String {
        "UndoStack(undo: \(undoHistory.count), redo: \(redoHistory.count))"
    }
}
