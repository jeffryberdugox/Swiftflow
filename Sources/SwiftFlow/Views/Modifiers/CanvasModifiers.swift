//
//  CanvasModifiers.swift
//  SwiftFlow
//
//  Fluent modifiers for configuring CanvasView.
//  Provides SwiftUI-style configuration API.
//
//  Note: Most modifiers are defined as extensions on CanvasView directly.
//  This file contains additional convenience helpers and presets.
//

import SwiftUI

// MARK: - Convenience Type Aliases

/// Shorthand for common modifier configurations.
/// Use these by creating a CanvasConfig with the appropriate preset
/// or by applying modifiers directly.
///
/// # Example
/// ```swift
/// // Using CanvasConfig preset
/// CanvasView(nodes: $nodes, edges: $edges, config: .minimal) { ... }
///
/// // Using presets
/// CanvasView(nodes: $nodes, edges: $edges, config: .presentation) { ... }
/// ```
public enum CanvasModifierPresets {
    // Config-based presets are available via CanvasConfig.minimal, CanvasConfig.presentation, etc.
}
