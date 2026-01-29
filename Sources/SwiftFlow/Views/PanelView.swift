//
//  PanelView.swift
//  SwiftFlow
//
//  Generic panel component for positioning UI elements on the canvas.
//

import SwiftUI

/// Position for panel placement
public enum PanelPosition: String, CaseIterable, Sendable {
    case topLeft = "top-left"
    case topCenter = "top-center"
    case topRight = "top-right"
    case bottomLeft = "bottom-left"
    case bottomCenter = "bottom-center"
    case bottomRight = "bottom-right"
}

/// Generic panel for positioning UI on canvas
public struct PanelView<Content: View>: View {
    let position: PanelPosition
    let padding: CGFloat
    let content: Content
    
    public init(
        position: PanelPosition = .topLeft,
        padding: CGFloat = 10,
        @ViewBuilder content: () -> Content
    ) {
        self.position = position
        self.padding = padding
        self.content = content()
    }
    
    public var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignmentForPosition)
            .padding(paddingEdgeInsets)
    }
    
    private var alignmentForPosition: Alignment {
        switch position {
        case .topLeft:
            return .topLeading
        case .topCenter:
            return .top
        case .topRight:
            return .topTrailing
        case .bottomLeft:
            return .bottomLeading
        case .bottomCenter:
            return .bottom
        case .bottomRight:
            return .bottomTrailing
        }
    }
    
    private var paddingEdgeInsets: EdgeInsets {
        switch position {
        case .topLeft:
            return EdgeInsets(top: padding, leading: padding, bottom: 0, trailing: 0)
        case .topCenter:
            return EdgeInsets(top: padding, leading: 0, bottom: 0, trailing: 0)
        case .topRight:
            return EdgeInsets(top: padding, leading: 0, bottom: 0, trailing: padding)
        case .bottomLeft:
            return EdgeInsets(top: 0, leading: padding, bottom: padding, trailing: 0)
        case .bottomCenter:
            return EdgeInsets(top: 0, leading: 0, bottom: padding, trailing: 0)
        case .bottomRight:
            return EdgeInsets(top: 0, leading: 0, bottom: padding, trailing: padding)
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Add a panel overlay to this view
    func panel<Content: View>(
        position: PanelPosition = .topLeft,
        padding: CGFloat = 10,
        @ViewBuilder content: () -> Content
    ) -> some View {
        self.overlay(
            PanelView(position: position, padding: padding, content: content)
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.2)
        
        PanelView(position: .topLeft) {
            Text("Top Left")
                .padding(8)
                .background(Color.white)
                .cornerRadius(6)
        }
        
        PanelView(position: .topRight) {
            Text("Top Right")
                .padding(8)
                .background(Color.white)
                .cornerRadius(6)
        }
        
        PanelView(position: .bottomLeft) {
            Text("Bottom Left")
                .padding(8)
                .background(Color.white)
                .cornerRadius(6)
        }
        
        PanelView(position: .bottomRight) {
            Text("Bottom Right")
                .padding(8)
                .background(Color.white)
                .cornerRadius(6)
        }
    }
    .frame(width: 600, height: 400)
}
