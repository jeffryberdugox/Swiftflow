//
//  InteractionConfig.swift
//  SwiftFlow
//
//  Configuration for user interaction behavior.
//

import Foundation
import CoreGraphics

// MARK: - InteractionConfig

/// Configuration for user interaction behavior.
///
/// # Usage
/// ```swift
/// // Default (full editing)
/// let config = InteractionConfig()
///
/// // View only (no editing)
/// let config = InteractionConfig.viewOnly
///
/// // Custom mode
/// let config = InteractionConfig(
///     mode: .custom(InteractionPermissions(
///         canSelect: true,
///         canDrag: false,
///         canConnect: true,
///         canResize: false,
///         canBoxSelect: true,
///         canUseKeyboard: true
///     )),
///     dragThreshold: 5.0
/// )
/// ```
public struct InteractionConfig: Equatable, Sendable, Hashable {
    
    /// Interaction mode (edit, viewOnly, selectOnly, custom)
    public var mode: InteractionMode
    
    /// Minimum distance before drag starts (avoids accidental drags)
    public var dragThreshold: CGFloat
    
    /// Connection mode (strict or loose)
    public var connectionMode: ConnectionMode
    
    /// Selection mode (full, partial, none)
    public var selectionMode: SelectionMode
    
    // MARK: - Initialization
    
    /// Creates an interaction configuration.
    /// - Parameters:
    ///   - mode: Interaction mode. Default is `.edit`.
    ///   - dragThreshold: Minimum drag distance. Default is 3.0.
    ///   - connectionMode: Connection mode. Default is `.strict`.
    ///   - selectionMode: Selection mode. Default is `.full`.
    public init(
        mode: InteractionMode = .edit,
        dragThreshold: CGFloat = 3.0,
        connectionMode: ConnectionMode = .default,
        selectionMode: SelectionMode = .default
    ) {
        self.mode = mode
        self.dragThreshold = dragThreshold
        self.connectionMode = connectionMode
        self.selectionMode = selectionMode
    }
    
    // MARK: - Presets
    
    /// Default interaction (full editing)
    public static let `default` = InteractionConfig()
    
    /// View only (pan/zoom only)
    public static let viewOnly = InteractionConfig(mode: .viewOnly)
    
    /// Select only (no dragging or connecting)
    public static let selectOnly = InteractionConfig(mode: .selectOnly)
    
    /// Connect only (can create connections but not move)
    public static let connectOnly = InteractionConfig(mode: .connectOnly)
    
    // MARK: - Computed Properties
    
    /// Current permissions based on mode
    public var permissions: InteractionPermissions {
        mode.permissions
    }
    
    /// Whether selection is enabled
    public var canSelect: Bool {
        permissions.canSelect
    }
    
    /// Whether dragging is enabled
    public var canDrag: Bool {
        permissions.canDrag
    }
    
    /// Whether connections can be created
    public var canConnect: Bool {
        permissions.canConnect
    }
    
    /// Whether resizing is enabled
    public var canResize: Bool {
        permissions.canResize
    }
    
    /// Whether box selection is enabled
    public var canBoxSelect: Bool {
        permissions.canBoxSelect
    }
    
    /// Whether keyboard shortcuts are enabled
    public var canUseKeyboard: Bool {
        permissions.canUseKeyboard
    }
}

// MARK: - Codable

extension InteractionConfig: Codable {}
