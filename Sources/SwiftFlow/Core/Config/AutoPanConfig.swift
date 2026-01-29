//
//  AutoPanConfig.swift
//  SwiftFlow
//
//  Configuration for auto-pan behavior when dragging near edges.
//

import Foundation
import CoreGraphics

// MARK: - AutoPanConfig

/// Configuration for auto-pan behavior when dragging near viewport edges.
///
/// # Usage
/// ```swift
/// // Default auto-pan
/// let config = AutoPanConfig()
///
/// // Disabled
/// let config = AutoPanConfig.disabled
///
/// // Fast auto-pan
/// let config = AutoPanConfig(speed: 25, threshold: 50)
/// ```
public struct AutoPanConfig: Equatable, Sendable, Hashable {
    
    /// Whether auto-pan is enabled
    public var enabled: Bool
    
    /// Pan speed in pixels per frame
    public var speed: CGFloat
    
    /// Distance from edge to trigger auto-pan
    public var threshold: CGFloat
    
    // MARK: - Initialization
    
    /// Creates an auto-pan configuration.
    /// - Parameters:
    ///   - enabled: Enable auto-pan. Default is true.
    ///   - speed: Pan speed. Default is 15.
    ///   - threshold: Trigger threshold. Default is 40.
    public init(
        enabled: Bool = true,
        speed: CGFloat = 15,
        threshold: CGFloat = 40
    ) {
        self.enabled = enabled
        self.speed = speed
        self.threshold = threshold
    }
    
    // MARK: - Presets
    
    /// Default auto-pan
    public static let `default` = AutoPanConfig()
    
    /// Auto-pan disabled
    public static let disabled = AutoPanConfig(enabled: false)
    
    /// Fast auto-pan
    public static let fast = AutoPanConfig(speed: 25)
    
    /// Slow auto-pan
    public static let slow = AutoPanConfig(speed: 8)
    
    /// Large trigger area
    public static let largeTrigger = AutoPanConfig(threshold: 60)
    
    /// Small trigger area
    public static let smallTrigger = AutoPanConfig(threshold: 25)
    
    // MARK: - Factory Methods
    
    /// Create enabled auto-pan with custom speed.
    public static func enabled(speed: CGFloat = 15, threshold: CGFloat = 40) -> AutoPanConfig {
        AutoPanConfig(enabled: true, speed: speed, threshold: threshold)
    }
}

// MARK: - Codable

extension AutoPanConfig: Codable {}
