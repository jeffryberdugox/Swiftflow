//
//  NodeSizeEnvironment.swift
//  SwiftFlow
//
//  Environment key for passing current node size during resize operations.
//

import SwiftUI

// MARK: - Node Current Size Environment Key

/// Environment key for current node size during resize
private struct NodeCurrentSizeKey: EnvironmentKey {
    static let defaultValue: CGSize? = nil
}

public extension EnvironmentValues {
    /// The current size of the node (may differ from stored size during resize)
    /// - Note: This is `nil` when node is not being resized, in which case
    ///         the node should use its stored `width` and `height` properties.
    var nodeCurrentSize: CGSize? {
        get { self[NodeCurrentSizeKey.self] }
        set { self[NodeCurrentSizeKey.self] = newValue }
    }
}
