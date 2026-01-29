//
//  ResizableModifier.swift
//  SwiftFlow
//
//  View modifier that adds resize functionality to nodes.
//

import SwiftUI

/// View modifier that adds resize handle and gesture to a node
struct ResizableModifier: ViewModifier {
    let nodeId: UUID
    let nodeSize: CGSize
    let isSelected: Bool
    let isResizable: Bool

    @EnvironmentObject var resizeManager: ResizeManager
    @EnvironmentObject var controller: CanvasController

    @State private var isHoveringHandle = false

    // Resize handle configuration
    private let handleSize: CGFloat = 12
    private let hitAreaPadding: CGFloat = 6  // Extra hit area: 12 + 6*2 = 24pt total
    private let handleInset: CGFloat = 6  // Spacing from node border to avoid content overlap
    
    // Track if this specific node is being resized to avoid unnecessary updates
    private var isThisNodeResizing: Bool {
        resizeManager.resizeState?.nodeId == nodeId
    }

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottomTrailing) {
                if isResizable && isSelected {
                    resizeHandle
                }
            }
    }

    private var resizeHandle: some View {
        ResizeHandleView(
            isVisible: true,
            isActive: isHoveringHandle || resizeManager.isResizing
        )
        .padding(.trailing, handleInset)
        .padding(.bottom, handleInset)
        .frame(width: handleSize + hitAreaPadding * 2, height: handleSize + hitAreaPadding * 2)
        .contentShape(Rectangle())  // Expand hit area
        .onHover { hovering in
            isHoveringHandle = hovering
            // TODO: Set cursor to resize cursor on macOS
        }
        .gesture(resizeGesture)
    }

    private var resizeGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                if !resizeManager.isResizing {
                    // Start resize with the initial size
                    resizeManager.startResize(
                        nodeId: nodeId,
                        originalSize: nodeSize,
                        at: value.startLocation,
                        anchor: .topLeft  // Bottom-right resize = top-left stays fixed
                    )
                }

                // Update resize preview in global space for stable delta
                resizeManager.updateResize(to: value.location)
            }
            .onEnded { _ in
                // End resize and apply final size through command system
                if let finalSize = resizeManager.endResize() {
                    controller.resizeNode(id: nodeId, to: finalSize, anchor: .topLeft)
                }
            }
    }
}

// MARK: - View Extension

public extension View {
    /// Makes the view resizable by adding a resize handle and gesture
    /// - Parameters:
    ///   - nodeId: ID of the node
    ///   - nodeSize: Current size of the node
    ///   - isSelected: Whether the node is currently selected
    ///   - isResizable: Whether the node can be resized
    func resizable(
        nodeId: UUID,
        nodeSize: CGSize,
        isSelected: Bool,
        isResizable: Bool
    ) -> some View {
        self.modifier(
            ResizableModifier(
                nodeId: nodeId,
                nodeSize: nodeSize,
                isSelected: isSelected,
                isResizable: isResizable
            )
        )
    }
}
