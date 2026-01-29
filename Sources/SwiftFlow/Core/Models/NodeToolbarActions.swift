//
//  NodeToolbarActions.swift
//  SwiftFlow
//
//  Actions available for node contextual toolbars.
//

import Foundation

/// Actions available for node toolbars
///
/// This struct provides closures for common node actions that can be
/// triggered from a contextual toolbar. Users can call these actions
/// or implement custom behavior.
///
/// Example usage:
/// ```swift
/// .nodeToolbar { node, panZoomManager, actions in
///     HStack {
///         Button("Delete") { actions.delete() }
///         Button("Duplicate") { actions.duplicate() }
///     }
/// }
/// ```
public struct NodeToolbarActions {
    /// Delete the currently selected node
    public let delete: () -> Void
    
    /// Duplicate the currently selected node
    public let duplicate: () -> Void
    
    /// Edit the currently selected node (shows inspector or editor)
    public let edit: () -> Void
    
    /// Copy the currently selected node to clipboard
    public let copy: () -> Void
    
    /// Cut the currently selected node
    public let cut: () -> Void
    
    /// Deselect the current node
    public let deselect: () -> Void
    
    /// Creates a new NodeToolbarActions instance
    /// - Parameters:
    ///   - delete: Closure called when delete action is triggered
    ///   - duplicate: Closure called when duplicate action is triggered
    ///   - edit: Closure called when edit action is triggered
    ///   - copy: Closure called when copy action is triggered
    ///   - cut: Closure called when cut action is triggered
    ///   - deselect: Closure called when deselect action is triggered
    public init(
        delete: @escaping () -> Void,
        duplicate: @escaping () -> Void,
        edit: @escaping () -> Void,
        copy: @escaping () -> Void,
        cut: @escaping () -> Void,
        deselect: @escaping () -> Void
    ) {
        self.delete = delete
        self.duplicate = duplicate
        self.edit = edit
        self.copy = copy
        self.cut = cut
        self.deselect = deselect
    }
    
    /// Creates a NodeToolbarActions with default no-op implementations
    public static var empty: NodeToolbarActions {
        NodeToolbarActions(
            delete: {},
            duplicate: {},
            edit: {},
            copy: {},
            cut: {},
            deselect: {}
        )
    }
}
