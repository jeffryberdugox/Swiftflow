//
//  HistoryConfig.swift
//  SwiftFlow
//
//  Configuration for undo/redo history.
//

import Foundation

// MARK: - HistoryConfig

/// Configuration for undo/redo history.
///
/// # Usage
/// ```swift
/// // Default history
/// let config = HistoryConfig()
///
/// // Larger history
/// let config = HistoryConfig(maxUndoCount: 100)
///
/// // Disabled
/// let config = HistoryConfig.disabled
/// ```
public struct HistoryConfig: Equatable, Sendable, Hashable {
    
    /// Whether undo/redo is enabled
    public var enabled: Bool
    
    /// Maximum number of undo steps
    public var maxUndoCount: Int
    
    // MARK: - Initialization
    
    /// Creates a history configuration.
    /// - Parameters:
    ///   - enabled: Enable undo/redo. Default is true.
    ///   - maxUndoCount: Maximum undo steps. Default is 50.
    public init(
        enabled: Bool = true,
        maxUndoCount: Int = 50
    ) {
        self.enabled = enabled
        self.maxUndoCount = max(1, maxUndoCount)
    }
    
    // MARK: - Presets
    
    /// Default history configuration
    public static let `default` = HistoryConfig()
    
    /// Large history (100 steps)
    public static let large = HistoryConfig(maxUndoCount: 100)
    
    /// Small history (20 steps)
    public static let small = HistoryConfig(maxUndoCount: 20)
    
    /// History disabled
    public static let disabled = HistoryConfig(enabled: false, maxUndoCount: 0)
}

// MARK: - Codable

extension HistoryConfig: Codable {}
