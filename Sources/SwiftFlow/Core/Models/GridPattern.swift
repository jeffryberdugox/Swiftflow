//
//  GridPattern.swift
//  SwiftFlow
//
//  Grid pattern styles for canvas background.
//

import Foundation

/// Visual pattern styles for canvas grid
public enum GridPattern: String, CaseIterable, Equatable, Sendable, Hashable, Codable {
    case dots        // Dots at grid intersections
    case lines       // Full grid lines (current default)
    case minimalist  // Subtle lines with reduced opacity
    case none        // No grid pattern visible
    
    public var displayName: String {
        switch self {
        case .dots: return "Dots"
        case .lines: return "Lines"
        case .minimalist: return "Minimalist"
        case .none: return "None"
        }
    }
    
    public var icon: String {
        switch self {
        case .dots: return "circle.grid.3x3"
        case .lines: return "square.grid.2x2"
        case .minimalist: return "square.dashed"
        case .none: return "eye.slash"
        }
    }
    
    public var description: String {
        switch self {
        case .dots: return "Dots at intersections"
        case .lines: return "Full grid lines"
        case .minimalist: return "Subtle minimal lines"
        case .none: return "No grid pattern"
        }
    }
}
