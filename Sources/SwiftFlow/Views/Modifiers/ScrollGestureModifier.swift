//
//  ScrollGestureModifier.swift
//  SwiftFlow
//
//  Modifier to capture native scroll events for trackpad support.
//

import SwiftUI
import AppKit

/// View modifier that captures native scroll events (trackpad/mouse wheel)
public struct ScrollGestureModifier: ViewModifier {
    let onScroll: (CGSize, NSEvent.Phase) -> Void
    let onMagnify: (CGFloat, CGPoint) -> Void
    let onDoubleClick: ((CGPoint) -> Void)?
    let isEnabled: Bool
    
    public func body(content: Content) -> some View {
        content
            .background(
                ScrollEventMonitorView(
                    onScroll: onScroll,
                    onMagnify: onMagnify,
                    onDoubleClick: onDoubleClick,
                    isEnabled: isEnabled
                )
            )
    }
}

/// NSView that uses local event monitors to capture scroll/magnify events
/// without interfering with SwiftUI's hit testing and gesture system
private struct ScrollEventMonitorView: NSViewRepresentable {
    let onScroll: (CGSize, NSEvent.Phase) -> Void
    let onMagnify: (CGFloat, CGPoint) -> Void
    let onDoubleClick: ((CGPoint) -> Void)?
    let isEnabled: Bool
    
    func makeNSView(context: Context) -> ScrollMonitorNSView {
        let view = ScrollMonitorNSView()
        view.onScroll = onScroll
        view.onMagnify = onMagnify
        view.onDoubleClick = onDoubleClick
        view.isEnabled = isEnabled
        return view
    }
    
    func updateNSView(_ nsView: ScrollMonitorNSView, context: Context) {
        nsView.onScroll = onScroll
        nsView.onMagnify = onMagnify
        nsView.onDoubleClick = onDoubleClick
        nsView.isEnabled = isEnabled
    }
}

/// NSView that monitors scroll and magnify events via local event monitors
/// This approach doesn't interfere with SwiftUI's gesture system
private class ScrollMonitorNSView: NSView {
    var onScroll: ((CGSize, NSEvent.Phase) -> Void)?
    var onMagnify: ((CGFloat, CGPoint) -> Void)?
    var onDoubleClick: ((CGPoint) -> Void)?
    var isEnabled: Bool = true
    
    private var scrollMonitor: Any?
    private var magnifyMonitor: Any?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupEventMonitors()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        removeEventMonitors()
    }
    
    // MARK: - Hit Testing
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        // CRITICAL: Return nil to let all mouse events pass through to SwiftUI
        // We capture scroll/magnify via event monitors instead
        return nil
    }
    
    // MARK: - Event Monitors
    
    private func setupEventMonitors() {
        // Monitor scroll wheel events
        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self = self, self.isEnabled else { return event }
            
            // Check if the event is within our view's bounds
            guard let window = self.window else { return event }
            let locationInWindow = event.locationInWindow
            let locationInView = self.convert(locationInWindow, from: nil)
            let locationInBounds = self.bounds.contains(locationInView)
            
            guard locationInBounds else { return event }
            
            // Process scroll for panning
            let delta = CGSize(
                width: event.scrollingDeltaX,
                height: event.scrollingDeltaY
            )
            
            if delta.width != 0 || delta.height != 0 {
                self.onScroll?(delta, event.phase)
            }
            
            // Return nil to consume the event (prevent further processing)
            // Or return event to allow it to propagate
            return nil
        }
        
        // Monitor magnify (pinch) events
        magnifyMonitor = NSEvent.addLocalMonitorForEvents(matching: .magnify) { [weak self] event in
            guard let self = self, self.isEnabled else { return event }
            
            // Check if the event is within our view's bounds
            guard let window = self.window else { return event }
            let locationInWindow = event.locationInWindow
            let locationInView = self.convert(locationInWindow, from: nil)
            let locationInBounds = self.bounds.contains(locationInView)
            
            guard locationInBounds else { return event }
            
            // Process magnification for zooming
            self.onMagnify?(event.magnification, locationInView)
            
            // Consume the event
            return nil
        }
    }
    
    private func removeEventMonitors() {
        if let monitor = scrollMonitor {
            NSEvent.removeMonitor(monitor)
            scrollMonitor = nil
        }
        if let monitor = magnifyMonitor {
            NSEvent.removeMonitor(monitor)
            magnifyMonitor = nil
        }
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        if window != nil {
            // Re-setup monitors when added to window
            if scrollMonitor == nil {
                setupEventMonitors()
            }
        } else {
            // Remove monitors when removed from window
            removeEventMonitors()
        }
    }
}

public extension View {
    /// Add native scroll/trackpad gesture support
    func scrollGesture(
        onScroll: @escaping (CGSize, NSEvent.Phase) -> Void,
        onMagnify: @escaping (CGFloat, CGPoint) -> Void,
        onDoubleClick: ((CGPoint) -> Void)? = nil,
        isEnabled: Bool = true
    ) -> some View {
        self.modifier(ScrollGestureModifier(
            onScroll: onScroll,
            onMagnify: onMagnify,
            onDoubleClick: onDoubleClick,
            isEnabled: isEnabled
        ))
    }
}
