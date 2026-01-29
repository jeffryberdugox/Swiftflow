//
//  MiniMapView.swift
//  SwiftFlow
//
//  MiniMap component for canvas navigation using Canvas API.
//

import SwiftUI

/// MiniMap view that displays a bird's-eye view of the canvas with interactive viewport indicator
public struct MiniMapView<Node: FlowNode>: View {
    // MARK: - Properties
    
    let nodes: [Node]
    let selectedNodes: Set<UUID>
    @ObservedObject var panZoomManager: PanZoomManager
    @ObservedObject var controller: MiniMapController
    let config: MiniMapConfig
    
    // MARK: - Local State
    
    @State private var isDraggingViewport: Bool = false
    
    // MARK: - Initialization
    
    public init(
        nodes: [Node],
        selectedNodes: Set<UUID>,
        panZoomManager: PanZoomManager,
        controller: MiniMapController,
        config: MiniMapConfig
    ) {
        self.nodes = nodes
        self.selectedNodes = selectedNodes
        self.panZoomManager = panZoomManager
        self.controller = controller
        self.config = config
        
        // Update controller with current size
        controller.miniMapSize = CGSize(width: config.width, height: config.height)
    }
    
    // MARK: - Body
    
    public var body: some View {
        Canvas { context, size in
            // 1. Background - transparent, material applied outside Canvas
            
            // 2. Draw nodes
            for node in nodes {
                let miniMapRect = nodeBoundsInMiniMap(node)
                let color = nodeColor(for: node.id)
                
                // Node fill (background de cada nodo)
                let nodePath = Path(
                    roundedRect: miniMapRect,
                    cornerRadius: config.nodeBorderRadius
                )
                context.fill(nodePath, with: .color(color))
                
                // Node border
                if config.nodeStrokeWidth > 0 {
                    context.stroke(
                        nodePath,
                        with: .color(config.nodeStrokeColor),
                        lineWidth: config.nodeStrokeWidth
                    )
                }
                
                // Node labels (if enabled and node is large enough)
                if config.showNodeLabels && miniMapRect.width >= config.minimumNodeSizeForLabel {
                    if let label = config.nodeLabelProvider?(node.id) {
                        drawLabel(
                            context: context,
                            text: label,
                            rect: miniMapRect,
                            font: config.nodeLabelFont,
                            color: config.nodeLabelColor
                        )
                    }
                }
            }
            
            // 3. Draw viewport indicator (rectángulo del área visible)
            let vpRect = controller.viewportIndicatorFrame
            let vpPath = Path(
                roundedRect: vpRect,
                cornerRadius: config.maskCornerRadius
            )
            
            // Viewport fill
            context.fill(vpPath, with: .color(config.maskColor))
            
            // Viewport border (con soporte para dash pattern)
            if let dashPattern = config.maskStrokeDashPattern {
                context.stroke(
                    vpPath,
                    with: .color(config.maskStrokeColor),
                    style: StrokeStyle(
                        lineWidth: config.maskStrokeWidth,
                        dash: dashPattern
                    )
                )
            } else {
                context.stroke(
                    vpPath,
                    with: .color(config.maskStrokeColor),
                    lineWidth: config.maskStrokeWidth
                )
            }
        }
        .frame(width: config.width, height: config.height)
        .glassBackground(in: RoundedRectangle(cornerRadius: config.cornerRadius))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .gesture(dragGesture)
        .gesture(tapGesture)
        .gesture(magnificationGesture)
        .onAppear {
            updateControllerInputs()
        }
        .onChange(of: nodes.map { $0.position }) { _ in
            updateControllerInputs()
        }
        .onChange(of: panZoomManager.transform) { _ in
            updateControllerInputs()
        }
    }
    
    // MARK: - Controller Updates
    
    /// Update the controller with current node bounds and viewport
    private func updateControllerInputs() {
        // Calculate nodes bounds
        controller.nodesBounds = calculateNodesBounds()
        
        // Calculate viewport rect in canvas coordinates
        let viewportRect = CGRect(origin: .zero, size: panZoomManager.viewportSize)
        let canvasRect = panZoomManager.transform.screenToCanvas(viewportRect)
        controller.viewportRectCanvas = CanvasRect(canvasRect)
    }
    
    /// Calculate bounds of all nodes
    private func calculateNodesBounds() -> CanvasRect {
        guard !nodes.isEmpty else { return .zero }
        
        var minX = CGFloat.infinity
        var minY = CGFloat.infinity
        var maxX = -CGFloat.infinity
        var maxY = -CGFloat.infinity
        
        for node in nodes {
            minX = Swift.min(minX, node.position.x)
            minY = Swift.min(minY, node.position.y)
            maxX = Swift.max(maxX, node.position.x + node.width)
            maxY = Swift.max(maxY, node.position.y + node.height)
        }
        
        return CanvasRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }
    
    /// Calculate minimap bounds for a node
    private func nodeBoundsInMiniMap(_ node: Node) -> CGRect {
        let canvasRect = CanvasRect(
            x: node.position.x,
            y: node.position.y,
            width: node.width,
            height: node.height
        )
        return controller.canvasToMiniMap(canvasRect)
    }
    
    // MARK: - Gestures
    
    /// Drag gesture for panning the viewport
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard config.pannable else { return }
                isDraggingViewport = true
                handleViewportDrag(at: value.location)
            }
            .onEnded { _ in
                isDraggingViewport = false
            }
    }
    
    /// Tap gesture for click-to-move functionality
    private var tapGesture: some Gesture {
        TapGesture()
            .onEnded { }  // Handled by SpatialTapGesture below
    }
    
    /// Magnification gesture for zooming
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                guard config.zoomable else { return }
                // Zoom towards center of viewport
                let viewportCenter = CGPoint(
                    x: panZoomManager.viewportSize.width / 2,
                    y: panZoomManager.viewportSize.height / 2
                )
                let zoomFactor = 1.0 + (value - 1.0) * config.zoomSensitivity
                panZoomManager.zoom(by: zoomFactor, at: viewportCenter)
            }
    }
    
    // MARK: - Helper Methods
    
    /// Get the color for a node
    /// - Parameter nodeId: ID of the node
    /// - Returns: Color to use for the node
    private func nodeColor(for nodeId: UUID) -> Color {
        if config.showSelectionInMiniMap && selectedNodes.contains(nodeId) {
            return config.selectedNodeColor
        }
        return config.nodeColorProvider?(nodeId) ?? config.nodeColor
    }
    
    /// Draw a label centered in a rectangle
    /// - Parameters:
    ///   - context: Graphics context
    ///   - text: Text to draw
    ///   - rect: Rectangle to center text in
    ///   - font: Font for text
    ///   - color: Color for text
    private func drawLabel(
        context: GraphicsContext,
        text: String,
        rect: CGRect,
        font: Font,
        color: Color
    ) {
        let resolvedText = context.resolve(
            Text(text)
                .font(font)
                .foregroundColor(color)
        )
        let textSize = resolvedText.measure(in: rect.size)
        let textOrigin = CGPoint(
            x: rect.midX - textSize.width / 2,
            y: rect.midY - textSize.height / 2
        )
        context.draw(resolvedText, at: textOrigin)
    }
    
    /// Handle viewport drag to pan the canvas
    /// - Parameter location: Location in minimap space
    private func handleViewportDrag(at location: CGPoint) {
        // Convert minimap location to canvas position
        let canvasPos = controller.miniMapToCanvas(location)
        
        // Calculate viewport size in canvas space
        let viewportSizeCanvas = panZoomManager.transform.screenToCanvas(
            panZoomManager.viewportSize
        )
        
        // Calculate new viewport top-left to center the viewport at the drag location
        let newViewportTopLeftCanvas = CGPoint(
            x: canvasPos.x - viewportSizeCanvas.width / 2,
            y: canvasPos.y - viewportSizeCanvas.height / 2
        )
        
        // Calculate new offset
        // Formula: screen = canvas * scale + offset
        // For viewport top-left at screen position (0, 0):
        // 0 = newViewportTopLeftCanvas * scale + offset
        // offset = -newViewportTopLeftCanvas * scale
        let newOffset = CGPoint(
            x: -newViewportTopLeftCanvas.x * panZoomManager.transform.scale,
            y: -newViewportTopLeftCanvas.y * panZoomManager.transform.scale
        )
        
        panZoomManager.setOffset(newOffset)
    }
}

// MARK: - View Extension for Click-to-Move

extension MiniMapView {
    /// Add spatial tap gesture for click-to-move functionality
    func onSpatialTap(perform action: @escaping (CGPoint) -> Void) -> some View {
        self.overlay(
            GeometryReader { geometry in
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        if config.clickToMove {
                            handleViewportDrag(at: location)
                        }
                    }
            }
        )
    }
}

// MARK: - Preview

#Preview("MiniMap with Nodes") {
    let nodes = [
        PreviewNode(position: CGPoint(x: 0, y: 0), width: 100, height: 80),
        PreviewNode(position: CGPoint(x: 200, y: 100), width: 120, height: 90),
        PreviewNode(position: CGPoint(x: 400, y: 50), width: 100, height: 80)
    ]
    
    @StateObject var panZoomManager = PanZoomManager(minZoom: 0.1, maxZoom: 4.0)
    @StateObject var controller = MiniMapController()
    
    return MiniMapView(
        nodes: nodes,
        selectedNodes: [nodes[1].id],
        panZoomManager: panZoomManager,
        controller: controller,
        config: MiniMapConfig()
    )
    .padding()
    .background(Color.gray.opacity(0.2))
}

#Preview("Empty MiniMap") {
    @StateObject var panZoomManager = PanZoomManager(minZoom: 0.1, maxZoom: 4.0)
    @StateObject var controller = MiniMapController()
    
    return MiniMapView(
        nodes: [PreviewNode](),
        selectedNodes: [],
        panZoomManager: panZoomManager,
        controller: controller,
        config: MiniMapConfig()
    )
    .padding()
    .background(Color.gray.opacity(0.2))
}
