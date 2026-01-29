//
//  EdgeAccessoryConfig.swift
//  SwiftFlow
//
//  Configuration for edge accessory views (labels, buttons, custom content).
//

import Foundation
import CoreGraphics

/// Type of edge accessory to display
public enum EdgeAccessoryType: String, Codable, CaseIterable {
    case label = "Label"
    case button = "Button"
    case icon = "Icon"
    case custom = "Custom"
    case none = "None"
    
    public var displayName: String {
        return self.rawValue
    }
}

/// Visibility behavior for edge accessory
public enum EdgeAccessoryVisibility: String, Codable, CaseIterable {
    case hidden = "Hidden"
    case visible = "Always Visible"
    case hover = "On Hover"
    case conditional = "Conditional"
    
    public var displayName: String {
        return self.rawValue
    }
    
    public var description: String {
        switch self {
        case .hidden:
            return "Accessory is never shown"
        case .visible:
            return "Accessory is always visible"
        case .hover:
            return "Accessory appears only when hovering edge"
        case .conditional:
            return "Accessory visibility controlled by custom logic"
        }
    }
}

/// Configuration for edge accessory positioning and behavior
public struct EdgeAccessoryConfig: Equatable {
    /// Position along edge (0.0 = start, 0.5 = middle, 1.0 = end)
    public var position: CGFloat
    
    /// Additional offset from calculated position
    public var offset: CGPoint
    
    /// Visibility behavior
    public var visibility: EdgeAccessoryVisibility
    
    /// Hide accessory while dragging nodes
    public var hideOnDrag: Bool
    
    /// Enable smooth show/hide transitions
    public var animated: Bool
    
    public init(
        position: CGFloat = 0.5,
        offset: CGPoint = .zero,
        visibility: EdgeAccessoryVisibility = .visible,
        hideOnDrag: Bool = false,
        animated: Bool = true
    ) {
        self.position = max(0, min(1, position))
        self.offset = offset
        self.visibility = visibility
        self.hideOnDrag = hideOnDrag
        self.animated = animated
    }
    
    /// Default configuration (centered on edge, always visible)
    public static let `default` = EdgeAccessoryConfig()
}
