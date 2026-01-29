//
//  PathCalculator.swift
//  SwiftFlow
//
//  Protocol for calculating edge paths between nodes.
//

import Foundation
import SwiftUI

/// Result of a path calculation containing the path and label position
public struct PathResult {
    /// The calculated path
    public let path: Path
    
    /// X position for placing a label on the edge
    public let labelX: CGFloat
    
    /// Y position for placing a label on the edge
    public let labelY: CGFloat
    
    /// Offset from source X to label X
    public let offsetX: CGFloat
    
    /// Offset from source Y to label Y
    public let offsetY: CGFloat
    
    public init(
        path: Path,
        labelX: CGFloat,
        labelY: CGFloat,
        offsetX: CGFloat,
        offsetY: CGFloat
    ) {
        self.path = path
        self.labelX = labelX
        self.labelY = labelY
        self.offsetX = offsetX
        self.offsetY = offsetY
    }
}

/// Protocol for calculating paths between two points with specific port positions
public protocol PathCalculator {
    /// Calculate the path between source and target points
    /// - Parameters:
    ///   - sourcePoint: Starting point of the path
    ///   - targetPoint: Ending point of the path
    ///   - sourcePosition: Position of the source port (determines initial direction)
    ///   - targetPosition: Position of the target port (determines final direction)
    /// - Returns: PathResult containing the calculated path and label position
    func calculatePath(
        from sourcePoint: CGPoint,
        to targetPoint: CGPoint,
        sourcePosition: PortPosition,
        targetPosition: PortPosition
    ) -> PathResult
}
