//
//  BezierPath.swift
//  SwiftFlow
//
//  Bezier curve path calculator for smooth edge connections.
//

import Foundation
import SwiftUI

/// Calculates smooth bezier curve paths between ports
public struct BezierPathCalculator: PathCalculator {
    /// Curvature factor (0.0 to 1.0, default 0.25)
    public var curvature: CGFloat
    
    public init(curvature: CGFloat = 0.25) {
        self.curvature = curvature
    }
    
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
        
        // Calculate control points with curvature
        let (sourceControlX, sourceControlY) = getControlWithCurvature(
            position: sourcePosition,
            x1: sourceX,
            y1: sourceY,
            x2: targetX,
            y2: targetY,
            curvature: curvature
        )
        
        let (targetControlX, targetControlY) = getControlWithCurvature(
            position: targetPosition,
            x1: targetX,
            y1: targetY,
            x2: sourceX,
            y2: sourceY,
            curvature: curvature
        )
        
        // Calculate center point for label placement
        let (labelX, labelY, offsetX, offsetY) = getBezierEdgeCenter(
            sourceX: sourceX,
            sourceY: sourceY,
            targetX: targetX,
            targetY: targetY,
            sourceControlX: sourceControlX,
            sourceControlY: sourceControlY,
            targetControlX: targetControlX,
            targetControlY: targetControlY
        )
        
        // Build the path
        var path = Path()
        path.move(to: CGPoint(x: sourceX, y: sourceY))
        path.addCurve(
            to: CGPoint(x: targetX, y: targetY),
            control1: CGPoint(x: sourceControlX, y: sourceControlY),
            control2: CGPoint(x: targetControlX, y: targetControlY)
        )
        
        return PathResult(
            path: path,
            labelX: labelX,
            labelY: labelY,
            offsetX: offsetX,
            offsetY: offsetY
        )
    }
}

// MARK: - Private Helper Functions

/// Calculate control offset based on distance and curvature
private func calculateControlOffset(distance: CGFloat, curvature: CGFloat) -> CGFloat {
    if distance >= 0 {
        return 0.5 * distance
    }
    return curvature * 25 * sqrt(-distance)
}

/// Get control point with curvature applied
private func getControlWithCurvature(
    position: PortPosition,
    x1: CGFloat,
    y1: CGFloat,
    x2: CGFloat,
    y2: CGFloat,
    curvature: CGFloat
) -> (CGFloat, CGFloat) {
    switch position {
    case .left:
        return (x1 - calculateControlOffset(distance: x1 - x2, curvature: curvature), y1)
    case .right:
        return (x1 + calculateControlOffset(distance: x2 - x1, curvature: curvature), y1)
    case .top:
        return (x1, y1 - calculateControlOffset(distance: y1 - y2, curvature: curvature))
    case .bottom:
        return (x1, y1 + calculateControlOffset(distance: y2 - y1, curvature: curvature))
    }
}

/// Calculate the center of a bezier curve for label placement
/// Uses t=0.5 approximation for cubic bezier
private func getBezierEdgeCenter(
    sourceX: CGFloat,
    sourceY: CGFloat,
    targetX: CGFloat,
    targetY: CGFloat,
    sourceControlX: CGFloat,
    sourceControlY: CGFloat,
    targetControlX: CGFloat,
    targetControlY: CGFloat
) -> (centerX: CGFloat, centerY: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
    // Cubic bezier t=0.5 mid point approximation
    let centerX = sourceX * 0.125 + sourceControlX * 0.375 + targetControlX * 0.375 + targetX * 0.125
    let centerY = sourceY * 0.125 + sourceControlY * 0.375 + targetControlY * 0.375 + targetY * 0.125
    let offsetX = abs(centerX - sourceX)
    let offsetY = abs(centerY - sourceY)
    
    return (centerX, centerY, offsetX, offsetY)
}
