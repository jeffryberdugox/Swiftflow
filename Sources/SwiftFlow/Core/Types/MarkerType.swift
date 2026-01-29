//
//  MarkerType.swift
//  SwiftFlow
//
//  Defines marker types for edge endpoints.
//

import Foundation

/// Type of marker (arrow, dot, etc.) for edge endpoints
public enum MarkerType: Equatable, Sendable, Hashable, Codable {
    /// Standard arrow marker
    case arrow
    
    /// Filled arrow marker
    case arrowClosed
    
    /// Circular dot marker
    case dot
    
    /// No marker
    case none
    
    public static let `default`: MarkerType = .arrow
}

/// Position of marker on edge
public enum MarkerPosition: String, Equatable, Sendable, Hashable, Codable {
    /// Marker at source (start) of edge
    case source
    
    /// Marker at target (end) of edge
    case target
}

/// Configuration for an edge marker
public struct EdgeMarker: Equatable, Sendable, Hashable, Codable {
    /// Type of marker
    public var type: MarkerType
    
    /// Position on edge
    public var position: MarkerPosition
    
    /// Size of marker
    public var size: CGFloat
    
    /// Color of marker (uses RGBAColor for platform independence)
    public var color: RGBAColor?
    
    public init(
        type: MarkerType,
        position: MarkerPosition,
        size: CGFloat = 8,
        color: RGBAColor? = nil
    ) {
        self.type = type
        self.position = position
        self.size = size
        self.color = color
    }
    
    // MARK: - Presets
    
    /// Standard arrow at target
    public static let targetArrow = EdgeMarker(type: .arrow, position: .target)
    
    /// Filled arrow at target
    public static let targetArrowClosed = EdgeMarker(type: .arrowClosed, position: .target)
    
    /// Dot at target
    public static let targetDot = EdgeMarker(type: .dot, position: .target)
    
    /// Standard arrow at source
    public static let sourceArrow = EdgeMarker(type: .arrow, position: .source)
    
    /// Filled arrow at source
    public static let sourceArrowClosed = EdgeMarker(type: .arrowClosed, position: .source)
    
    /// Dot at source
    public static let sourceDot = EdgeMarker(type: .dot, position: .source)
}
