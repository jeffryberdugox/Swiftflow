//
//  InteractivePortView.swift
//  SwiftFlow
//
//  Interactive port view with drag gesture for creating connections.
//

import SwiftUI

/// Interactive port view that allows creating connections via drag gesture
public struct InteractivePortView: View {
    // MARK: - Properties
    
    /// The port to display
    let port: any FlowPort
    
    /// The node this port belongs to
    let node: any FlowNode
    
    /// Whether this is an input port (true) or output port (false)
    let isInput: Bool
    
    /// Connection manager from environment
    @EnvironmentObject var connectionManager: ConnectionManager
    
    /// Port position registry from environment
    @EnvironmentObject var portPositionRegistry: PortPositionRegistry
    
    /// All nodes from environment
    @Environment(\.flowNodes) var allNodes: [AnyFlowNode]
    
    // MARK: - Styling
    
    /// Size of the port circle
    public var size: CGFloat = 12
    
    /// Default color of the port
    public var color: Color
    
    /// Color when hovering over a valid target
    public var hoverColor: Color = .green
    
    /// Color when dragging
    public var draggingColor: Color = .blue
    
    // MARK: - State
    
    @State private var isDragging: Bool = false
    @State private var isHovered: Bool = false
    
    // MARK: - Initialization
    
    public init(
        port: any FlowPort,
        node: any FlowNode,
        isInput: Bool,
        size: CGFloat = 12,
        color: Color? = nil
    ) {
        self.port = port
        self.node = node
        self.isInput = isInput
        self.size = size
        self.color = color ?? (isInput ? .blue : .green)
    }
    
    // MARK: - Body
    
    public var body: some View {
        Circle()
            .fill(currentColor)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
            .shadow(color: currentColor.opacity(0.4), radius: isDragging ? 4 : 2, x: 0, y: 1)
            .scaleEffect(isDragging ? 1.3 : (isHovered ? 1.15 : 1.0))
            .animation(.easeInOut(duration: 0.15), value: isDragging)
            .animation(.easeInOut(duration: 0.1), value: isHovered)
            .contentShape(Circle().scale(2.0)) // Larger hit area for easier interaction
            .gesture(connectionDragGesture)
            .onHover { hovering in
                isHovered = hovering
            }
            .background(
                GeometryReader { geometry in
                    let nodeFrame = geometry.frame(in: .named("node-\(node.id)"))
                    let nodeLocalCenter = CGPoint(x: nodeFrame.midX, y: nodeFrame.midY)
                    Color.clear
                        .preference(
                            key: PortPositionPreferenceKey.self,
                            value: nodeLocalCenter
                        )
                }
            )
            .onPreferenceChange(PortPositionPreferenceKey.self) { nodeLocalCenter in
                guard let nodeLocalCenter else { return }
                let existing = portPositionRegistry.nodeLocalOffset(for: port.id)
                let shouldUpdate: Bool
                if let existing {
                    let dx = abs(existing.x - nodeLocalCenter.x)
                    let dy = abs(existing.y - nodeLocalCenter.y)
                    shouldUpdate = dx > 0.5 || dy > 0.5
                } else {
                    shouldUpdate = true
                }
                
                guard shouldUpdate else { return }

                portPositionRegistry.register(
                    portId: port.id,
                    nodeId: node.id,
                    nodeLocalOffset: nodeLocalCenter,
                    layout: port.layout,
                    isInput: isInput,
                    portPosition: port.position
                )
            }
            .frame(width: size, height: size)
            .onDisappear {
                // Unregister when the port view is removed
                portPositionRegistry.unregister(portId: port.id)
            }
    }
    
    // MARK: - Computed Properties
    
    private var currentColor: Color {
        if isDragging {
            return draggingColor
        } else if isHovered {
            return hoverColor
        }
        return color
    }
    
    // MARK: - Drag Gesture
    
    private var connectionDragGesture: some Gesture {
        DragGesture(minimumDistance: 3, coordinateSpace: .named("canvas"))
            .onChanged { value in
                if !isDragging {
                    // Start the connection using the port's current canvas position
                    isDragging = true
                    
                    let startPosition = portPositionRegistry.canvasPosition(
                        for: port.id,
                        nodePosition: node.position
                    ) ?? value.startLocation

                    connectionManager.startConnection(
                        from: node.id,
                        portId: port.id,
                        at: startPosition,
                        portPosition: port.position,
                        isFromInput: isInput
                    )
                }
                
                // Build node positions dictionary from environment
                let nodePositions = Dictionary(
                    uniqueKeysWithValues: allNodes.map { ($0.id, $0.position) }
                )
                
                // Find nearby port using the registry with current node positions
                let lookingForInput = !isInput // If dragging from output, look for input
                let nearbyPort = portPositionRegistry.findClosestPort(
                    to: value.location,
                    radius: connectionManager.connectionRadius,
                    nodePositions: nodePositions,
                    excludeNodeId: node.id,
                    lookingForInput: lookingForInput
                )
                
                // Update connection with current position and nearby port
                connectionManager.updateConnection(
                    to: value.location,
                    nearbyPort: nearbyPort
                )
            }
            .onEnded { _ in
                isDragging = false
                connectionManager.endConnection()
            }
    }
}

// MARK: - Port Position Preference Key

/// Preference key for capturing port positions
struct PortPositionPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint? = nil
    
    static func reduce(value: inout CGPoint?, nextValue: () -> CGPoint?) {
        value = nextValue() ?? value
    }
}

// MARK: - CGRect Extension

extension CGRect {
    /// The center point of the rectangle
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

// MARK: - Port Overlay Modifier

/// View modifier that adds interactive ports to a node view
public struct InteractivePortsModifier: ViewModifier {
    let node: any FlowNode
    var inputPortColor: Color = .blue
    var outputPortColor: Color = .green
    var portSize: CGFloat = 12
    
    public func body(content: Content) -> some View {
        content
            .overlay(portsOverlay)
    }
    
    @ViewBuilder
    private var portsOverlay: some View {
        ZStack {
            // Input ports (left side)
            VStack(spacing: 12) {
                ForEach(Array(node.inputPorts.enumerated()), id: \.element.id) { _, port in
                    InteractivePortView(
                        port: port,
                        node: node,
                        isInput: true,
                        size: portSize,
                        color: inputPortColor
                    )
                    .offset(x: -portSize / 2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            
            // Output ports (right side)
            VStack(spacing: 12) {
                ForEach(Array(node.outputPorts.enumerated()), id: \.element.id) { _, port in
                    InteractivePortView(
                        port: port,
                        node: node,
                        isInput: false,
                        size: portSize,
                        color: outputPortColor
                    )
                    .offset(x: portSize / 2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Add interactive ports to a node view
    func interactivePorts(
        for node: any FlowNode,
        inputColor: Color = .blue,
        outputColor: Color = .green,
        portSize: CGFloat = 12
    ) -> some View {
        self.modifier(
            InteractivePortsModifier(
                node: node,
                inputPortColor: inputColor,
                outputPortColor: outputColor,
                portSize: portSize
            )
        )
    }
}

// MARK: - Preview

#Preview("Output Port") {
    let node = PreviewNode()
    let port = PreviewPort(position: .right)
    
    return ZStack {
        Color.gray.opacity(0.1)
        
        InteractivePortView(
            port: port,
            node: node,
            isInput: false,
            size: 12,
            color: .green
        )
    }
    .environmentObject(ConnectionManager())
    .environmentObject(PortPositionRegistry())
    .environment(\.flowNodes, [AnyFlowNode(node)])
    .coordinateSpace(name: "node-\(node.id)")
    .coordinateSpace(name: "canvas")
    .frame(width: 200, height: 200)
}

#Preview("Input Port") {
    let node = PreviewNode()
    let port = PreviewPort(position: .left)
    
    return ZStack {
        Color.gray.opacity(0.1)
        
        InteractivePortView(
            port: port,
            node: node,
            isInput: true,
            size: 12,
            color: .blue
        )
    }
    .environmentObject(ConnectionManager())
    .environmentObject(PortPositionRegistry())
    .environment(\.flowNodes, [AnyFlowNode(node)])
    .coordinateSpace(name: "node-\(node.id)")
    .coordinateSpace(name: "canvas")
    .frame(width: 200, height: 200)
}
