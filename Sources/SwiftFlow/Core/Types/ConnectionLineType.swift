//
//  ConnectionLineType.swift
//  SwiftFlow
//
//  Defines the type of line to use for connection preview during dragging.
//

import Foundation

/// Type of line to render for connection preview
public enum ConnectionLineType: Equatable, Sendable, Hashable, Codable {
    /// Bezier curve with curvature
    case bezier(curvature: CGFloat = 0.25)
    
    /// Smooth step (orthogonal) path
    case smoothStep(borderRadius: CGFloat = 8)
    
    /// Straight line
    case straight
    
    /// Use the same style as configured edges
    case inherit
    
    public static let `default`: ConnectionLineType = .bezier()
}

// MARK: - Conversion to EdgePathStyle

extension ConnectionLineType {
    /// Convert to EdgePathStyle for rendering
    public func toEdgePathStyle() -> EdgePathStyle {
        switch self {
        case .bezier(let curvature):
            return .bezier(curvature: curvature)
        case .smoothStep(let borderRadius):
            return .smoothStep(borderRadius: borderRadius)
        case .straight:
            return .straight
        case .inherit:
            return .default
        }
    }
}
