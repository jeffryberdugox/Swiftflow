//
//  BoxSelectionManager.swift
//  SwiftFlow
//
//  Manager for box/rubber-band selection with real-time updates.
//

import Foundation
import SwiftUI

/// State for box selection
public struct BoxSelectionState: Equatable {
    /// Start point of selection box (screen coordinates)
    public var startPoint: CGPoint
    
    /// Current point of selection box (screen coordinates)
    public var currentPoint: CGPoint
    
    /// Whether selection is currently active
    public var isActive: Bool
    
    /// Whether to add to existing selection (Command key pressed)
    public var addToSelection: Bool
    
    /// Selection state before marquee started (for additive mode)
    public var preSelectionIds: Set<UUID>
    
    public init(
        startPoint: CGPoint = .zero,
        currentPoint: CGPoint = .zero,
        isActive: Bool = false,
        addToSelection: Bool = false,
        preSelectionIds: Set<UUID> = []
    ) {
        self.startPoint = startPoint
        self.currentPoint = currentPoint
        self.isActive = isActive
        self.addToSelection = addToSelection
        self.preSelectionIds = preSelectionIds
    }
    
    /// Get the selection rectangle in screen coordinates
    public var selectionRect: CGRect {
        let minX = min(startPoint.x, currentPoint.x)
        let minY = min(startPoint.y, currentPoint.y)
        let maxX = max(startPoint.x, currentPoint.x)
        let maxY = max(startPoint.y, currentPoint.y)
        
        return CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }
    
    /// Reset the state
    public mutating func reset() {
        startPoint = .zero
        currentPoint = .zero
        isActive = false
        addToSelection = false
        preSelectionIds = []
    }
}

/// Manager for box selection with real-time node selection updates
@MainActor
public class BoxSelectionManager: ObservableObject {
    
    @Published public var boxState = BoxSelectionState()
    
    private let panZoomManager: PanZoomManager
    private let selectionManager: SelectionManager
    
    /// Whether box selection is enabled
    public var isEnabled: Bool = true
    
    public init(
        panZoomManager: PanZoomManager,
        selectionManager: SelectionManager
    ) {
        self.panZoomManager = panZoomManager
        self.selectionManager = selectionManager
    }
    
    // MARK: - Box Selection
    
    /// Start box selection at a point
    /// - Parameters:
    ///   - point: Starting point in screen coordinates
    ///   - addToSelection: Whether to add to existing selection (Command key)
    public func startSelection(at point: CGPoint, addToSelection: Bool = false) {
        guard isEnabled else { return }
        
        boxState = BoxSelectionState(
            startPoint: point,
            currentPoint: point,
            isActive: true,
            addToSelection: addToSelection,
            preSelectionIds: addToSelection ? selectionManager.selectedNodes : []
        )
        
        // Clear selection if not adding
        if !addToSelection {
            selectionManager.clearSelection()
        }
    }
    
    /// Update box selection and select nodes in real-time
    /// - Parameters:
    ///   - point: Current point in screen coordinates
    ///   - nodes: All nodes to check for selection
    public func updateSelection<Node: FlowNode>(to point: CGPoint, nodes: [Node]) {
        guard boxState.isActive, isEnabled else { return }
        
        boxState.currentPoint = point
        
        // COORDINATE SYSTEM:
        // 1. Selection rectangle is drawn in screen space (from gesture)
        // 2. Convert to canvas space for comparison with node bounds
        // 3. node.bounds is in canvas space (position = top-left)
        let canvasRect = panZoomManager.transform.screenToCanvas(boxState.selectionRect)
        
        // Find nodes currently in the marquee rect
        let nodesInRect = nodes.filter { node in
            canvasRect.intersects(node.bounds)
        }
        let nodesInRectIds = Set(nodesInRect.map(\.id))
        
        // Calculate new selection
        let newSelection: Set<UUID>
        if boxState.addToSelection {
            // Union of pre-selection and current marquee selection
            newSelection = boxState.preSelectionIds.union(nodesInRectIds)
        } else {
            newSelection = nodesInRectIds
        }
        
        // Only update if selection changed (performance optimization)
        if newSelection != selectionManager.selectedNodes {
            selectionManager.selectNodes(newSelection, additive: false)
        }
    }
    
    /// End box selection (selection is already updated in real-time)
    public func endSelection() {
        boxState.reset()
    }
    
    /// Cancel box selection without applying changes
    public func cancelSelection() {
        // Restore pre-selection if in additive mode
        if boxState.addToSelection {
            selectionManager.selectNodes(boxState.preSelectionIds, additive: false)
        } else {
            selectionManager.clearSelection()
        }
        boxState.reset()
    }
}

// MARK: - Box Selection View

/// Visual representation of the selection box
public struct BoxSelectionView: View {
    @ObservedObject var boxManager: BoxSelectionManager
    
    /// Custom color for the selection box
    var selectionColor: Color
    
    public init(
        boxManager: BoxSelectionManager,
        selectionColor: Color = .accentColor
    ) {
        self.boxManager = boxManager
        self.selectionColor = selectionColor
    }
    
    public var body: some View {
        if boxManager.boxState.isActive {
            let rect = boxManager.boxState.selectionRect
            
            Rectangle()
                .fill(selectionColor.opacity(0.1))
                .overlay(
                    Rectangle()
                        .stroke(selectionColor, style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                )
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Box Selection Gesture

/// ViewModifier that adds box selection gesture with real-time updates
public struct BoxSelectionGesture<Node: FlowNode>: ViewModifier {
    @ObservedObject var boxManager: BoxSelectionManager
    let nodes: [Node]
    let isEnabled: Bool
    let isDraggingNodes: () -> Bool
    
    @State private var dragStart: CGPoint? = nil
    
    public init(
        boxManager: BoxSelectionManager,
        nodes: [Node],
        isEnabled: Bool = true,
        isDraggingNodes: @escaping () -> Bool = { false }
    ) {
        self.boxManager = boxManager
        self.nodes = nodes
        self.isEnabled = isEnabled
        self.isDraggingNodes = isDraggingNodes
    }
    
    public func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        guard isEnabled, !isDraggingNodes() else { return }
                        
                        if dragStart == nil {
                            dragStart = value.startLocation
                            
                            // Check for Command key (add to selection)
                            #if os(macOS)
                            let addToSelection = NSEvent.modifierFlags.contains(.command)
                            #else
                            let addToSelection = false
                            #endif
                            
                            boxManager.startSelection(at: value.startLocation, addToSelection: addToSelection)
                        }
                        
                        // Real-time update with current nodes
                        boxManager.updateSelection(to: value.location, nodes: nodes)
                    }
                    .onEnded { _ in
                        guard isEnabled else { return }
                        
                        boxManager.endSelection()
                        dragStart = nil
                    }
            )
    }
}

// MARK: - View Extension

public extension View {
    /// Add box selection gesture with real-time selection updates
    /// - Parameters:
    ///   - manager: The BoxSelectionManager to use
    ///   - nodes: Array of nodes to check for selection
    ///   - isEnabled: Whether box selection is enabled
    ///   - isDraggingNodes: Closure that returns true if nodes are being dragged
    func boxSelection<Node: FlowNode>(
        manager: BoxSelectionManager,
        nodes: [Node],
        isEnabled: Bool = true,
        isDraggingNodes: @escaping () -> Bool = { false }
    ) -> some View {
        self.modifier(BoxSelectionGesture(
            boxManager: manager,
            nodes: nodes,
            isEnabled: isEnabled,
            isDraggingNodes: isDraggingNodes
        ))
    }
}
