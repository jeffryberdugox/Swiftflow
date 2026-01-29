//
//  ComponentProps.swift
//  SwiftFlow
//
//  Public props structs for canvas components.
//

import Foundation
import SwiftUI

// MARK: - Background Props

/// Props for the canvas background/grid component
public struct BackgroundProps: Equatable, Sendable, Hashable {
    /// Whether the background is visible
    public var visible: Bool
    
    /// Grid pattern type
    public var pattern: GridPattern
    
    /// Grid size (spacing between lines/dots)
    public var size: CGFloat
    
    /// Grid color
    public var color: RGBAColor
    
    /// Grid line width (for line patterns)
    public var lineWidth: CGFloat
    
    /// Gap between pattern repetitions
    public var gap: CGFloat
    
    /// Background color of the canvas
    public var backgroundColor: RGBAColor
    
    public init(
        visible: Bool = true,
        pattern: GridPattern = .lines,
        size: CGFloat = 20,
        color: RGBAColor = RGBAColor.gray.withAlpha(0.2),
        lineWidth: CGFloat = 1,
        gap: CGFloat = 0,
        backgroundColor: RGBAColor = RGBAColor.white
    ) {
        self.visible = visible
        self.pattern = pattern
        self.size = size
        self.color = color
        self.lineWidth = lineWidth
        self.gap = gap
        self.backgroundColor = backgroundColor
    }
    
    /// Convert to GridConfig
    public func toGridConfig() -> GridConfig {
        return GridConfig(
            visible: visible,
            size: size,
            snap: false,
            pattern: pattern,
            style: GridStyle(
                lineColor: color,
                lineWidth: lineWidth,
                backgroundColor: backgroundColor
            )
        )
    }
    
    // MARK: - Presets
    
    public static let `default` = BackgroundProps()
    public static let dots = BackgroundProps(pattern: .dots)
    public static let lines = BackgroundProps(pattern: .lines)
    public static let minimalist = BackgroundProps(pattern: .minimalist)
    public static let hidden = BackgroundProps(visible: false)
}

// MARK: - MiniMap Props

/// Props for the minimap component
public struct MiniMapProps: Equatable, Sendable {
    /// Position of the minimap
    public var position: PanelPosition
    
    /// Width of the minimap
    public var width: CGFloat
    
    /// Height of the minimap
    public var height: CGFloat
    
    /// Panel background color
    public var backgroundColor: RGBAColor
    
    /// Panel border color
    public var borderColor: RGBAColor
    
    /// Panel border width
    public var borderWidth: CGFloat
    
    /// Panel corner radius
    public var cornerRadius: CGFloat
    
    /// Node color in minimap
    public var nodeColor: RGBAColor
    
    /// Node stroke color
    public var nodeStrokeColor: RGBAColor?
    
    /// Node stroke width
    public var nodeStrokeWidth: CGFloat
    
    /// Node border radius
    public var nodeBorderRadius: CGFloat
    
    /// Selected node color
    public var selectedNodeColor: RGBAColor?
    
    /// Show selection in minimap
    public var showSelection: Bool
    
    /// Viewport mask color
    public var maskColor: RGBAColor
    
    /// Viewport mask stroke color
    public var maskStrokeColor: RGBAColor
    
    /// Viewport mask stroke width
    public var maskStrokeWidth: CGFloat
    
    /// Whether minimap is pannable
    public var pannable: Bool
    
    /// Whether minimap is zoomable
    public var zoomable: Bool
    
    /// Whether clicking moves viewport
    public var clickToMove: Bool
    
    public init(
        position: PanelPosition = .bottomRight,
        width: CGFloat = 200,
        height: CGFloat = 150,
        backgroundColor: RGBAColor = RGBAColor.gray.withAlpha(0.15),
        borderColor: RGBAColor = RGBAColor.gray.withAlpha(0.4),
        borderWidth: CGFloat = 1,
        cornerRadius: CGFloat = 8,
        nodeColor: RGBAColor = RGBAColor.blue,
        nodeStrokeColor: RGBAColor? = nil,
        nodeStrokeWidth: CGFloat = 1,
        nodeBorderRadius: CGFloat = 3,
        selectedNodeColor: RGBAColor? = nil,
        showSelection: Bool = true,
        maskColor: RGBAColor = RGBAColor.blue.withAlpha(0.15),
        maskStrokeColor: RGBAColor = RGBAColor.blue,
        maskStrokeWidth: CGFloat = 2,
        pannable: Bool = true,
        zoomable: Bool = true,
        clickToMove: Bool = true
    ) {
        self.position = position
        self.width = width
        self.height = height
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.nodeColor = nodeColor
        self.nodeStrokeColor = nodeStrokeColor
        self.nodeStrokeWidth = nodeStrokeWidth
        self.nodeBorderRadius = nodeBorderRadius
        self.selectedNodeColor = selectedNodeColor
        self.showSelection = showSelection
        self.maskColor = maskColor
        self.maskStrokeColor = maskStrokeColor
        self.maskStrokeWidth = maskStrokeWidth
        self.pannable = pannable
        self.zoomable = zoomable
        self.clickToMove = clickToMove
    }
    
    /// Convert to MiniMapConfig
    public func toMiniMapConfig() -> MiniMapConfig {
        return MiniMapConfig(
            position: position,
            width: width,
            height: height,
            backgroundColor: Color(backgroundColor),
            borderColor: Color(borderColor),
            borderWidth: borderWidth,
            cornerRadius: cornerRadius,
            nodeColor: Color(nodeColor),
            nodeColorProvider: nil,
            nodeStrokeColor: nodeStrokeColor.map { Color($0) } ?? Color.gray.opacity(0.5),
            nodeStrokeWidth: nodeStrokeWidth,
            nodeBorderRadius: nodeBorderRadius,
            showNodeLabels: false,
            nodeLabelProvider: nil,
            minimumNodeSizeForLabel: 25,
            selectedNodeColor: selectedNodeColor.map { Color($0) } ?? Color.blue,
            showSelectionInMiniMap: showSelection,
            maskColor: Color(maskColor),
            maskStrokeColor: Color(maskStrokeColor),
            maskStrokeWidth: maskStrokeWidth,
            maskCornerRadius: 4,
            maskStrokeDashPattern: nil,
            pannable: pannable,
            zoomable: zoomable,
            clickToMove: clickToMove,
            contentPadding: 20
        )
    }
    
    // MARK: - Presets
    
    public static let `default` = MiniMapProps()
    public static let compact = MiniMapProps(width: 150, height: 100)
    public static let large = MiniMapProps(width: 300, height: 200)
}

// MARK: - Controls Props

/// Props for the controls component (zoom/fit buttons)
public struct ControlsProps: Equatable, Sendable, Hashable {
    /// Position of the controls
    public var position: PanelPosition
    
    /// Show zoom in button
    public var showZoomIn: Bool
    
    /// Show zoom out button
    public var showZoomOut: Bool
    
    /// Show fit view button
    public var showFitView: Bool
    
    /// Show interactive toggle button
    public var showInteractive: Bool
    
    /// Button size
    public var buttonSize: CGFloat
    
    /// Button spacing
    public var spacing: CGFloat
    
    /// Background color
    public var backgroundColor: RGBAColor
    
    /// Border color
    public var borderColor: RGBAColor
    
    /// Border width
    public var borderWidth: CGFloat
    
    /// Corner radius
    public var cornerRadius: CGFloat
    
    public init(
        position: PanelPosition = .topLeft,
        showZoomIn: Bool = true,
        showZoomOut: Bool = true,
        showFitView: Bool = true,
        showInteractive: Bool = false,
        buttonSize: CGFloat = 32,
        spacing: CGFloat = 8,
        backgroundColor: RGBAColor = RGBAColor.white,
        borderColor: RGBAColor = RGBAColor.gray.withAlpha(0.3),
        borderWidth: CGFloat = 1,
        cornerRadius: CGFloat = 6
    ) {
        self.position = position
        self.showZoomIn = showZoomIn
        self.showZoomOut = showZoomOut
        self.showFitView = showFitView
        self.showInteractive = showInteractive
        self.buttonSize = buttonSize
        self.spacing = spacing
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
    }
    
    // MARK: - Presets
    
    public static let `default` = ControlsProps()
    public static let minimal = ControlsProps(showInteractive: false)
    public static let full = ControlsProps(showInteractive: true)
}

// MARK: - Panel Props

/// Generic props for positioned panels
public struct PanelProps: Equatable, Sendable, Hashable {
    /// Position of the panel
    public var position: PanelPosition
    
    /// Padding from screen edges
    public var padding: CGFloat
    
    /// Background color
    public var backgroundColor: RGBAColor?
    
    /// Border color
    public var borderColor: RGBAColor?
    
    /// Border width
    public var borderWidth: CGFloat
    
    /// Corner radius
    public var cornerRadius: CGFloat
    
    /// Shadow enabled
    public var shadow: Bool
    
    public init(
        position: PanelPosition = .topLeft,
        padding: CGFloat = 16,
        backgroundColor: RGBAColor? = nil,
        borderColor: RGBAColor? = nil,
        borderWidth: CGFloat = 0,
        cornerRadius: CGFloat = 8,
        shadow: Bool = false
    ) {
        self.position = position
        self.padding = padding
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.shadow = shadow
    }
    
    // MARK: - Presets
    
    public static let `default` = PanelProps()
    public static let card = PanelProps(
        backgroundColor: RGBAColor.white,
        borderColor: RGBAColor.gray.withAlpha(0.2),
        borderWidth: 1,
        shadow: true
    )
}

// MARK: - Node Props

/// Props for individual nodes (configuration wrapper)
public struct NodeProps: Equatable, Sendable {
    /// Node type identifier
    public var type: String?
    
    /// Whether node is draggable
    public var draggable: Bool
    
    /// Whether node is selectable
    public var selectable: Bool
    
    /// Whether node is connectable
    public var connectable: Bool
    
    /// Whether node is resizable
    public var resizable: Bool
    
    /// Z-index for layering
    public var zIndex: Double
    
    /// Parent node ID (for nested nodes)
    public var parentId: UUID?
    
    public init(
        type: String? = nil,
        draggable: Bool = true,
        selectable: Bool = true,
        connectable: Bool = true,
        resizable: Bool = false,
        zIndex: Double = 0,
        parentId: UUID? = nil
    ) {
        self.type = type
        self.draggable = draggable
        self.selectable = selectable
        self.connectable = connectable
        self.resizable = resizable
        self.zIndex = zIndex
        self.parentId = parentId
    }
    
    // MARK: - Presets
    
    public static let `default` = NodeProps()
    public static let locked = NodeProps(draggable: false, resizable: false)
    public static let input = NodeProps(type: "input")
    public static let output = NodeProps(type: "output")
}

// MARK: - Edge Props

/// Props for individual edges (configuration wrapper)
public struct EdgeProps: Equatable, Sendable {
    /// Edge type identifier
    public var type: String?
    
    /// Whether edge is animated
    public var animated: Bool
    
    /// Whether edge is selectable
    public var selectable: Bool
    
    /// Whether edge can be updated (reconnected)
    public var updatable: Bool
    
    /// Marker at source
    public var markerStart: EdgeMarker?
    
    /// Marker at target
    public var markerEnd: EdgeMarker?
    
    /// Z-index for layering
    public var zIndex: Double
    
    public init(
        type: String? = nil,
        animated: Bool = false,
        selectable: Bool = true,
        updatable: Bool = false,
        markerStart: EdgeMarker? = nil,
        markerEnd: EdgeMarker? = .targetArrow,
        zIndex: Double = 0
    ) {
        self.type = type
        self.animated = animated
        self.selectable = selectable
        self.updatable = updatable
        self.markerStart = markerStart
        self.markerEnd = markerEnd
        self.zIndex = zIndex
    }
    
    // MARK: - Presets
    
    public static let `default` = EdgeProps()
    public static let animated = EdgeProps(animated: true)
    public static let readonly = EdgeProps(selectable: false, updatable: false)
}
