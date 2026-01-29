//
//  HelperLinesConfig.swift
//  SwiftFlow
//
//  Configuration for helper lines (alignment guides) during node dragging.
//  Uses RGBAColor to avoid SwiftUI dependency in Core layer.
//

import Foundation
import CoreGraphics

// MARK: - HelperLinesConfig

/// Configuration for helper lines (alignment guides) behavior.
///
/// # Usage
/// ```swift
/// // Default (disabled)
/// let config = HelperLinesConfig()
///
/// // Enabled with snapping and haptic feedback
/// let config = HelperLinesConfig.enabled
///
/// // Custom configuration
/// let config = HelperLinesConfig(
///     enabled: true,
///     threshold: 8.0,
///     snapToGuides: true,
///     showCenterGuides: true,
///     showEdgeGuides: true,
///     hapticFeedback: true,  // Haptic feedback on snap
///     style: .default
/// )
/// ```
public struct HelperLinesConfig: Equatable, Sendable, Hashable {
    
    /// Whether helper lines are enabled
    public var enabled: Bool
    
    /// Distance threshold for detecting alignment (in canvas units)
    public var threshold: CGFloat
    
    /// Whether to snap nodes to alignment guides
    public var snapToGuides: Bool
    
    /// Whether to show center alignment guides
    public var showCenterGuides: Bool
    
    /// Whether to show edge alignment guides (left, right, top, bottom)
    public var showEdgeGuides: Bool
    
    /// Whether to provide haptic feedback when snapping
    public var hapticFeedback: Bool
    
    /// Visual style for helper lines
    public var style: HelperLinesStyle
    
    // MARK: - Initialization
    
    public init(
        enabled: Bool = false,
        threshold: CGFloat = 5.0,
        snapToGuides: Bool = true,
        showCenterGuides: Bool = true,
        showEdgeGuides: Bool = true,
        hapticFeedback: Bool = true,
        style: HelperLinesStyle = .default
    ) {
        self.enabled = enabled
        self.threshold = threshold
        self.snapToGuides = snapToGuides
        self.showCenterGuides = showCenterGuides
        self.showEdgeGuides = showEdgeGuides
        self.hapticFeedback = hapticFeedback
        self.style = style
    }
    
    // MARK: - Presets
    
    /// Default configuration (disabled)
    public static let `default` = HelperLinesConfig()
    
    /// Enabled with default settings
    public static let enabled = HelperLinesConfig(enabled: true)
    
    /// Enabled with snapping
    public static let snapping = HelperLinesConfig(
        enabled: true,
        snapToGuides: true
    )
    
    /// Enabled without snapping (visual guides only)
    public static let visualOnly = HelperLinesConfig(
        enabled: true,
        snapToGuides: false
    )
    
    /// Center guides only
    public static let centerOnly = HelperLinesConfig(
        enabled: true,
        showCenterGuides: true,
        showEdgeGuides: false
    )
}

// MARK: - HelperLinesStyle

/// Visual style for helper lines rendering.
/// Uses RGBAColor to keep Core layer SwiftUI-free.
public struct HelperLinesStyle: Equatable, Sendable, Hashable {
    
    /// Color of the helper lines
    public var lineColor: RGBAColor
    
    /// Width of the helper lines
    public var lineWidth: CGFloat
    
    /// Dash pattern (empty for solid line)
    public var dashPattern: [CGFloat]
    
    // MARK: - Initialization
    
    public init(
        lineColor: RGBAColor = RGBAColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 0.8),
        lineWidth: CGFloat = 1.0,
        dashPattern: [CGFloat] = []
    ) {
        self.lineColor = lineColor
        self.lineWidth = lineWidth
        self.dashPattern = dashPattern
    }
    
    // MARK: - Presets
    
    /// Default style (blue solid line)
    public static let `default` = HelperLinesStyle()
    
    /// Dashed style
    public static let dashed = HelperLinesStyle(
        dashPattern: [5, 3]
    )
    
    /// Subtle style (lighter color)
    public static let subtle = HelperLinesStyle(
        lineColor: RGBAColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5),
        lineWidth: 0.5
    )
}

// MARK: - Codable

extension HelperLinesConfig: Codable {}
extension HelperLinesStyle: Codable {}
