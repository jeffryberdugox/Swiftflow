//
//  ResizeHandleView.swift
//  SwiftFlow
//
//  Visual resize handle for bottom-right corner of nodes.
//

import SwiftUI

/// Resize handle view displayed at the bottom-right corner of resizable nodes
public struct ResizeHandleView: View {
    let isVisible: Bool
    let isActive: Bool

    public init(isVisible: Bool, isActive: Bool = false) {
        self.isVisible = isVisible
        self.isActive = isActive
    }

    public var body: some View {
        Group {
            if isVisible {
                // Visual handle
                Capsule()
                    .fill(isActive ? Color.white : Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Capsule()
                            .stroke(Color.white, lineWidth: 1)
                    )
                    .compositingGroup()
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .scaleEffect(isActive ? 1.2 : 1.0)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ResizeHandleView(isVisible: true, isActive: false)
        ResizeHandleView(isVisible: true, isActive: true)
    }
    .padding()
}
