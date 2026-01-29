//
//  KeyboardShortcutsManager.swift
//  SwiftFlow
//
//  Manager for keyboard shortcuts with configurable bindings.
//

import SwiftUI
import AppKit

// MARK: - Keyboard Shortcuts Manager

/// Manager for handling keyboard shortcuts with configurable bindings
@MainActor
public class KeyboardShortcutsManager: ObservableObject {
    
    // MARK: - Configuration
    
    /// Keyboard configuration with all bindings
    @Published public var config: KeyboardConfig
    
    // MARK: - Dependencies
    
    private let selectionManager: SelectionManager
    
    // MARK: - Callbacks
    
    /// Called when any action is triggered (default handler)
    public var onAction: ((CanvasAction) -> Void)?
    
    /// Custom handlers per action that can override default behavior
    public var customHandlers: [CanvasAction: () -> ActionResult] = [:]
    
    // MARK: - Initialization
    
    public init(
        selectionManager: SelectionManager,
        config: KeyboardConfig = KeyboardConfig()
    ) {
        self.selectionManager = selectionManager
        self.config = config
    }
    
    // MARK: - Key Event Handling
    
    /// Handle key down event
    /// - Parameter event: The NSEvent for the key press
    /// - Returns: true if the event was handled, false otherwise
    public func handleKeyDown(_ event: NSEvent) -> Bool {
        // Check master switch
        guard config.enabled else { return false }
        
        // Find matching action for this key event
        guard let action = findAction(for: event) else { return false }
        
        // Check if this specific action is enabled
        guard config.bindings[action]?.isEnabled == true else { return false }
        
        // Try custom handler first
        if let customHandler = customHandlers[action] {
            let result = customHandler()
            if result == .handled {
                return true
            }
        }
        
        // Handle special case for escape (clear selection)
        if action == .escape {
            selectionManager.clearSelection()
            return true
        }
        
        // Fire the unified action callback
        onAction?(action)
        
        return true
    }
    
    // MARK: - Action Finding
    
    /// Find which action corresponds to a key event
    private func findAction(for event: NSEvent) -> CanvasAction? {
        // Get relevant modifier flags only
        let relevantModifiers: NSEvent.ModifierFlags = [.command, .shift, .option, .control]
        let eventModifiers = event.modifierFlags.intersection(relevantModifiers)
        
        for (action, binding) in config.bindings {
            let bindingModifiers = binding.modifiers.intersection(relevantModifiers)
            
            if event.keyCode == binding.keyCode && eventModifiers == bindingModifiers {
                return action
            }
        }
        
        // Handle forward delete as alternative to delete
        if event.keyCode == 117 { // Forward Delete
            return .delete
        }
        
        return nil
    }
    
    // MARK: - Configuration Helpers
    
    /// Check if an action is enabled
    public func isActionEnabled(_ action: CanvasAction) -> Bool {
        config.enabled && (config.bindings[action]?.isEnabled ?? false)
    }
    
    /// Enable or disable an action at runtime
    public func setActionEnabled(_ action: CanvasAction, enabled: Bool) {
        config.bindings[action]?.isEnabled = enabled
    }
    
    /// Set a custom handler for an action
    public func setCustomHandler(for action: CanvasAction, handler: @escaping () -> ActionResult) {
        customHandlers[action] = handler
    }
    
    /// Remove custom handler for an action
    public func removeCustomHandler(for action: CanvasAction) {
        customHandlers.removeValue(forKey: action)
    }
}

// MARK: - View Modifier

/// View modifier to add keyboard shortcuts to a view
public struct KeyboardShortcutsModifier: ViewModifier {
    @ObservedObject var manager: KeyboardShortcutsManager
    let isEnabled: Bool
    
    public func body(content: Content) -> some View {
        content
            .background(
                KeyEventHandlingView(
                    onKeyDown: { event in
                        guard isEnabled else { return false }
                        return manager.handleKeyDown(event)
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
    }
}

// MARK: - Key Event Handling View (NSViewRepresentable)

/// NSViewRepresentable for capturing key events
private struct KeyEventHandlingView: NSViewRepresentable {
    let onKeyDown: (NSEvent) -> Bool
    
    func makeNSView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.onKeyDown = onKeyDown
        return view
    }
    
    func updateNSView(_ nsView: KeyCaptureView, context: Context) {
        nsView.onKeyDown = onKeyDown
    }
}

// MARK: - Key Capture View (NSView)

/// Custom NSView that captures keyboard events
private class KeyCaptureView: NSView {
    var onKeyDown: ((NSEvent) -> Bool)?
    private var trackingArea: NSTrackingArea?
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        autoresizingMask = [.width, .height]
        wantsLayer = true
    }
    
    // MARK: - First Responder
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        return true
    }
    
    // MARK: - Tracking Area
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        // Remove existing tracking area
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        
        // Create new tracking area
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [
                .activeInKeyWindow,
                .mouseEnteredAndExited,
                .inVisibleRect
            ],
            owner: self,
            userInfo: nil
        )
        
        if let area = trackingArea {
            addTrackingArea(area)
        }
    }
    
    // MARK: - Mouse Events (for focus management)
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        // Request focus when mouse enters the canvas
        DispatchQueue.main.async { [weak self] in
            self?.window?.makeFirstResponder(self)
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        // Request focus on click
        window?.makeFirstResponder(self)
        super.mouseDown(with: event)
    }
    
    // MARK: - Key Events
    
    override func keyDown(with event: NSEvent) {
        if let handler = onKeyDown, handler(event) {
            // Event was handled, don't propagate
            return
        }
        // Pass to next responder if not handled
        super.keyDown(with: event)
    }
    
    // MARK: - Window Events
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        // Become first responder when added to window
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let window = self.window else { return }
            window.makeFirstResponder(self)
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Add keyboard shortcuts support to this view
    /// - Parameters:
    ///   - manager: The KeyboardShortcutsManager instance
    ///   - isEnabled: Whether shortcuts are enabled (default: true)
    /// - Returns: Modified view with keyboard shortcut support
    func keyboardShortcuts(
        manager: KeyboardShortcutsManager,
        isEnabled: Bool = true
    ) -> some View {
        self.modifier(KeyboardShortcutsModifier(manager: manager, isEnabled: isEnabled))
    }
}
