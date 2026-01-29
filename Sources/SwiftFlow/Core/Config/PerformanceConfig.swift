//
//  PerformanceConfig.swift
//  SwiftFlow
//
//  Performance optimization configuration for rendering large graphs.
//

import Foundation
import CoreGraphics

/// Performance optimization configuration
///
/// # Usage
/// ```swift
/// // Maximum performance (all optimizations)
/// let config = CanvasConfig(performance: .maximum)
///
/// // Balanced (recommended default)
/// let config = CanvasConfig(performance: .balanced)
///
/// // Custom configuration
/// let config = CanvasConfig(
///     performance: PerformanceConfig(
///         enableDrawingGroup: true,
///         enableViewportCulling: true,
///         cullingMargin: 300
///     )
/// )
/// ```
public struct PerformanceConfig: Equatable, Sendable, Hashable {
    
    /// Enable GPU-accelerated rendering for canvas content
    /// When true, uses .drawingGroup() to batch render nodes and edges
    /// Recommended: true (significantly improves performance)
    public var enableDrawingGroup: Bool
    
    /// Enable viewport culling (only render visible nodes/edges)
    /// When true, nodes/edges outside viewport are not rendered
    /// Recommended: true for 50+ nodes
    public var enableViewportCulling: Bool
    
    /// Viewport culling margin (in canvas coordinates)
    /// Adds padding to viewport bounds to prevent pop-in during pan
    public var cullingMargin: CGFloat
    
    /// Enable edge path caching
    /// When true, edge paths are cached and only recalculated when needed
    /// Recommended: true for 30+ edges
    public var enablePathCache: Bool
    
    /// Enable transform ID optimization
    /// When true, removes the .id() that forces re-render on every transform
    /// Recommended: true (removes major performance bottleneck)
    public var optimizeTransformRendering: Bool
    
    /// Debounce interval for expensive updates during drag/zoom (milliseconds)
    /// 0 = no debounce, 16 = update every frame (~60fps)
    public var updateDebounceMs: Int
    
    // MARK: - Initialization
    
    /// Creates a performance configuration.
    /// - Parameters:
    ///   - enableDrawingGroup: Enable GPU-accelerated rendering. Default is true.
    ///   - enableViewportCulling: Enable viewport culling. Default is true.
    ///   - cullingMargin: Viewport padding in canvas coordinates. Default is 200.
    ///   - enablePathCache: Enable edge path caching. Default is true.
    ///   - optimizeTransformRendering: Enable transform optimization. Default is true.
    ///   - updateDebounceMs: Debounce interval in milliseconds. Default is 0.
    public init(
        enableDrawingGroup: Bool = true,
        enableViewportCulling: Bool = true,
        cullingMargin: CGFloat = 200,
        enablePathCache: Bool = true,
        optimizeTransformRendering: Bool = true,
        updateDebounceMs: Int = 0
    ) {
        self.enableDrawingGroup = enableDrawingGroup
        self.enableViewportCulling = enableViewportCulling
        self.cullingMargin = cullingMargin
        self.enablePathCache = enablePathCache
        self.optimizeTransformRendering = optimizeTransformRendering
        self.updateDebounceMs = updateDebounceMs
    }
    
    // MARK: - Presets
    
    /// Maximum performance (all optimizations enabled)
    /// Recommended for 100+ nodes/edges
    public static let maximum = PerformanceConfig()
    
    /// Balanced performance (safe for most use cases)
    /// Default preset with all core optimizations enabled
    public static let balanced = PerformanceConfig(
        enableDrawingGroup: true,
        enableViewportCulling: true,
        enablePathCache: true,
        optimizeTransformRendering: true
    )
    
    /// Conservative (minimal optimizations for debugging)
    /// Use this for debugging visual issues
    public static let conservative = PerformanceConfig(
        enableDrawingGroup: true,
        enableViewportCulling: false,
        enablePathCache: false,
        optimizeTransformRendering: true
    )
    
    /// Legacy behavior (all optimizations disabled)
    /// Use this to restore pre-v2.0 behavior
    public static let legacy = PerformanceConfig(
        enableDrawingGroup: false,
        enableViewportCulling: false,
        enablePathCache: false,
        optimizeTransformRendering: false
    )
}

// MARK: - Codable

extension PerformanceConfig: Codable {}
