//
//  EdgeHoverManager.swift
//  SwiftFlow
//
//  Centralized manager for edge hover state
//

import Foundation
import SwiftUI

/// Manages hover state for edges across the canvas
@MainActor
public class EdgeHoverManager: ObservableObject {
    /// The ID of the currently hovered edge, if any
    @Published public private(set) var hoveredEdgeId: UUID?
    
    public init() {}
    
    /// Set which edge is currently being hovered
    /// - Parameter edgeId: ID of the edge being hovered, or nil to clear hover
    public func setHoveredEdge(_ edgeId: UUID?) {
        hoveredEdgeId = edgeId
    }
    
    /// Check if a specific edge is currently hovered
    /// - Parameter edgeId: ID of the edge to check
    /// - Returns: true if this edge is the currently hovered edge
    public func isEdgeHovered(_ edgeId: UUID) -> Bool {
        return hoveredEdgeId == edgeId
    }
    
    /// Clear all hover state
    public func clearHover() {
        hoveredEdgeId = nil
    }
}
