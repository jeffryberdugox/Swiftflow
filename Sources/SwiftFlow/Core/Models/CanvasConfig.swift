//
//  CanvasConfig.swift
//  SwiftFlow
//
//  Configuration options for the canvas view.
//  Now uses structured sub-configs for cleaner API.
//

import Foundation
import CoreGraphics
import SwiftUI

/// Configuration options for the canvas view.
/// Uses structured sub-configs for a cleaner, more organized API.
///
/// # Simple Usage
/// ```swift
/// // Default configuration
/// let config = CanvasConfig()
///
/// // Using presets
/// let config = CanvasConfig.minimal
/// let config = CanvasConfig.presentation
/// ```
///
/// # Custom Configuration
/// ```swift
/// let config = CanvasConfig(
///     zoom: ZoomConfig(min: 0.5, max: 2.0),
///     grid: .snapping,
///     interaction: .default,
///     edge: EdgeConfig(pathStyle: .smoothStep())
/// )
/// ```
public struct CanvasConfig: Equatable, Sendable {
    
    // MARK: - Sub-Configs (New API)
    
    /// Zoom configuration
    public var zoom: ZoomConfig
    
    /// Grid configuration
    public var grid: GridConfig
    
    /// Interaction configuration
    public var interaction: InteractionConfig
    
    /// Edge configuration
    public var edge: EdgeConfig
    
    /// MiniMap configuration (nil = disabled)
    public var miniMapConfig: MiniMapConfig?
    
    /// History (undo/redo) configuration
    public var history: HistoryConfig
    
    /// Auto-pan configuration
    public var autoPan: AutoPanConfig
    
    /// Helper lines (alignment guides) configuration
    public var helperLines: HelperLinesConfig
    
    // MARK: - Additional Settings
    
    /// Whether to show controls overlay
    public var showControls: Bool
    
    /// Padding when fitting nodes to view
    public var fitViewPadding: CGFloat
    
    /// Enable parent-child node hierarchy
    public var enableParentChild: Bool
    
    /// Background color of the canvas (SwiftUI layer)
    public var canvasBackgroundColor: Color
    
    /// Default stroke color for edges (SwiftUI layer)
    public var defaultEdgeStrokeColor: Color
    
    /// Default line width for edges
    public var defaultEdgeLineWidth: CGFloat
    
    /// Default color for selected edges (SwiftUI layer)
    public var defaultEdgeSelectedColor: Color
    
    /// Type of edge accessory to display
    public var edgeAccessoryType: EdgeAccessoryType
    
    /// Visibility behavior for edge accessory
    public var edgeAccessoryVisibility: EdgeAccessoryVisibility
    
    /// Enable node resizing
    public var enableNodeResizing: Bool
    
    /// Minimum node width when resizing
    public var minNodeWidth: CGFloat
    
    /// Minimum node height when resizing
    public var minNodeHeight: CGFloat
    
    /// Preserve aspect ratio when resizing
    public var preserveAspectRatio: Bool
    
    // MARK: - New Initializer (Recommended)
    
    /// Creates a canvas configuration with structured sub-configs.
    /// This is the recommended way to configure the canvas.
    ///
    /// - Parameters:
    ///   - zoom: Zoom behavior configuration
    ///   - grid: Grid display and snap configuration
    ///   - interaction: User interaction configuration
    ///   - edge: Edge appearance configuration
    ///   - miniMap: MiniMap configuration (nil to disable)
    ///   - history: Undo/redo configuration
    ///   - autoPan: Auto-pan behavior configuration
    ///   - helperLines: Helper lines (alignment guides) configuration
    ///   - showControls: Whether to show controls overlay
    ///   - fitViewPadding: Padding when fitting nodes to view
    ///   - enableParentChild: Enable nested node hierarchy
    public init(
        zoom: ZoomConfig = .default,
        grid: GridConfig = .default,
        interaction: InteractionConfig = .default,
        edge: EdgeConfig = .default,
        miniMap: MiniMapConfig? = MiniMapConfig(),
        history: HistoryConfig = .default,
        autoPan: AutoPanConfig = .default,
        helperLines: HelperLinesConfig = .default,
        showControls: Bool = true,
        fitViewPadding: CGFloat = 50,
        enableParentChild: Bool = true,
        canvasBackgroundColor: Color = Color(nsColor: .controlBackgroundColor),
        defaultEdgeStrokeColor: Color = Color.gray.opacity(0.6),
        defaultEdgeLineWidth: CGFloat = 2.0,
        defaultEdgeSelectedColor: Color = Color.blue,
        edgeAccessoryType: EdgeAccessoryType = .label,
        edgeAccessoryVisibility: EdgeAccessoryVisibility = .visible,
        enableNodeResizing: Bool = false,
        minNodeWidth: CGFloat = 50,
        minNodeHeight: CGFloat = 50,
        preserveAspectRatio: Bool = false
    ) {
        self.zoom = zoom
        self.grid = grid
        self.interaction = interaction
        self.edge = edge
        self.miniMapConfig = miniMap
        self.history = history
        self.autoPan = autoPan
        self.helperLines = helperLines
        self.showControls = showControls
        self.fitViewPadding = fitViewPadding
        self.enableParentChild = enableParentChild
        self.canvasBackgroundColor = canvasBackgroundColor
        self.defaultEdgeStrokeColor = defaultEdgeStrokeColor
        self.defaultEdgeLineWidth = defaultEdgeLineWidth
        self.defaultEdgeSelectedColor = defaultEdgeSelectedColor
        self.edgeAccessoryType = edgeAccessoryType
        self.edgeAccessoryVisibility = edgeAccessoryVisibility
        self.enableNodeResizing = enableNodeResizing
        self.minNodeWidth = minNodeWidth
        self.minNodeHeight = minNodeHeight
        self.preserveAspectRatio = preserveAspectRatio
    }
    
    // MARK: - Presets
    
    /// Default configuration
    public static let `default` = CanvasConfig()
    
    /// Minimal configuration (no grid, no minimap, no controls)
    public static let minimal = CanvasConfig(
        grid: .hidden,
        miniMap: nil,
        showControls: false
    )
    
    /// Presentation mode (view only, no editing)
    public static let presentation = CanvasConfig(
        interaction: .viewOnly,
        showControls: true
    )
    
    /// Debugging configuration (grid with snap enabled)
    public static let debugging = CanvasConfig(
        grid: .snapping
    )
    
    /// Blueprint style (blue background, white grid)
    public static let blueprint = CanvasConfig(
        grid: GridConfig(
            visible: true,
            size: 20,
            snap: true,
            pattern: .lines,
            style: .blueprint
        ),
        canvasBackgroundColor: Color(red: 0.1, green: 0.2, blue: 0.4)
    )
    
    // MARK: - Equatable
    
    public static func == (lhs: CanvasConfig, rhs: CanvasConfig) -> Bool {
        return lhs.zoom == rhs.zoom &&
               lhs.grid == rhs.grid &&
               lhs.interaction == rhs.interaction &&
               lhs.edge == rhs.edge &&
               lhs.miniMapConfig == rhs.miniMapConfig &&
               lhs.history == rhs.history &&
               lhs.autoPan == rhs.autoPan &&
               lhs.helperLines == rhs.helperLines &&
               lhs.showControls == rhs.showControls &&
               lhs.fitViewPadding == rhs.fitViewPadding &&
               lhs.enableParentChild == rhs.enableParentChild
    }
}
