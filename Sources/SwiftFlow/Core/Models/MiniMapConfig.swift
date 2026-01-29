//
//  MiniMapConfig.swift
//  SwiftFlow
//
//  Configuration for the MiniMap component.
//

import SwiftUI

/// Configuration for the MiniMap component appearance and behavior
public struct MiniMapConfig: Sendable, Equatable {
    // MARK: - Layout
    
    /// Position of the minimap panel on the canvas
    public var position: PanelPosition
    
    /// Width of the minimap in points
    public var width: CGFloat
    
    /// Height of the minimap in points
    public var height: CGFloat
    
    /// Padding from the edge of the panel
    public var padding: CGFloat
    
    // MARK: - Panel Appearance
    
    /// Background color of the minimap panel
    public var backgroundColor: Color
    
    /// Border color of the minimap panel
    public var borderColor: Color
    
    /// Width of the minimap panel border
    public var borderWidth: CGFloat
    
    /// Corner radius of the minimap panel
    public var cornerRadius: CGFloat
    
    // MARK: - Node Appearance
    
    /// Default fill color for nodes in the minimap
    public var nodeColor: Color
    
    /// Custom color provider for individual nodes (by nodeId)
    public var nodeColorProvider: (@Sendable (UUID) -> Color)?
    
    /// Stroke color for node borders
    public var nodeStrokeColor: Color
    
    /// Width of node borders
    public var nodeStrokeWidth: CGFloat
    
    /// Corner radius of nodes in the minimap
    public var nodeBorderRadius: CGFloat
    
    // MARK: - Node Labels
    
    /// Whether to show labels on nodes in the minimap
    public var showNodeLabels: Bool
    
    /// Provider for node label text (by nodeId)
    public var nodeLabelProvider: (@Sendable (UUID) -> String?)?
    
    /// Font for node labels
    public var nodeLabelFont: Font
    
    /// Color for node labels
    public var nodeLabelColor: Color
    
    /// Minimum node size (in minimap space) to show a label
    public var minimumNodeSizeForLabel: CGFloat
    
    // MARK: - Selection Highlighting
    
    /// Color for selected nodes in the minimap
    public var selectedNodeColor: Color
    
    /// Whether to highlight selected nodes in the minimap
    public var showSelectionInMiniMap: Bool
    
    // MARK: - Viewport Indicator
    
    /// Fill color for the viewport indicator (visible area rectangle)
    public var maskColor: Color
    
    /// Stroke color for the viewport indicator border
    public var maskStrokeColor: Color
    
    /// Width of the viewport indicator border
    public var maskStrokeWidth: CGFloat
    
    /// Corner radius of the viewport indicator
    public var maskCornerRadius: CGFloat
    
    /// Dash pattern for the viewport indicator border (e.g., [5, 3] for dashed line)
    public var maskStrokeDashPattern: [CGFloat]?
    
    // MARK: - Interactions
    
    /// Whether the viewport indicator can be dragged to pan the canvas
    public var pannable: Bool
    
    /// Whether scrolling/pinching on the minimap zooms the canvas
    public var zoomable: Bool
    
    /// Whether clicking on the minimap centers the viewport at that position
    public var clickToMove: Bool
    
    /// Sensitivity for zoom gesture (affects how much each scroll step zooms)
    public var zoomSensitivity: CGFloat
    
    // MARK: - Performance
    
    /// Padding around nodes in minimap bounds calculation
    public var contentPadding: CGFloat
    
    // MARK: - Initialization
    
    public init(
        position: PanelPosition = .bottomRight,
        width: CGFloat = 200,
        height: CGFloat = 150,
        padding: CGFloat = 10,
        backgroundColor: Color = Color.gray.opacity(0.1),
        borderColor: Color = Color.gray.opacity(0.3),
        borderWidth: CGFloat = 1,
        cornerRadius: CGFloat = 8,
        nodeColor: Color = Color.gray.opacity(0.1),
        nodeColorProvider: (@Sendable (UUID) -> Color)? = nil,
        nodeStrokeColor: Color = Color.gray.opacity(0.5),
        nodeStrokeWidth: CGFloat = 1,
        nodeBorderRadius: CGFloat = 2,
        showNodeLabels: Bool = false,
        nodeLabelProvider: (@Sendable (UUID) -> String?)? = nil,
        nodeLabelFont: Font = .system(size: 8),
        nodeLabelColor: Color = .primary,
        minimumNodeSizeForLabel: CGFloat = 20,
        selectedNodeColor: Color = Color.white.opacity(0.3),
        showSelectionInMiniMap: Bool = true,
        maskColor: Color = Color.gray.opacity(0.1),
        maskStrokeColor: Color = Color.gray.opacity(0.3),
        maskStrokeWidth: CGFloat = 2,
        maskCornerRadius: CGFloat = 4,
        maskStrokeDashPattern: [CGFloat]? = nil,
        pannable: Bool = true,
        zoomable: Bool = true,
        clickToMove: Bool = true,
        zoomSensitivity: CGFloat = 0.1,
        contentPadding: CGFloat = 50
    ) {
        self.position = position
        self.width = width
        self.height = height
        self.padding = padding
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.nodeColor = nodeColor
        self.nodeColorProvider = nodeColorProvider
        self.nodeStrokeColor = nodeStrokeColor
        self.nodeStrokeWidth = nodeStrokeWidth
        self.nodeBorderRadius = nodeBorderRadius
        self.showNodeLabels = showNodeLabels
        self.nodeLabelProvider = nodeLabelProvider
        self.nodeLabelFont = nodeLabelFont
        self.nodeLabelColor = nodeLabelColor
        self.minimumNodeSizeForLabel = minimumNodeSizeForLabel
        self.selectedNodeColor = selectedNodeColor
        self.showSelectionInMiniMap = showSelectionInMiniMap
        self.maskColor = maskColor
        self.maskStrokeColor = maskStrokeColor
        self.maskStrokeWidth = maskStrokeWidth
        self.maskCornerRadius = maskCornerRadius
        self.maskStrokeDashPattern = maskStrokeDashPattern
        self.pannable = pannable
        self.zoomable = zoomable
        self.clickToMove = clickToMove
        self.zoomSensitivity = zoomSensitivity
        self.contentPadding = contentPadding
    }
    
    /// Default minimap configuration
    public static let `default` = MiniMapConfig()
    
    // MARK: - Equatable
    
    /// Custom Equatable implementation (ignores closures)
    public static func == (lhs: MiniMapConfig, rhs: MiniMapConfig) -> Bool {
        return lhs.position == rhs.position &&
               lhs.width == rhs.width &&
               lhs.height == rhs.height &&
               lhs.padding == rhs.padding &&
               lhs.backgroundColor == rhs.backgroundColor &&
               lhs.borderColor == rhs.borderColor &&
               lhs.borderWidth == rhs.borderWidth &&
               lhs.cornerRadius == rhs.cornerRadius &&
               lhs.nodeColor == rhs.nodeColor &&
               lhs.nodeStrokeColor == rhs.nodeStrokeColor &&
               lhs.nodeStrokeWidth == rhs.nodeStrokeWidth &&
               lhs.nodeBorderRadius == rhs.nodeBorderRadius &&
               lhs.showNodeLabels == rhs.showNodeLabels &&
               lhs.nodeLabelFont == rhs.nodeLabelFont &&
               lhs.nodeLabelColor == rhs.nodeLabelColor &&
               lhs.minimumNodeSizeForLabel == rhs.minimumNodeSizeForLabel &&
               lhs.selectedNodeColor == rhs.selectedNodeColor &&
               lhs.showSelectionInMiniMap == rhs.showSelectionInMiniMap &&
               lhs.maskColor == rhs.maskColor &&
               lhs.maskStrokeColor == rhs.maskStrokeColor &&
               lhs.maskStrokeWidth == rhs.maskStrokeWidth &&
               lhs.maskCornerRadius == rhs.maskCornerRadius &&
               lhs.maskStrokeDashPattern == rhs.maskStrokeDashPattern &&
               lhs.pannable == rhs.pannable &&
               lhs.zoomable == rhs.zoomable &&
               lhs.clickToMove == rhs.clickToMove &&
               lhs.zoomSensitivity == rhs.zoomSensitivity &&
               lhs.contentPadding == rhs.contentPadding
        // Note: nodeColorProvider and nodeLabelProvider are closures and cannot be compared
    }
}
