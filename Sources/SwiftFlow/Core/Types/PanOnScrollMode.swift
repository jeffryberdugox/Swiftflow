//
//  PanOnScrollMode.swift
//  SwiftFlow
//
//  Defines how scrolling behavior affects the canvas.
//

import Foundation

/// Scroll behavior mode
public enum PanOnScrollMode: Equatable, Sendable, Hashable, Codable {
    /// Scroll to zoom (default)
    case zoom
    
    /// Scroll to pan horizontally
    case horizontal
    
    /// Scroll to pan vertically
    case vertical
    
    /// Scroll to pan in both directions
    case free
    
    public static let `default`: PanOnScrollMode = .zoom
}
