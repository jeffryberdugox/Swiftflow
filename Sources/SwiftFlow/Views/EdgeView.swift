//
//  EdgeView.swift
//  SwiftFlow
//
//  Visual representation of an edge connection between nodes.
//

import SwiftUI

/// View that renders an edge between two nodes
public struct EdgeView<Edge: FlowEdge, Node: FlowNode>: View {
    let edge: Edge
    let nodes: [Node]
    var pathCalculator: any PathCalculator
    var strokeColor: Color
    var selectedColor: Color
    var lineWidth: CGFloat
    var isSelected: Bool
    var showArrow: Bool
    var arrowSize: CGFloat
    var sourceMarker: EdgeMarker?
    var targetMarker: EdgeMarker?
    var nodeOffsets: [UUID: CGSize]
    var nodeSizes: [UUID: CGSize]
    var nodePositionAdjustments: [UUID: CGPoint]
    var showLabel: Bool
    var transform: FlowTransform
    var edgeAccessoryBuilder: ((Edge, CGPoint, Bool) -> AnyView)?
    var edgeAccessoryConfig: EdgeAccessoryConfig
    var isDragging: Bool
    var onEdgeTap: ((UUID) -> Void)?
    var onHoverChange: ((UUID, Bool) -> Void)?
    
    /// Port position registry for getting real port positions (reactive)
    @EnvironmentObject var portPositionRegistry: PortPositionRegistry
    
    /// Edge hover manager for centralized hover state (reactive)
    @EnvironmentObject var edgeHoverManager: EdgeHoverManager
    
    public init(
        edge: Edge,
        nodes: [Node],
        pathCalculator: any PathCalculator = BezierPathCalculator(),
        strokeColor: Color = Color.gray.opacity(0.6),
        selectedColor: Color = Color.blue,
        lineWidth: CGFloat = 2,
        isSelected: Bool = false,
        showArrow: Bool = true,
        arrowSize: CGFloat = 8,
        sourceMarker: EdgeMarker? = nil,
        targetMarker: EdgeMarker? = nil,
        nodeOffsets: [UUID: CGSize] = [:],
        nodeSizes: [UUID: CGSize] = [:],
        nodePositionAdjustments: [UUID: CGPoint] = [:],
        showLabel: Bool = false,
        transform: FlowTransform = FlowTransform(),
        edgeAccessoryBuilder: ((Edge, CGPoint, Bool) -> AnyView)? = nil,
        edgeAccessoryConfig: EdgeAccessoryConfig = .default,
        isDragging: Bool = false,
        onEdgeTap: ((UUID) -> Void)? = nil,
        onHoverChange: ((UUID, Bool) -> Void)? = nil
    ) {
        self.edge = edge
        self.nodes = nodes
        self.pathCalculator = pathCalculator
        self.strokeColor = strokeColor
        self.selectedColor = selectedColor
        self.lineWidth = lineWidth
        self.isSelected = isSelected
        self.showArrow = showArrow
        self.arrowSize = arrowSize
        self.sourceMarker = sourceMarker
        self.targetMarker = targetMarker
        self.nodeOffsets = nodeOffsets
        self.nodeSizes = nodeSizes
        self.nodePositionAdjustments = nodePositionAdjustments
        self.showLabel = showLabel
        self.transform = transform
        self.edgeAccessoryBuilder = edgeAccessoryBuilder
        self.edgeAccessoryConfig = edgeAccessoryConfig
        self.isDragging = isDragging
        self.onEdgeTap = onEdgeTap
        self.onHoverChange = onHoverChange
    }
    
    public var body: some View {
        if let (sourcePoint, sourcePos, targetPoint, targetPos) = calculateEndpoints() {
            // Calculate path directly (caching will be added later if needed)
            let result = pathCalculator.calculatePath(
                from: sourcePoint,
                to: targetPoint,
                sourcePosition: sourcePos,
                targetPosition: targetPos
            )
            
            // Check if edge is disabled
            let isEdgeDisabled = (edge as? any DisableableFlowEdge)?.isDisabled ?? false
            let effectiveColor = isEdgeDisabled ? Color.gray.opacity(0.3) : (isSelected ? selectedColor : strokeColor)
            
            ZStack {
                // Main path (visual only)
                result.path
                    .stroke(
                        effectiveColor,
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            lineCap: .round,
                            lineJoin: .round,
                            dash: isEdgeDisabled ? [5, 5] : []
                        )
                    )
                    .opacity(isEdgeDisabled ? 0.5 : 1.0)
                
                // Markers
                // Source marker (at start of edge)
                if let sourceMarker = sourceMarker {
                    EdgeMarkerRendererView(
                        marker: sourceMarker,
                        position: sourcePoint,
                        angle: calculateArrowAngle(from: targetPoint, to: sourcePoint, targetPosition: sourcePos),
                        defaultColor: isSelected ? selectedColor : strokeColor
                    )
                }
                
                // Target marker (at end of edge) - legacy arrow or configured marker
                if showArrow || targetMarker != nil {
                    let marker = targetMarker ?? .targetArrow
                    EdgeMarkerRendererView(
                        marker: marker,
                        position: targetPoint,
                        angle: calculateArrowAngle(from: sourcePoint, to: targetPoint, targetPosition: targetPos),
                        defaultColor: isSelected ? selectedColor : strokeColor
                    )
                }
                
                // Tap detection area - uses the path shape for precise hit-testing
                if !isEdgeDisabled {
                    result.path
                        .stroke(
                            Color.clear,
                            style: StrokeStyle(
                                lineWidth: max(20, lineWidth + 10),
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .contentShape(
                            result.path.strokedPath(
                                StrokeStyle(lineWidth: max(20, lineWidth + 10), lineCap: .round, lineJoin: .round)
                            )
                        )
                        .onTapGesture {
                            onEdgeTap?(edge.id)
                        }
                        .onHover { hovering in
                            onHoverChange?(edge.id, hovering)
                        }
                }
                
                
                // Edge accessory - custom content or default label
                if !isEdgeDisabled {
                    if let builder = edgeAccessoryBuilder {
                        let shouldHide = edgeAccessoryConfig.hideOnDrag && isDragging
                        if !shouldHide {
                            let accessoryPosition = result.path.trimmedPath(
                                from: 0,
                                to: edgeAccessoryConfig.position
                            ).currentPoint ?? .zero
                            
                            let offsetPosition = CGPoint(
                                x: accessoryPosition.x + edgeAccessoryConfig.offset.x,
                                y: accessoryPosition.y + edgeAccessoryConfig.offset.y
                            )
                            
                            let isEdgeHovered = edgeHoverManager.isEdgeHovered(edge.id)
                            builder(edge, offsetPosition, isEdgeHovered)
                                .transition(edgeAccessoryConfig.animated ? .opacity : .identity)
                                // Keep hover active when mouse is over the accessory
                                .onHover { hovering in
                                    onHoverChange?(edge.id, hovering)
                                }
                        }
                    } else if showLabel, let labeledEdge = edge as? any LabeledFlowEdge, let label = labeledEdge.label {
                        let labelPoint = result.path.trimmedPath(from: 0, to: label.position).currentPoint ?? .zero
                        
                        Text(label.text)
                            .font(.system(size: label.fontSize))
                            .foregroundColor(label.textColor)
                            .padding(label.padding)
                            .background(
                                Group {
                                    if label.showBackground {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(label.backgroundColor)
                                            .shadow(color: Color.black.opacity(0.1), radius: 2)
                                    }
                                }
                            )
                            .position(labelPoint)
                            // Keep hover active when mouse is over the label
                            .onHover { hovering in
                                onHoverChange?(edge.id, hovering)
                            }
                    }
                }
            }
            // CRITICAL: Disable hit testing on the ZStack container itself
            // This allows each edge's path to receive its own hover events
            .allowsHitTesting(true)
            .contentShape(
                result.path.strokedPath(
                    StrokeStyle(lineWidth: max(20, lineWidth + 10), lineCap: .round, lineJoin: .round)
                )
            )
        }
    }
    
    /// Calculate the source and target points and port positions.
    /// All positions are in canvas coordinates.
    private func calculateEndpoints() -> (CGPoint, PortPosition, CGPoint, PortPosition)? {
        guard let sourceNode = nodes.first(where: { $0.id == edge.sourceNodeId }),
              let targetNode = nodes.first(where: { $0.id == edge.targetNodeId }) else {
            return nil
        }
        
        // Get drag offsets for nodes
        let sourceOffset = nodeOffsets[sourceNode.id] ?? .zero
        let targetOffset = nodeOffsets[targetNode.id] ?? .zero
        
        // Get current sizes (may differ during resize)
        let sourceSize = nodeSizes[sourceNode.id] ?? CGSize(width: sourceNode.width, height: sourceNode.height)
        let targetSize = nodeSizes[targetNode.id] ?? CGSize(width: targetNode.width, height: targetNode.height)
        
        // Get position adjustments for resizing nodes
        let sourceAdjustment = nodePositionAdjustments[sourceNode.id] ?? .zero
        let targetAdjustment = nodePositionAdjustments[targetNode.id] ?? .zero
        
        // Calculate current node positions (top-left in canvas coordinates)
        // node.position + drag offset + resize adjustment
        let currentSourceNodeTopLeft = CGPoint(
            x: sourceNode.position.x + sourceOffset.width + sourceAdjustment.x,
            y: sourceNode.position.y + sourceOffset.height + sourceAdjustment.y
        )
        let currentTargetNodeTopLeft = CGPoint(
            x: targetNode.position.x + targetOffset.width + targetAdjustment.x,
            y: targetNode.position.y + targetOffset.height + targetAdjustment.y
        )
        
        // Find the ports
        let sourcePort = sourceNode.outputPorts.first { $0.id == edge.sourcePortId }
        let targetPort = targetNode.inputPorts.first { $0.id == edge.targetPortId }
        
        // Default port positions if ports not found
        let sourcePos = sourcePort?.position ?? .right
        let targetPos = targetPort?.position ?? .left
        
        // Calculate actual port positions in canvas coordinates
        var sourcePoint: CGPoint
        var targetPoint: CGPoint

        // Calculate source point using registry (preferred) or layout fallback
        if let nodeLocalOffset = portPositionRegistry.nodeLocalOffset(for: edge.sourcePortId) {
            // Port is registered in the registry
            var finalOffset = nodeLocalOffset
            
            // During resize, recalculate position from layout if available
            if nodeSizes[sourceNode.id] != nil, let layout = portPositionRegistry.layout(for: edge.sourcePortId) {
                // Preset-based layouts adapt to new size automatically
                finalOffset = layout.position(nodeSize: sourceSize)
            }
            
            // Convert from node-local to canvas coordinates
            sourcePoint = CGPoint(
                x: currentSourceNodeTopLeft.x + finalOffset.x,
                y: currentSourceNodeTopLeft.y + finalOffset.y
            )
        } else if let port = sourcePort {
            // Fallback: calculate from port's layout
            let nodeLocalPos = port.layout.position(nodeSize: sourceSize)
            sourcePoint = CGPoint(
                x: currentSourceNodeTopLeft.x + nodeLocalPos.x,
                y: currentSourceNodeTopLeft.y + nodeLocalPos.y
            )
        } else {
            // Ultimate fallback: right-center of node
            sourcePoint = CGPoint(
                x: currentSourceNodeTopLeft.x + sourceSize.width,
                y: currentSourceNodeTopLeft.y + sourceSize.height / 2
            )
        }

        // Calculate target point using registry (preferred) or layout fallback
        if let nodeLocalOffset = portPositionRegistry.nodeLocalOffset(for: edge.targetPortId) {
            // Port is registered in the registry
            var finalOffset = nodeLocalOffset
            
            // During resize, recalculate position from layout if available
            if nodeSizes[targetNode.id] != nil, let layout = portPositionRegistry.layout(for: edge.targetPortId) {
                // Preset-based layouts adapt to new size automatically
                finalOffset = layout.position(nodeSize: targetSize)
            }
            
            // Convert from node-local to canvas coordinates
            targetPoint = CGPoint(
                x: currentTargetNodeTopLeft.x + finalOffset.x,
                y: currentTargetNodeTopLeft.y + finalOffset.y
            )
        } else if let port = targetPort {
            // Fallback: calculate from port's layout
            let nodeLocalPos = port.layout.position(nodeSize: targetSize)
            targetPoint = CGPoint(
                x: currentTargetNodeTopLeft.x + nodeLocalPos.x,
                y: currentTargetNodeTopLeft.y + nodeLocalPos.y
            )
        } else {
            // Ultimate fallback: left-center of node
            targetPoint = CGPoint(
                x: currentTargetNodeTopLeft.x,
                y: currentTargetNodeTopLeft.y + targetSize.height / 2
            )
        }

        return (sourcePoint, sourcePos, targetPoint, targetPos)
    }
    
    /// Calculate the angle for the arrow head
    private func calculateArrowAngle(
        from source: CGPoint,
        to target: CGPoint,
        targetPosition: PortPosition
    ) -> Double {
        // Use the target port position to determine arrow direction
        switch targetPosition {
        case .left:
            return .pi // Pointing left
        case .right:
            return 0 // Pointing right
        case .top:
            return -.pi / 2 // Pointing up
        case .bottom:
            return .pi / 2 // Pointing down
        }
    }
}

// MARK: - Arrow Head Shape

/// Arrow head shape for edge endpoints
public struct ArrowHead: Shape {
    let at: CGPoint
    let angle: Double
    let size: CGFloat
    
    public init(at: CGPoint, angle: Double, size: CGFloat = 8) {
        self.at = at
        self.angle = angle
        self.size = size
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Arrow points
        let tip = at
        let left = CGPoint(
            x: at.x - size * cos(angle - .pi / 6),
            y: at.y - size * sin(angle - .pi / 6)
        )
        let right = CGPoint(
            x: at.x - size * cos(angle + .pi / 6),
            y: at.y - size * sin(angle + .pi / 6)
        )
        
        path.move(to: tip)
        path.addLine(to: left)
        path.addLine(to: right)
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Preview

#Preview("Basic Edge") {
    let nodes = [
        PreviewNode(position: CGPoint(x: 50, y: 150)),
        PreviewNode(position: CGPoint(x: 300, y: 150))
    ]
    let edge = PreviewEdge(
        sourceNodeId: nodes[0].id,
        targetNodeId: nodes[1].id,
        sourcePortId: nodes[0].outputPorts.first!.id,
        targetPortId: nodes[1].inputPorts.first!.id
    )
    
    return EdgeView(
        edge: edge,
        nodes: nodes
    )
    .environmentObject(PortPositionRegistry())
    .environmentObject(EdgeHoverManager())
    .frame(width: 400, height: 300)
    .background(Color.gray.opacity(0.1))
}

#Preview("Selected Edge") {
    let nodes = [
        PreviewNode(position: CGPoint(x: 50, y: 150)),
        PreviewNode(position: CGPoint(x: 300, y: 150))
    ]
    let edge = PreviewEdge(
        sourceNodeId: nodes[0].id,
        targetNodeId: nodes[1].id,
        sourcePortId: nodes[0].outputPorts.first!.id,
        targetPortId: nodes[1].inputPorts.first!.id
    )
    
    return EdgeView(
        edge: edge,
        nodes: nodes,
        isSelected: true
    )
    .environmentObject(PortPositionRegistry())
    .environmentObject(EdgeHoverManager())
    .frame(width: 400, height: 300)
    .background(Color.gray.opacity(0.1))
}
