//
//  ResizeControlVariant.swift
//  SwiftFlow
//
//  Defines which resize controls are available on nodes.
//

import Foundation

/// Resize control variant
public enum ResizeControlVariant: Equatable, Sendable, Hashable, Codable {
    /// Single handle at bottom-right (default)
    case handle
    
    /// Handles on all four corners
    case corners
    
    /// Handles on all edges (4 corners + 4 edges)
    case edges
    
    /// No resize controls
    case none
    
    public static let `default`: ResizeControlVariant = .handle
}

/// Position of a resize control relative to node
public enum ResizeControlPosition: String, Equatable, Sendable, Hashable, Codable, CaseIterable {
    case topLeft
    case top
    case topRight
    case right
    case bottomRight
    case bottom
    case bottomLeft
    case left
    
    /// Convert to ResizeAnchor (opposite corner/edge stays fixed)
    public var anchor: ResizeAnchor {
        switch self {
        case .topLeft:
            return .bottomRight
        case .top:
            return .bottom
        case .topRight:
            return .bottomLeft
        case .right:
            return .left
        case .bottomRight:
            return .topLeft
        case .bottom:
            return .top
        case .bottomLeft:
            return .topRight
        case .left:
            return .right
        }
    }
}
