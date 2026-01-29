//
//  KeyboardConfig.swift
//  SwiftFlow
//
//  Configuration for keyboard shortcuts with granular control.
//

import Foundation
import AppKit

// MARK: - Canvas Action

/// Enum representing all canvas keyboard actions
public enum CanvasAction: String, CaseIterable, Hashable, Sendable {
    case copy
    case paste
    case cut
    case duplicate
    case delete
    case undo
    case redo
    case selectAll
    case escape  // Clear selection
}

// MARK: - Shortcut Binding

/// Configuration for a single keyboard shortcut
public struct ShortcutBinding: Equatable, Sendable {
    /// The key code for this shortcut
    public var keyCode: UInt16
    
    /// Modifier flags (command, shift, option, control)
    public var modifiers: NSEvent.ModifierFlags
    
    /// Whether this shortcut is enabled
    public var isEnabled: Bool
    
    public init(
        keyCode: UInt16,
        modifiers: NSEvent.ModifierFlags = [],
        isEnabled: Bool = true
    ) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.isEnabled = isEnabled
    }
    
    public static func == (lhs: ShortcutBinding, rhs: ShortcutBinding) -> Bool {
        lhs.keyCode == rhs.keyCode &&
        lhs.modifiers.rawValue == rhs.modifiers.rawValue &&
        lhs.isEnabled == rhs.isEnabled
    }
}

// MARK: - Keyboard Config

/// Configuration for all keyboard shortcuts
public struct KeyboardConfig: Equatable, Sendable {
    
    /// Individual shortcut bindings for each action
    public var bindings: [CanvasAction: ShortcutBinding]
    
    /// Master switch to enable/disable all shortcuts
    public var enabled: Bool
    
    // MARK: - Initialization
    
    public init(
        bindings: [CanvasAction: ShortcutBinding]? = nil,
        enabled: Bool = true
    ) {
        self.bindings = bindings ?? Self.defaultBindings
        self.enabled = enabled
    }
    
    // MARK: - Default Bindings
    
    /// Default key bindings for all actions
    public static var defaultBindings: [CanvasAction: ShortcutBinding] {
        [
            .copy: ShortcutBinding(keyCode: 8, modifiers: .command),           // Cmd+C
            .paste: ShortcutBinding(keyCode: 9, modifiers: .command),          // Cmd+V
            .cut: ShortcutBinding(keyCode: 7, modifiers: .command),            // Cmd+X
            .duplicate: ShortcutBinding(keyCode: 2, modifiers: .command),      // Cmd+D
            .delete: ShortcutBinding(keyCode: 51, modifiers: []),              // Delete/Backspace
            .undo: ShortcutBinding(keyCode: 6, modifiers: .command),           // Cmd+Z
            .redo: ShortcutBinding(keyCode: 6, modifiers: [.command, .shift]), // Cmd+Shift+Z
            .selectAll: ShortcutBinding(keyCode: 0, modifiers: .command),      // Cmd+A
            .escape: ShortcutBinding(keyCode: 53, modifiers: [])               // Escape
        ]
    }
    
    // MARK: - Builder Methods
    
    /// Disable a specific action
    public func disabling(_ action: CanvasAction) -> KeyboardConfig {
        var copy = self
        copy.bindings[action]?.isEnabled = false
        return copy
    }
    
    /// Disable multiple actions
    public func disabling(_ actions: [CanvasAction]) -> KeyboardConfig {
        var copy = self
        for action in actions {
            copy.bindings[action]?.isEnabled = false
        }
        return copy
    }
    
    /// Disable multiple actions (variadic)
    public func disabling(_ actions: CanvasAction...) -> KeyboardConfig {
        disabling(actions)
    }
    
    /// Enable a specific action
    public func enabling(_ action: CanvasAction) -> KeyboardConfig {
        var copy = self
        copy.bindings[action]?.isEnabled = true
        return copy
    }
    
    /// Enable multiple actions
    public func enabling(_ actions: [CanvasAction]) -> KeyboardConfig {
        var copy = self
        for action in actions {
            copy.bindings[action]?.isEnabled = true
        }
        return copy
    }
    
    /// Change key binding for an action
    public func binding(
        _ action: CanvasAction,
        to keyCode: UInt16,
        modifiers: NSEvent.ModifierFlags = []
    ) -> KeyboardConfig {
        var copy = self
        let wasEnabled = copy.bindings[action]?.isEnabled ?? true
        copy.bindings[action] = ShortcutBinding(
            keyCode: keyCode,
            modifiers: modifiers,
            isEnabled: wasEnabled
        )
        return copy
    }
    
    /// Disable all shortcuts
    public func disableAll() -> KeyboardConfig {
        var copy = self
        copy.enabled = false
        return copy
    }
    
    /// Enable all shortcuts
    public func enableAll() -> KeyboardConfig {
        var copy = self
        copy.enabled = true
        return copy
    }
    
    // MARK: - Equatable
    
    public static func == (lhs: KeyboardConfig, rhs: KeyboardConfig) -> Bool {
        lhs.enabled == rhs.enabled &&
        lhs.bindings == rhs.bindings
    }
}

// MARK: - Key Code Reference
//
// Common macOS key codes for reference:
// A=0, S=1, D=2, F=3, H=4, G=5, Z=6, X=7, C=8, V=9
// Delete=51, Escape=53, Return=36, Tab=48, Space=49
// Forward Delete=117
//
