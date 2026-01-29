//
//  GridConfig.swift
//  SwiftFlow
//
//  Configuration for grid display and snapping.
//  Uses RGBAColor to avoid SwiftUI dependency in Core layer.
//

import Foundation
import CoreGraphics

// MARK: - GridConfig

/// Configuration for grid display and snapping behavior.
///
/// # Usage
/// ```swift
/// // Default grid
/// let config = GridConfig()
///
/// // Hidden grid
/// let config = GridConfig.hidden
///
/// // Grid with snapping enabled
/// let config = GridConfig.snapping
///
/// // Custom grid
/// let config = GridConfig(
///     visible: true,
///     size: 25,
///     snap: true,
///     pattern: .dots,
///     style: GridStyle(lineColor: .gray.withAlpha(0.3))
/// )
/// ```
public struct GridConfig: Equatable, Sendable, Hashable {
    
    /// Whether the grid is visible
    public var visible: Bool
    
    /// Size of grid cells in canvas units
    public var size: CGFloat
    
    /// Whether nodes snap to grid when dragging
    public var snap: Bool
    
    /// Visual pattern for the grid
    public var pattern: GridPattern
    
    /// Visual style for the grid (colors, line width)
    public var style: GridStyle
    
    // MARK: - Initialization
    
    /// Creates a grid configuration.
    /// - Parameters:
    ///   - visible: Whether the grid is visible. Default is true.
    ///   - size: Grid cell size. Default is 20.
    ///   - snap: Whether nodes snap to grid. Default is false.
    ///   - pattern: Grid pattern. Default is `.lines`.
    ///   - style: Grid visual style. Default is `.default`.
    public init(
        visible: Bool = true,
        size: CGFloat = 20,
        snap: Bool = false,
        pattern: GridPattern = .dots,
        style: GridStyle = .default
    ) {
        self.visible = visible
        self.size = size
        self.snap = snap
        self.pattern = pattern
        self.style = style
    }
    
    // MARK: - Presets
    
    /// Default grid configuration (visible, no snap)
    public static let `default` = GridConfig()
    
    /// Hidden grid
    public static let hidden = GridConfig(visible: false)
    
    /// Grid with snapping enabled
    public static let snapping = GridConfig(snap: true)
    
    /// Dot pattern grid
    public static let dots = GridConfig(pattern: .dots)
    
    /// Large grid (40px cells)
    public static let large = GridConfig(size: 40)
    
    /// Small grid (10px cells)
    public static let small = GridConfig(size: 10)
    
    // MARK: - Factory Methods
    
    /// Create a visible grid with optional snapping.
    /// - Parameter snap: Whether to enable snapping
    /// - Returns: Grid configuration
    public static func visible(snap: Bool = false) -> GridConfig {
        GridConfig(visible: true, snap: snap)
    }
    
    /// Create a grid with custom size.
    /// - Parameters:
    ///   - size: Grid cell size
    ///   - snap: Whether to enable snapping
    /// - Returns: Grid configuration
    public static func withSize(_ size: CGFloat, snap: Bool = false) -> GridConfig {
        GridConfig(size: size, snap: snap)
    }
}

// MARK: - GridColorMode

/// Determines how grid colors adapt to the system color scheme
public enum GridColorMode: Equatable, Sendable, Hashable, Codable {
    /// Adaptive colors that change with system light/dark mode
    case adaptive
    
    /// Fixed colors that don't change with system theme
    case fixed(light: RGBAColor, dark: RGBAColor)
    
    /// Static color (legacy mode, same in light and dark)
    case staticColor(RGBAColor)
}

// MARK: - GridStyle

/// Visual style for grid rendering.
/// Supports both static colors and adaptive colors that respond to system theme.
public struct GridStyle: Equatable, Sendable, Hashable {
    
    /// Color mode for grid lines/dots
    public var lineColorMode: GridColorMode
    
    /// Width of grid lines
    public var lineWidth: CGFloat
    
    /// Color mode for canvas background
    public var backgroundColorMode: GridColorMode
    
    // MARK: - Initialization
    
    /// Creates a grid style with adaptive or fixed colors.
    /// - Parameters:
    ///   - lineColorMode: Color mode for grid lines/dots. Default is adaptive.
    ///   - lineWidth: Width of grid lines. Default is 0.5.
    ///   - backgroundColorMode: Color mode for canvas background. Default is adaptive.
    public init(
        lineColorMode: GridColorMode = .adaptive,
        lineWidth: CGFloat = 0.5,
        backgroundColorMode: GridColorMode = .adaptive
    ) {
        self.lineColorMode = lineColorMode
        self.lineWidth = lineWidth
        self.backgroundColorMode = backgroundColorMode
    }
    
    /// Creates a grid style with legacy static colors (backward compatibility).
    /// - Parameters:
    ///   - lineColor: Color for grid lines/dots.
    ///   - lineWidth: Width of grid lines. Default is 0.5.
    ///   - backgroundColor: Canvas background color.
    @available(*, deprecated, message: "Use init with GridColorMode for adaptive colors")
    public init(
        lineColor: RGBAColor,
        lineWidth: CGFloat = 0.5,
        backgroundColor: RGBAColor
    ) {
        self.lineColorMode = .staticColor(lineColor)
        self.lineWidth = lineWidth
        self.backgroundColorMode = .staticColor(backgroundColor)
    }
    
    // MARK: - Computed Properties for Legacy Support
    
    /// Legacy property for line color (returns light mode color if adaptive)
    @available(*, deprecated, message: "Use lineColorMode instead")
    public var lineColor: RGBAColor {
        get {
            switch lineColorMode {
            case .adaptive:
                return RGBAColor.gray.withAlpha(0.2) // Light mode default
            case .fixed(let light, _):
                return light
            case .staticColor(let color):
                return color
            }
        }
        set {
            lineColorMode = .staticColor(newValue)
        }
    }
    
    /// Legacy property for background color (returns light mode color if adaptive)
    @available(*, deprecated, message: "Use backgroundColorMode instead")
    public var backgroundColor: RGBAColor {
        get {
            switch backgroundColorMode {
            case .adaptive:
                return RGBAColor(red: 0.95, green: 0.95, blue: 0.95) // Light mode default
            case .fixed(let light, _):
                return light
            case .staticColor(let color):
                return color
            }
        }
        set {
            backgroundColorMode = .staticColor(newValue)
        }
    }
    
    // MARK: - Presets
    
    /// Default adaptive grid style (responds to system theme)
    public static let `default` = GridStyle()
    
    /// Dark mode grid style (fixed dark colors)
    public static let dark = GridStyle(
        lineColorMode: .fixed(
            light: RGBAColor.gray.withAlpha(0.2),
            dark: RGBAColor.white.withAlpha(0.1)
        ),
        backgroundColorMode: .fixed(
            light: RGBAColor(red: 0.95, green: 0.95, blue: 0.95),
            dark: RGBAColor(red: 0.1, green: 0.1, blue: 0.1)
        )
    )
    
    /// High contrast grid style (adaptive with higher opacity)
    public static let highContrast = GridStyle(
        lineColorMode: .fixed(
            light: RGBAColor.gray.withAlpha(0.4),
            dark: RGBAColor.white.withAlpha(0.25)
        ),
        lineWidth: 1.0,
        backgroundColorMode: .adaptive
    )
    
    /// Blueprint style (blue background, white lines)
    public static let blueprint = GridStyle(
        lineColorMode: .staticColor(RGBAColor.white.withAlpha(0.2)),
        lineWidth: 0.5,
        backgroundColorMode: .staticColor(RGBAColor(red: 0.1, green: 0.2, blue: 0.4))
    )
}

// MARK: - Codable

extension GridConfig: Codable {}
extension GridStyle: Codable {}
