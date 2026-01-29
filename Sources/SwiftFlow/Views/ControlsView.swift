//
//  ControlsView.swift
//  SwiftFlow
//
//  Controls panel with zoom, fit view, and lock buttons.
//

import SwiftUI

/// Position for the controls panel
public enum ControlsPosition: String, Sendable {
    case topLeft = "top-left"
    case topRight = "top-right"
    case bottomLeft = "bottom-left"
    case bottomRight = "bottom-right"
}

/// Configuration for controls
public struct ControlsConfig {
    public var position: ControlsPosition
    public var showZoom: Bool
    public var showFitView: Bool
    public var showLock: Bool
    public var showInteractiveToggle: Bool
    
    public init(
        position: ControlsPosition = .bottomLeft,
        showZoom: Bool = true,
        showFitView: Bool = true,
        showLock: Bool = false,
        showInteractiveToggle: Bool = false
    ) {
        self.position = position
        self.showZoom = showZoom
        self.showFitView = showFitView
        self.showLock = showLock
        self.showInteractiveToggle = showInteractiveToggle
    }
    
    public static let `default` = ControlsConfig()
}

/// Controls panel for canvas interactions
public struct ControlsView<Node: FlowNode>: View {
    let nodes: [Node]
    let onZoomIn: () -> Void
    let onZoomOut: () -> Void
    let onFitView: () -> Void
    let config: ControlsConfig
    
    @Binding var isLocked: Bool
    
    public init(
        nodes: [Node],
        isLocked: Binding<Bool> = .constant(false),
        config: ControlsConfig = .default,
        onZoomIn: @escaping () -> Void,
        onZoomOut: @escaping () -> Void,
        onFitView: @escaping () -> Void
    ) {
        self.nodes = nodes
        self._isLocked = isLocked
        self.config = config
        self.onZoomIn = onZoomIn
        self.onZoomOut = onZoomOut
        self.onFitView = onFitView
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            if config.showZoom {
                ControlButton(
                    icon: "minus",
                    action: onZoomOut,
                    help: "Zoom Out"
                )
                
                Divider()
                    .frame(height: 24)
                
                ControlButton(
                    icon: "plus",
                    action: onZoomIn,
                    help: "Zoom In"
                )
            }
            
            if config.showFitView && config.showZoom {
                Divider()
                    .frame(height: 24)
            }
            
            if config.showFitView {
                ControlButton(
                    icon: "arrow.up.left.and.arrow.down.right",
                    action: onFitView,
                    help: "Fit View"
                )
            }
            
            if config.showLock {
                if (config.showZoom || config.showFitView) {
                    Divider()
                        .frame(height: 24)
                }
                
                ControlButton(
                    icon: isLocked ? "lock.fill" : "lock.open",
                    action: { isLocked.toggle() },
                    help: isLocked ? "Unlock" : "Lock",
                    isActive: isLocked
                )
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .glassBackground(in: Capsule())
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Control Button

struct ControlButton: View {
    let icon: String
    let action: () -> Void
    let help: String
    var isActive: Bool = false
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .help(help)
        .background(backgroundForState)
        .foregroundColor(foregroundForState)
        .brightness(isHovered ? 0.1 : 0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var backgroundForState: some View {
        Group {
            if isActive {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.accentColor.opacity(0.15))
            } else {
                Color.clear
            }
        }
    }
    
    private var foregroundForState: Color {
        if isActive {
            return Color.primary
        } else {
            return Color.primary.opacity(0.7)
        }
    }
}

// MARK: - Preview

#Preview {
    ControlsView(
        nodes: [PreviewNode()],
        config: ControlsConfig(showLock: true),
        onZoomIn: { print("Zoom in") },
        onZoomOut: { print("Zoom out") },
        onFitView: { print("Fit view") }
    )
    .padding()
}
