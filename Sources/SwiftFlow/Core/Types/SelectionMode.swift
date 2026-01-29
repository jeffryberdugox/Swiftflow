//
//  SelectionMode.swift
//  SwiftFlow
//
//  Defines how nodes and edges can be selected.
//

import Foundation

/// Selection behavior mode
public enum SelectionMode: Equatable, Sendable, Hashable, Codable {
    /// Full selection with multi-select support
    case full
    
    /// Partial selection (nodes only, no edges)
    case partial
    
    /// No selection allowed
    case none
    
    public static let `default`: SelectionMode = .full
}

// MARK: - Conversion to InteractionPermissions

extension SelectionMode {
    /// Convert to InteractionPermissions for internal use
    public func toInteractionPermissions() -> InteractionPermissions {
        switch self {
        case .full:
            return InteractionPermissions.all
        case .partial:
            return InteractionPermissions(
                canSelect: true,
                canDrag: true,
                canConnect: true,
                canResize: true,
                canBoxSelect: true,
                canUseKeyboard: true
            )
        case .none:
            return InteractionPermissions(
                canSelect: false,
                canDrag: false,
                canConnect: false,
                canResize: false,
                canBoxSelect: false,
                canUseKeyboard: false
            )
        }
    }
}
