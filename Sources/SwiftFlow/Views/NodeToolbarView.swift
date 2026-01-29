//
//  NodeToolbarView.swift
//  SwiftFlow
//
//  Contextual toolbar for nodes.
//

import SwiftUI

/// Position of the toolbar relative to the node
public enum ToolbarPosition: String, CaseIterable, Sendable {
    /// Toolbar appears above the node
    case top
    /// Toolbar appears below the node
    case bottom
    /// Toolbar appears to the left of the node
    case left
    /// Toolbar appears to the right of the node
    case right
    /// Toolbar uses custom offset from node center
    case custom
}

/// Alignment of the toolbar
public enum ToolbarAlign: String, CaseIterable, Sendable {
    case start
    case center
    case end
}

/// Configuration for node toolbar
public struct NodeToolbarConfig: Equatable {
    /// Position of the toolbar relative to the node
    public var position: ToolbarPosition
    
    /// Alignment within the position (start, center, end)
    public var align: ToolbarAlign
    
    /// Distance from the node edge (for predefined positions)
    public var offset: CGFloat
    
    /// Custom offset from node center (used when position is .custom)
    /// X: positive = right, negative = left
    /// Y: positive = down, negative = up
    public var customOffset: CGPoint
    
    /// Whether the toolbar is visible
    public var isVisible: Bool
    
    /// Whether to hide toolbar during node drag
    public var hideOnDrag: Bool
    
    /// Animation for showing/hiding
    public var animated: Bool
    
    public init(
        position: ToolbarPosition = .top,
        align: ToolbarAlign = .center,
        offset: CGFloat = 10,
        customOffset: CGPoint = .zero,
        isVisible: Bool = true,
        hideOnDrag: Bool = true,
        animated: Bool = true
    ) {
        self.position = position
        self.align = align
        self.offset = offset
        self.customOffset = customOffset
        self.isVisible = isVisible
        self.hideOnDrag = hideOnDrag
        self.animated = animated
    }
    
    public static let `default` = NodeToolbarConfig()
    
    /// Create a config with custom positioning from node center
    public static func custom(offsetX: CGFloat, offsetY: CGFloat) -> NodeToolbarConfig {
        NodeToolbarConfig(
            position: .custom,
            customOffset: CGPoint(x: offsetX, y: offsetY)
        )
    }
    
    /// Create a config at top position
    public static func top(offset: CGFloat = 10, align: ToolbarAlign = .center) -> NodeToolbarConfig {
        NodeToolbarConfig(position: .top, align: align, offset: offset)
    }
    
    /// Create a config at bottom position
    public static func bottom(offset: CGFloat = 10, align: ToolbarAlign = .center) -> NodeToolbarConfig {
        NodeToolbarConfig(position: .bottom, align: align, offset: offset)
    }
    
    /// Create a config at left position
    public static func left(offset: CGFloat = 10, align: ToolbarAlign = .center) -> NodeToolbarConfig {
        NodeToolbarConfig(position: .left, align: align, offset: offset)
    }
    
    /// Create a config at right position
    public static func right(offset: CGFloat = 10, align: ToolbarAlign = .center) -> NodeToolbarConfig {
        NodeToolbarConfig(position: .right, align: align, offset: offset)
    }
}

/// Contextual toolbar for nodes
public struct NodeToolbarView<Content: View>: View {
    let node: any FlowNode
    let config: NodeToolbarConfig
    let content: Content
    
    /// Screen position of the node (calculated externally and passed in)
    let nodeScreenPosition: CGPoint
    
    /// Screen size of the node (scaled)
    let nodeScreenSize: CGSize
    
    public init(
        node: any FlowNode,
        nodeScreenPosition: CGPoint,
        nodeScreenSize: CGSize,
        config: NodeToolbarConfig = .default,
        @ViewBuilder content: () -> Content
    ) {
        self.node = node
        self.nodeScreenPosition = nodeScreenPosition
        self.nodeScreenSize = nodeScreenSize
        self.config = config
        self.content = content()
    }
    
    /// Convenience initializer that calculates screen position from transform
    public init(
        node: any FlowNode,
        panZoomManager: PanZoomManager,
        config: NodeToolbarConfig = .default,
        @ViewBuilder content: () -> Content
    ) {
        let transform = panZoomManager.transform
        self.node = node
        self.nodeScreenPosition = transform.canvasToScreen(node.position)
        self.nodeScreenSize = CGSize(
            width: node.width * transform.scale,
            height: node.height * transform.scale
        )
        self.config = config
        self.content = content()
    }
    
    public var body: some View {
        let position = calculatePosition()
        
        if config.isVisible {
            content
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .glassBackground(in: Capsule())
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                .position(position)
        }
    }
    
    // MARK: - Position Calculation
    
    private func calculatePosition() -> CGPoint {
        // nodeScreenPosition is already the CENTER of the node in screen coordinates
        let nodeCenter = nodeScreenPosition
        
        // nodeScreenSize is already scaled
        let nodeWidth = nodeScreenSize.width
        let nodeHeight = nodeScreenSize.height
        
        // Calculate node edges from center
        let nodeTop = nodeCenter.y - nodeHeight / 2
        let nodeBottom = nodeCenter.y + nodeHeight / 2
        let nodeLeft = nodeCenter.x - nodeWidth / 2
        let nodeRight = nodeCenter.x + nodeWidth / 2
        
        // Handle custom positioning
        if config.position == .custom {
            return CGPoint(
                x: nodeCenter.x + config.customOffset.x,
                y: nodeCenter.y + config.customOffset.y
            )
        }
        
        // Base position based on toolbar position
        var x: CGFloat
        var y: CGFloat
        
        switch config.position {
        case .top:
            x = nodeCenter.x
            y = nodeTop - config.offset
            
        case .bottom:
            x = nodeCenter.x
            y = nodeBottom + config.offset
            
        case .left:
            x = nodeLeft - config.offset
            y = nodeCenter.y
            
        case .right:
            x = nodeRight + config.offset
            y = nodeCenter.y
            
        case .custom:
            // Already handled above
            x = nodeCenter.x
            y = nodeCenter.y
        }
        
        // Apply alignment for non-custom positions
        switch config.position {
        case .top, .bottom:
            switch config.align {
            case .start:
                x = nodeLeft
            case .center:
                x = nodeCenter.x
            case .end:
                x = nodeRight
            }
            
        case .left, .right:
            switch config.align {
            case .start:
                y = nodeTop
            case .center:
                y = nodeCenter.y
            case .end:
                y = nodeBottom
            }
            
        case .custom:
            break // No alignment adjustments for custom
        }
        
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Convenience Extension

public extension View {
    /// Add a node toolbar to this view
    func nodeToolbar<Content: View>(
        for node: any FlowNode,
        panZoomManager: PanZoomManager,
        config: NodeToolbarConfig = .default,
        @ViewBuilder content: () -> Content
    ) -> some View {
        self.overlay(
            NodeToolbarView(
                node: node,
                panZoomManager: panZoomManager,
                config: config,
                content: content
            )
        )
    }
}

// MARK: - Preview

#Preview {
    @StateObject var panZoomManager = PanZoomManager(
        minZoom: 0.1,
        maxZoom: 4.0
    )
    
    let node = PreviewNode(
        position: CGPoint(x: 200, y: 200),
        width: 200,
        height: 100
    )
    
    ZStack {
        Color.gray.opacity(0.2)
        
        // Node representation
        Rectangle()
            .fill(Color.white)
            .frame(width: 200, height: 100)
            .position(CGPoint(x: 300, y: 250))
            .overlay(
                Text("Node")
                    .position(CGPoint(x: 300, y: 250))
            )
        
        // Toolbar
        NodeToolbarView(
            node: node,
            panZoomManager: panZoomManager,
            config: NodeToolbarConfig(position: .top)
        ) {
            HStack(spacing: 8) {
                Button(action: {}) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                
                Button(action: {}) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                
                Button(action: {}) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }
    .frame(width: 600, height: 400)
}
