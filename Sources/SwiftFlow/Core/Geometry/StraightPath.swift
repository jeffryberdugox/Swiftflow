//
//  StraightPath.swift
//  SwiftFlow
//
//  Straight line path calculator for direct edge connections.
//

import Foundation
import SwiftUI

/// Calculates straight line paths between ports
public struct StraightPathCalculator: PathCalculator {
    public init() {}
    
    public func calculatePath(
        from sourcePoint: CGPoint,
        to targetPoint: CGPoint,
        sourcePosition: PortPosition,
        targetPosition: PortPosition
    ) -> PathResult {
        let sourceX = sourcePoint.x
        let sourceY = sourcePoint.y
        let targetX = targetPoint.x
        let targetY = targetPoint.y
        
        // Calculate center point
        let (labelX, labelY, offsetX, offsetY) = getEdgeCenter(
            sourceX: sourceX,
            sourceY: sourceY,
            targetX: targetX,
            targetY: targetY
        )
        
        // Build simple line path
        var path = Path()
        path.move(to: CGPoint(x: sourceX, y: sourceY))
        path.addLine(to: CGPoint(x: targetX, y: targetY))
        
        return PathResult(
            path: path,
            labelX: labelX,
            labelY: labelY,
            offsetX: offsetX,
            offsetY: offsetY
        )
    }
}

// MARK: - Helper Functions

/// Calculate the center point of a straight edge
func getEdgeCenter(
    sourceX: CGFloat,
    sourceY: CGFloat,
    targetX: CGFloat,
    targetY: CGFloat
) -> (centerX: CGFloat, centerY: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
    let xOffset = abs(targetX - sourceX) / 2
    let centerX = targetX < sourceX ? targetX + xOffset : targetX - xOffset
    
    let yOffset = abs(targetY - sourceY) / 2
    let centerY = targetY < sourceY ? targetY + yOffset : targetY - yOffset
    
    return (centerX, centerY, xOffset, yOffset)
}
