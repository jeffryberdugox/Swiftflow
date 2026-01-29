//
//  ZoomConfig.swift
//  SwiftFlow
//
//  Configuration for zoom behavior.
//

import Foundation
import CoreGraphics

// MARK: - ZoomConfig

/// Configuration for zoom behavior in the canvas.
///
/// # Usage
/// ```swift
/// // Default zoom settings
/// let config = ZoomConfig()
///
/// // Custom zoom range
/// let config = ZoomConfig(min: 0.5, max: 2.0)
///
/// // Enable double-click zoom
/// let config = ZoomConfig(doubleClickEnabled: true)
/// ```
public struct ZoomConfig: Equatable, Sendable, Hashable {
    
    /// Minimum zoom level (e.g., 0.1 = 10%)
    public var min: CGFloat
    
    /// Maximum zoom level (e.g., 4.0 = 400%)
    public var max: CGFloat
    
    /// Initial zoom level when canvas is first displayed
    public var initial: CGFloat
    
    /// Whether double-click zooms in/out
    public var doubleClickEnabled: Bool
    
    /// Whether scroll wheel/trackpad zooms
    public var scrollEnabled: Bool
    
    /// Zoom factor for zoom in/out operations (1.2 = 20% per step)
    public var stepFactor: CGFloat
    
    /// Scroll behavior mode (zoom, pan horizontal, pan vertical, free)
    public var panOnScrollMode: PanOnScrollMode
    
    // MARK: - Initialization
    
    /// Creates a zoom configuration.
    /// - Parameters:
    ///   - min: Minimum zoom level. Default is 0.1 (10%).
    ///   - max: Maximum zoom level. Default is 4.0 (400%).
    ///   - initial: Initial zoom level. Default is 1.0 (100%).
    ///   - doubleClickEnabled: Enable double-click zoom. Default is false.
    ///   - scrollEnabled: Enable scroll/trackpad zoom. Default is true.
    ///   - stepFactor: Zoom factor per step. Default is 1.2 (20%).
    ///   - panOnScrollMode: Scroll behavior mode. Default is `.zoom`.
    public init(
        min: CGFloat = 0.1,
        max: CGFloat = 4.0,
        initial: CGFloat = 1.0,
        doubleClickEnabled: Bool = false,
        scrollEnabled: Bool = true,
        stepFactor: CGFloat = 1.2,
        panOnScrollMode: PanOnScrollMode = .default
    ) {
        self.min = min
        self.max = max
        self.initial = initial
        self.doubleClickEnabled = doubleClickEnabled
        self.scrollEnabled = scrollEnabled
        self.stepFactor = stepFactor
        self.panOnScrollMode = panOnScrollMode
    }
    
    // MARK: - Presets
    
    /// Default zoom configuration
    public static let `default` = ZoomConfig()
    
    /// Restricted zoom range (50% - 200%)
    public static let restricted = ZoomConfig(min: 0.5, max: 2.0)
    
    /// Wide zoom range (5% - 1000%)
    public static let wide = ZoomConfig(min: 0.05, max: 10.0)
    
    /// No zoom (fixed at 100%)
    public static let disabled = ZoomConfig(
        min: 1.0,
        max: 1.0,
        initial: 1.0,
        doubleClickEnabled: false,
        scrollEnabled: false
    )
}

// MARK: - Codable

extension ZoomConfig: Codable {}
