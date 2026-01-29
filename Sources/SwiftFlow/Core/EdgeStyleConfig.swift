//
//  EdgeStyleConfig.swift
//  SwiftFlow
//
//  Configuration for edge visual styling (color and width).
//

import SwiftUI

/// Configuration for edge visual styling
public struct EdgeStyleConfig: Codable, Equatable {
    /// Stroke color for the edge line
    public var strokeColor: Color
    
    /// Line width for the edge
    public var lineWidth: CGFloat
    
    /// Color when the edge is selected (optional, defaults to blue if nil)
    public var selectedColor: Color?
    
    public init(
        strokeColor: Color = Color.gray.opacity(0.6),
        lineWidth: CGFloat = 2.0,
        selectedColor: Color? = nil
    ) {
        self.strokeColor = strokeColor
        self.lineWidth = lineWidth
        self.selectedColor = selectedColor
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case lineWidth
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lineWidth = try container.decode(CGFloat.self, forKey: .lineWidth)
        // Colors can't be reliably encoded, use defaults
        strokeColor = Color.gray.opacity(0.6)
        selectedColor = nil
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lineWidth, forKey: .lineWidth)
    }
}
