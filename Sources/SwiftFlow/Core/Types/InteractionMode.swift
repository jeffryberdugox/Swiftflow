//
//  InteractionMode.swift
//  SwiftFlow
//
//  Defines how users can interact with the canvas.
//  Uses enums instead of multiple booleans to avoid "boolean traps".
//

import Foundation

// MARK: - InteractionMode

/// Defines how users can interact with the canvas.
/// Replaces multiple boolean flags with a cleaner enum-based API.
///
/// # Usage
/// ```swift
/// // Preset modes
/// let config = CanvasConfig(interaction: .edit)      // Full editing
/// let config = CanvasConfig(interaction: .viewOnly)  // Pan/zoom only
///
/// // Custom mode with fine-grained control
/// let custom = InteractionConfig(
///     mode: .custom(InteractionPermissions(
///         canSelect: true,
///         canDrag: false,
///         canConnect: false,
///         canResize: false,
///         canBoxSelect: true,
///         canUseKeyboard: true
///     ))
/// )
/// ```
public enum InteractionMode: Equatable, Sendable, Hashable {

    /// Full editing mode: select, drag, connect, resize, box select, keyboard shortcuts.
    /// This is the default mode for most use cases.
    case edit
    
    /// View only mode: pan and zoom only, no selection or editing.
    /// Useful for presentations or read-only views.
    case viewOnly
    
    /// Select only mode: can select and box-select nodes, but not move, connect, or resize.
    /// Useful for inspection or comparison views.
    case selectOnly
    
    /// Connect only mode: can create connections but not move or resize nodes.
    /// Useful for connection-focused workflows.
    case connectOnly
    
    /// Custom mode: fine-grained control over individual permissions.
    case custom(InteractionPermissions)
    
    // MARK: - Computed Permissions
    
    /// Returns the permissions for this mode.
    public var permissions: InteractionPermissions {
        switch self {
        case .edit:
            return .all
        case .viewOnly:
            return .none
        case .selectOnly:
            return InteractionPermissions(
                canSelect: true,
                canDrag: false,
                canConnect: false,
                canResize: false,
                canBoxSelect: true,
                canUseKeyboard: true
            )
        case .connectOnly:
            return InteractionPermissions(
                canSelect: true,
                canDrag: false,
                canConnect: true,
                canResize: false,
                canBoxSelect: false,
                canUseKeyboard: true
            )
        case .custom(let permissions):
            return permissions
        }
    }
}

// MARK: - InteractionPermissions

/// Fine-grained permissions for canvas interaction.
/// Used with `InteractionMode.custom` for precise control.
public struct InteractionPermissions: Equatable, Sendable, Hashable {
    
    /// Whether nodes and edges can be selected
    public var canSelect: Bool
    
    /// Whether nodes can be dragged to new positions
    public var canDrag: Bool
    
    /// Whether new connections can be created between ports
    public var canConnect: Bool
    
    /// Whether nodes can be resized
    public var canResize: Bool
    
    /// Whether box/marquee selection is enabled
    public var canBoxSelect: Bool
    
    /// Whether keyboard shortcuts are active
    public var canUseKeyboard: Bool
    
    // MARK: - Initialization
    
    /// Creates interaction permissions with the specified options.
    public init(
        canSelect: Bool,
        canDrag: Bool,
        canConnect: Bool,
        canResize: Bool,
        canBoxSelect: Bool,
        canUseKeyboard: Bool
    ) {
        self.canSelect = canSelect
        self.canDrag = canDrag
        self.canConnect = canConnect
        self.canResize = canResize
        self.canBoxSelect = canBoxSelect
        self.canUseKeyboard = canUseKeyboard
    }
    
    // MARK: - Presets
    
    /// All interactions enabled
    public static let all = InteractionPermissions(
        canSelect: true,
        canDrag: true,
        canConnect: true,
        canResize: true,
        canBoxSelect: true,
        canUseKeyboard: true
    )
    
    /// All interactions disabled (view only)
    public static let none = InteractionPermissions(
        canSelect: false,
        canDrag: false,
        canConnect: false,
        canResize: false,
        canBoxSelect: false,
        canUseKeyboard: false
    )
    
    // MARK: - Modifiers
    
    /// Returns a copy with the specified permission enabled.
    public func enabling(_ keyPath: WritableKeyPath<InteractionPermissions, Bool>) -> InteractionPermissions {
        var copy = self
        copy[keyPath: keyPath] = true
        return copy
    }
    
    /// Returns a copy with the specified permission disabled.
    public func disabling(_ keyPath: WritableKeyPath<InteractionPermissions, Bool>) -> InteractionPermissions {
        var copy = self
        copy[keyPath: keyPath] = false
        return copy
    }
}

// MARK: - Codable

extension InteractionMode: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case permissions
    }
    
    private enum ModeType: String, Codable {
        case edit, viewOnly, selectOnly, connectOnly, custom
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ModeType.self, forKey: .type)
        
        switch type {
        case .edit:
            self = .edit
        case .viewOnly:
            self = .viewOnly
        case .selectOnly:
            self = .selectOnly
        case .connectOnly:
            self = .connectOnly
        case .custom:
            let permissions = try container.decode(InteractionPermissions.self, forKey: .permissions)
            self = .custom(permissions)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .edit:
            try container.encode(ModeType.edit, forKey: .type)
        case .viewOnly:
            try container.encode(ModeType.viewOnly, forKey: .type)
        case .selectOnly:
            try container.encode(ModeType.selectOnly, forKey: .type)
        case .connectOnly:
            try container.encode(ModeType.connectOnly, forKey: .type)
        case .custom(let permissions):
            try container.encode(ModeType.custom, forKey: .type)
            try container.encode(permissions, forKey: .permissions)
        }
    }
}

extension InteractionPermissions: Codable {}

// MARK: - CustomStringConvertible

extension InteractionMode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .edit:
            return "InteractionMode.edit"
        case .viewOnly:
            return "InteractionMode.viewOnly"
        case .selectOnly:
            return "InteractionMode.selectOnly"
        case .connectOnly:
            return "InteractionMode.connectOnly"
        case .custom(let permissions):
            return "InteractionMode.custom(\(permissions))"
        }
    }
}
