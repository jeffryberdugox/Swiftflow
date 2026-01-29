//
//  PortPositioning.swift
//  SwiftFlow
//
//  Port positioning system with presets and custom offsets.
//

import Foundation
import CoreGraphics

// MARK: - Port Preset

/// Preset positions for ports on a node.
/// Coordinates are in node-local space (relative to top-left corner).
public enum PortPreset: Codable, Sendable, Equatable, Hashable {
    case topLeft
    case topCenter
    case topRight
    case leftCenter
    case center
    case rightCenter
    case bottomLeft
    case bottomCenter
    case bottomRight
    case custom(CGPoint) // Direct offset from node top-left
    
    /// Calculate absolute position in node-local space given a node size.
    /// - Parameter nodeSize: The current size of the node
    /// - Returns: Position in node-local coordinates (0,0 = top-left corner)
    public func calculatePosition(nodeSize: CGSize) -> CGPoint {
        switch self {
        case .topLeft:
            return CGPoint(x: 0, y: 0)
        case .topCenter:
            return CGPoint(x: nodeSize.width / 2, y: 0)
        case .topRight:
            return CGPoint(x: nodeSize.width, y: 0)
        case .leftCenter:
            return CGPoint(x: 0, y: nodeSize.height / 2)
        case .center:
            return CGPoint(x: nodeSize.width / 2, y: nodeSize.height / 2)
        case .rightCenter:
            return CGPoint(x: nodeSize.width, y: nodeSize.height / 2)
        case .bottomLeft:
            return CGPoint(x: 0, y: nodeSize.height)
        case .bottomCenter:
            return CGPoint(x: nodeSize.width / 2, y: nodeSize.height)
        case .bottomRight:
            return CGPoint(x: nodeSize.width, y: nodeSize.height)
        case .custom(let point):
            return point
        }
    }
    
    // MARK: Codable Implementation for Enum with Associated Values
    
    private enum CodingKeys: String, CodingKey {
        case type
        case x
        case y
    }
    
    private enum PresetType: String, Codable {
        case topLeft, topCenter, topRight
        case leftCenter, center, rightCenter
        case bottomLeft, bottomCenter, bottomRight
        case custom
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(PresetType.self, forKey: .type)
        
        switch type {
        case .topLeft: self = .topLeft
        case .topCenter: self = .topCenter
        case .topRight: self = .topRight
        case .leftCenter: self = .leftCenter
        case .center: self = .center
        case .rightCenter: self = .rightCenter
        case .bottomLeft: self = .bottomLeft
        case .bottomCenter: self = .bottomCenter
        case .bottomRight: self = .bottomRight
        case .custom:
            let x = try container.decode(CGFloat.self, forKey: .x)
            let y = try container.decode(CGFloat.self, forKey: .y)
            self = .custom(CGPoint(x: x, y: y))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .topLeft:
            try container.encode(PresetType.topLeft, forKey: .type)
        case .topCenter:
            try container.encode(PresetType.topCenter, forKey: .type)
        case .topRight:
            try container.encode(PresetType.topRight, forKey: .type)
        case .leftCenter:
            try container.encode(PresetType.leftCenter, forKey: .type)
        case .center:
            try container.encode(PresetType.center, forKey: .type)
        case .rightCenter:
            try container.encode(PresetType.rightCenter, forKey: .type)
        case .bottomLeft:
            try container.encode(PresetType.bottomLeft, forKey: .type)
        case .bottomCenter:
            try container.encode(PresetType.bottomCenter, forKey: .type)
        case .bottomRight:
            try container.encode(PresetType.bottomRight, forKey: .type)
        case .custom(let point):
            try container.encode(PresetType.custom, forKey: .type)
            try container.encode(point.x, forKey: .x)
            try container.encode(point.y, forKey: .y)
        }
    }
}

// MARK: - Port Layout

/// Defines the complete layout of a port including preset position and custom offset.
/// Positions are always in node-local space (relative to node's top-left corner).
public struct PortLayout: Codable, Sendable, Equatable, Hashable {
    /// The preset position (adapts to node size changes)
    public var preset: PortPreset
    
    /// Additional offset from the preset position
    public var offset: CGPoint
    
    /// Create a port layout with a preset and optional offset.
    /// - Parameters:
    ///   - preset: The base preset position
    ///   - offset: Additional offset to apply (default: zero)
    public init(preset: PortPreset, offset: CGPoint = .zero) {
        self.preset = preset
        self.offset = offset
    }
    
    /// Calculate final position in node-local space.
    /// - Parameter nodeSize: The current size of the node
    /// - Returns: Final position relative to node's top-left corner
    public func position(nodeSize: CGSize) -> CGPoint {
        let base = preset.calculatePosition(nodeSize: nodeSize)
        return CGPoint(
            x: base.x + offset.x,
            y: base.y + offset.y
        )
    }
    
    // MARK: Convenience Initializers
    
    /// Create a layout with just an offset (equivalent to .custom(offset))
    public static func custom(_ offset: CGPoint) -> PortLayout {
        return PortLayout(preset: .custom(offset), offset: .zero)
    }
    
    /// Create a layout for the left center with optional vertical offset
    public static func leftCenter(offsetY: CGFloat = 0) -> PortLayout {
        return PortLayout(preset: .leftCenter, offset: CGPoint(x: 0, y: offsetY))
    }
    
    /// Create a layout for the right center with optional vertical offset
    public static func rightCenter(offsetY: CGFloat = 0) -> PortLayout {
        return PortLayout(preset: .rightCenter, offset: CGPoint(x: 0, y: offsetY))
    }
    
    /// Create a layout for the top center with optional horizontal offset
    public static func topCenter(offsetX: CGFloat = 0) -> PortLayout {
        return PortLayout(preset: .topCenter, offset: CGPoint(x: offsetX, y: 0))
    }
    
    /// Create a layout for the bottom center with optional horizontal offset
    public static func bottomCenter(offsetX: CGFloat = 0) -> PortLayout {
        return PortLayout(preset: .bottomCenter, offset: CGPoint(x: offsetX, y: 0))
    }
}

// MARK: - Default Layouts based on PortPosition

public extension PortLayout {
    /// Get default layout for a given PortPosition (for backward compatibility).
    /// Maps the old PortPosition enum to a PortLayout preset.
    /// - Parameter position: The legacy port position
    /// - Returns: Corresponding port layout
    static func `default`(for position: PortPosition) -> PortLayout {
        switch position {
        case .left:
            return PortLayout(preset: .leftCenter)
        case .right:
            return PortLayout(preset: .rightCenter)
        case .top:
            return PortLayout(preset: .topCenter)
        case .bottom:
            return PortLayout(preset: .bottomCenter)
        }
    }
}
