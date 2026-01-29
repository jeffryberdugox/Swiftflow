//
//  EdgeConfig.swift
//  SwiftFlow
//
//  Configuration for edge/connection appearance and behavior.
//

import Foundation
import CoreGraphics

// MARK: - EdgeConfig

/// Configuration for edge/connection appearance and behavior.
///
/// # Usage
/// ```swift
/// // Default bezier edges
/// let config = EdgeConfig()
///
/// // Straight lines
/// let config = EdgeConfig(pathStyle: .straight)
///
/// // Animated edges
/// let config = EdgeConfig(animated: true, animationDuration: 1.5)
///
/// // Custom styling
/// let config = EdgeConfig(
///     pathStyle: .bezier(curvature: 0.3),
///     strokeStyle: EdgeStrokeStyle(
///         color: .blue,
///         selectedColor: .orange,
///         lineWidth: 3
///     )
/// )
/// ```
public struct EdgeConfig: Equatable, Sendable, Hashable {
    
    /// Path style (bezier, smoothStep, straight)
    public var pathStyle: EdgePathStyle
    
    /// Stroke style (colors, line width)
    public var strokeStyle: EdgeStrokeStyle
    
    /// Whether edges are animated (flowing dots)
    public var animated: Bool
    
    /// Animation duration in seconds
    public var animationDuration: TimeInterval
    
    /// Whether to show edge labels
    public var showLabels: Bool
    
    /// Hover detection radius for edges
    public var hoverRadius: CGFloat
    
    /// Marker at source (start) of edge
    public var sourceMarker: EdgeMarker?
    
    /// Marker at target (end) of edge
    public var targetMarker: EdgeMarker?
    
    /// Connection line type for preview during dragging
    public var connectionLineType: ConnectionLineType
    
    // MARK: - Initialization
    
    /// Creates an edge configuration.
    /// - Parameters:
    ///   - pathStyle: Path style. Default is `.bezier()`.
    ///   - strokeStyle: Stroke style. Default is `.default`.
    ///   - animated: Enable animation. Default is false.
    ///   - animationDuration: Animation duration. Default is 1.0 second.
    ///   - showLabels: Show edge labels. Default is true.
    ///   - hoverRadius: Hover detection radius. Default is 10.
    ///   - sourceMarker: Marker at source. Default is nil.
    ///   - targetMarker: Marker at target. Default is `.targetArrow`.
    ///   - connectionLineType: Connection preview type. Default is `.inherit`.
    public init(
        pathStyle: EdgePathStyle = .default,
        strokeStyle: EdgeStrokeStyle = .default,
        animated: Bool = false,
        animationDuration: TimeInterval = 1.0,
        showLabels: Bool = true,
        hoverRadius: CGFloat = 10,
        sourceMarker: EdgeMarker? = nil,
        targetMarker: EdgeMarker? = .targetArrow,
        connectionLineType: ConnectionLineType = .inherit
    ) {
        self.pathStyle = pathStyle
        self.strokeStyle = strokeStyle
        self.animated = animated
        self.animationDuration = animationDuration
        self.showLabels = showLabels
        self.hoverRadius = hoverRadius
        self.sourceMarker = sourceMarker
        self.targetMarker = targetMarker
        self.connectionLineType = connectionLineType
    }
    
    // MARK: - Presets
    
    /// Default edge configuration
    public static let `default` = EdgeConfig()
    
    /// Straight line edges
    public static let straight = EdgeConfig(pathStyle: .straight)
    
    /// Smooth step (orthogonal) edges
    public static let smoothStep = EdgeConfig(pathStyle: .smoothStep())
    
    /// Animated edges
    public static let animated = EdgeConfig(animated: true)
    
    /// Minimal (no labels)
    public static let minimal = EdgeConfig(showLabels: false)
}

// MARK: - EdgeStrokeStyle

/// Visual style for edge strokes.
public struct EdgeStrokeStyle: Equatable, Sendable, Hashable {
    
    /// Default stroke color
    public var color: RGBAColor
    
    /// Color when edge is selected
    public var selectedColor: RGBAColor
    
    /// Stroke line width
    public var lineWidth: CGFloat
    
    // MARK: - Initialization
    
    /// Creates an edge stroke style.
    /// - Parameters:
    ///   - color: Default color. Default is gray at 60% opacity.
    ///   - selectedColor: Selected color. Default is blue.
    ///   - lineWidth: Line width. Default is 2.0.
    public init(
        color: RGBAColor = RGBAColor.gray.withAlpha(0.6),
        selectedColor: RGBAColor = RGBAColor.blue,
        lineWidth: CGFloat = 2.0
    ) {
        self.color = color
        self.selectedColor = selectedColor
        self.lineWidth = lineWidth
    }
    
    // MARK: - Presets
    
    /// Default stroke style
    public static let `default` = EdgeStrokeStyle()
    
    /// Thin stroke style
    public static let thin = EdgeStrokeStyle(lineWidth: 1.0)
    
    /// Thick stroke style
    public static let thick = EdgeStrokeStyle(lineWidth: 3.0)
    
    /// High contrast style
    public static let highContrast = EdgeStrokeStyle(
        color: RGBAColor.black,
        selectedColor: RGBAColor.red,
        lineWidth: 2.5
    )
}

// MARK: - Codable

extension EdgeConfig: Codable {}
extension EdgeStrokeStyle: Codable {}
