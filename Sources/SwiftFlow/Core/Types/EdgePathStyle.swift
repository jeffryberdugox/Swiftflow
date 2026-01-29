//
//  EdgePathStyle.swift
//  SwiftFlow
//
//  Defines the visual style for edge path rendering.
//  Uses an enum with associated values instead of separate type + config properties.
//

import Foundation
import CoreGraphics

// MARK: - EdgePathStyle

/// Defines how edge paths are rendered between nodes.
/// Uses associated values for style-specific configuration.
///
/// # Usage
/// ```swift
/// // Default bezier curve
/// let style: EdgePathStyle = .bezier()
///
/// // Custom curvature
/// let gentle: EdgePathStyle = .bezier(curvature: 0.15)
/// let dramatic: EdgePathStyle = .bezier(curvature: 0.5)
///
/// // Orthogonal paths
/// let stepped: EdgePathStyle = .smoothStep()
/// let rounded: EdgePathStyle = .smoothStep(borderRadius: 12)
///
/// // Direct lines
/// let direct: EdgePathStyle = .straight
/// ```
public enum EdgePathStyle: Equatable, Sendable, Hashable {
    
    /// Smooth bezier curve connecting source to target.
    /// - Parameter curvature: Control point distance factor (0.0 - 1.0).
    ///   Higher values create more pronounced curves. Default is 0.25.
    case bezier(curvature: CGFloat = 0.25)
    
    /// Orthogonal path with optional rounded corners.
    /// Path segments are always horizontal or vertical.
    /// - Parameter borderRadius: Corner radius for path bends. Default is 8.
    case smoothStep(borderRadius: CGFloat = 8)
    
    /// Direct straight line from source to target.
    /// Simplest path type, no curves or bends.
    case straight
    
    // MARK: - Default
    
    /// The default edge path style (bezier with standard curvature)
    public static let `default` = EdgePathStyle.bezier()
    
    // MARK: - Properties
    
    /// Returns the curvature value for bezier paths, nil for other types.
    public var curvature: CGFloat? {
        if case .bezier(let curvature) = self {
            return curvature
        }
        return nil
    }
    
    /// Returns the border radius for smooth step paths, nil for other types.
    public var borderRadius: CGFloat? {
        if case .smoothStep(let radius) = self {
            return radius
        }
        return nil
    }
    
    /// Returns a string identifier for this path type.
    public var typeIdentifier: String {
        switch self {
        case .bezier:
            return "bezier"
        case .smoothStep:
            return "smoothStep"
        case .straight:
            return "straight"
        }
    }
}

// MARK: - Codable

extension EdgePathStyle: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case curvature
        case borderRadius
    }
    
    private enum PathType: String, Codable {
        case bezier, smoothStep, straight
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(PathType.self, forKey: .type)
        
        switch type {
        case .bezier:
            let curvature = try container.decodeIfPresent(CGFloat.self, forKey: .curvature) ?? 0.25
            self = .bezier(curvature: curvature)
        case .smoothStep:
            let radius = try container.decodeIfPresent(CGFloat.self, forKey: .borderRadius) ?? 8
            self = .smoothStep(borderRadius: radius)
        case .straight:
            self = .straight
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .bezier(let curvature):
            try container.encode(PathType.bezier, forKey: .type)
            try container.encode(curvature, forKey: .curvature)
        case .smoothStep(let radius):
            try container.encode(PathType.smoothStep, forKey: .type)
            try container.encode(radius, forKey: .borderRadius)
        case .straight:
            try container.encode(PathType.straight, forKey: .type)
        }
    }
}

// MARK: - CustomStringConvertible

extension EdgePathStyle: CustomStringConvertible {
    public var description: String {
        switch self {
        case .bezier(let curvature):
            return "EdgePathStyle.bezier(curvature: \(String(format: "%.2f", curvature)))"
        case .smoothStep(let radius):
            return "EdgePathStyle.smoothStep(borderRadius: \(String(format: "%.1f", radius)))"
        case .straight:
            return "EdgePathStyle.straight"
        }
    }
}

// MARK: - ResizeAnchor

/// Defines the anchor point for resize operations.
/// Determines which corner/edge remains fixed during resize.
public enum ResizeAnchor: String, Equatable, Sendable, Codable, CaseIterable {
    /// Top-left corner is anchored
    case topLeft
    /// Top-right corner is anchored
    case topRight
    /// Bottom-left corner is anchored
    case bottomLeft
    /// Bottom-right corner is anchored
    case bottomRight
    /// Top edge center is anchored
    case top
    /// Bottom edge center is anchored
    case bottom
    /// Left edge center is anchored
    case left
    /// Right edge center is anchored
    case right
    /// Center is anchored (resize expands/contracts equally)
    case center
    
    /// Returns the opposite anchor point
    public var opposite: ResizeAnchor {
        switch self {
        case .topLeft: return .bottomRight
        case .topRight: return .bottomLeft
        case .bottomLeft: return .topRight
        case .bottomRight: return .topLeft
        case .top: return .bottom
        case .bottom: return .top
        case .left: return .right
        case .right: return .left
        case .center: return .center
        }
    }
}
