//
//  SmoothStepPath.swift
//  SwiftFlow
//
//  Smooth step (orthogonal with rounded corners) path calculator.
//

import Foundation
import SwiftUI

/// Calculates orthogonal paths with rounded corners between ports
public struct SmoothStepPathCalculator: PathCalculator {
    /// Radius for rounded corners
    public var borderRadius: CGFloat
    
    /// Offset from port before first turn
    public var offset: CGFloat
    
    /// Position of the step bend (0 = at source, 1 = at target, 0.5 = midpoint)
    public var stepPosition: CGFloat
    
    public init(
        borderRadius: CGFloat = 5,
        offset: CGFloat = 20,
        stepPosition: CGFloat = 0.5
    ) {
        self.borderRadius = borderRadius
        self.offset = offset
        self.stepPosition = stepPosition
    }
    
    public func calculatePath(
        from sourcePoint: CGPoint,
        to targetPoint: CGPoint,
        sourcePosition: PortPosition,
        targetPosition: PortPosition
    ) -> PathResult {
        let source = sourcePoint
        let target = targetPoint
        
        // Get direction vectors for source and target handles
        let sourceDir = handleDirections[sourcePosition]!
        let targetDir = handleDirections[targetPosition]!
        
        // Calculate gapped positions (offset from port)
        let sourceGapped = CGPoint(
            x: source.x + sourceDir.x * offset,
            y: source.y + sourceDir.y * offset
        )
        let targetGapped = CGPoint(
            x: target.x + targetDir.x * offset,
            y: target.y + targetDir.y * offset
        )
        
        // Calculate path points
        let (points, labelX, labelY) = calculateStepPoints(
            source: source,
            sourceGapped: sourceGapped,
            target: target,
            targetGapped: targetGapped,
            sourcePosition: sourcePosition,
            targetPosition: targetPosition,
            sourceDir: sourceDir,
            targetDir: targetDir
        )
        
        // Build path with rounded corners
        let path = buildPathWithBends(points: points, bendSize: borderRadius)
        
        let offsetX = abs(labelX - source.x)
        let offsetY = abs(labelY - source.y)
        
        return PathResult(
            path: path,
            labelX: labelX,
            labelY: labelY,
            offsetX: offsetX,
            offsetY: offsetY
        )
    }
}

// MARK: - Private Helpers

private let handleDirections: [PortPosition: CGPoint] = [
    .left: CGPoint(x: -1, y: 0),
    .right: CGPoint(x: 1, y: 0),
    .top: CGPoint(x: 0, y: -1),
    .bottom: CGPoint(x: 0, y: 1)
]

/// Calculate the routing points for step path
private func calculateStepPoints(
    source: CGPoint,
    sourceGapped: CGPoint,
    target: CGPoint,
    targetGapped: CGPoint,
    sourcePosition: PortPosition,
    targetPosition: PortPosition,
    sourceDir: CGPoint,
    targetDir: CGPoint
) -> (points: [CGPoint], labelX: CGFloat, labelY: CGFloat) {
    var points: [CGPoint] = []
    
    // Determine primary direction
    let isHorizontal = sourcePosition.isHorizontal
    
    // Calculate center based on step position
    let centerX: CGFloat
    let centerY: CGFloat
    
    if isHorizontal {
        centerX = sourceGapped.x + (targetGapped.x - sourceGapped.x) * 0.5
        centerY = (sourceGapped.y + targetGapped.y) / 2
    } else {
        centerX = (sourceGapped.x + targetGapped.x) / 2
        centerY = sourceGapped.y + (targetGapped.y - sourceGapped.y) * 0.5
    }
    
    // Check if handles are opposite
    let areOpposite = (sourceDir.x * targetDir.x + sourceDir.y * targetDir.y) == -1
    
    if areOpposite {
        // Standard opposite handles case
        if isHorizontal {
            points = [
                CGPoint(x: centerX, y: sourceGapped.y),
                CGPoint(x: centerX, y: targetGapped.y)
            ]
        } else {
            points = [
                CGPoint(x: sourceGapped.x, y: centerY),
                CGPoint(x: targetGapped.x, y: centerY)
            ]
        }
    } else {
        // Same side or perpendicular handles
        if isHorizontal {
            points = [CGPoint(x: sourceGapped.x, y: targetGapped.y)]
        } else {
            points = [CGPoint(x: targetGapped.x, y: sourceGapped.y)]
        }
    }
    
    // Build full path points
    let allPoints = [source, sourceGapped] + points + [targetGapped, target]
    
    return (allPoints, centerX, centerY)
}

/// Build path with rounded corners at bends
private func buildPathWithBends(points: [CGPoint], bendSize: CGFloat) -> Path {
    var path = Path()
    
    guard points.count >= 2 else { return path }
    
    path.move(to: points[0])
    
    for i in 1..<points.count {
        if i < points.count - 1 {
            // Calculate bend
            let prev = points[i - 1]
            let curr = points[i]
            let next = points[i + 1]
            
            let bendPath = calculateBend(a: prev, b: curr, c: next, size: bendSize)
            path.addPath(bendPath)
        } else {
            // Last point - just line to it
            path.addLine(to: points[i])
        }
    }
    
    return path
}

/// Calculate bend path for a corner
private func calculateBend(a: CGPoint, b: CGPoint, c: CGPoint, size: CGFloat) -> Path {
    var path = Path()
    
    let distAB = pointDistance(a, b)
    let distBC = pointDistance(b, c)
    let bendSize = min(distAB / 2, distBC / 2, size)
    
    // Check if no bend needed (straight line)
    if (a.x == b.x && b.x == c.x) || (a.y == b.y && b.y == c.y) {
        path.addLine(to: b)
        return path
    }
    
    // Calculate bend start and end points
    if a.y == b.y {
        // First segment is horizontal
        let xDir: CGFloat = a.x < c.x ? -1 : 1
        let yDir: CGFloat = a.y < c.y ? 1 : -1
        
        let bendStart = CGPoint(x: b.x + bendSize * xDir, y: b.y)
        let bendEnd = CGPoint(x: b.x, y: b.y + bendSize * yDir)
        
        path.addLine(to: bendStart)
        path.addQuadCurve(to: bendEnd, control: b)
    } else {
        // First segment is vertical
        let xDir: CGFloat = a.x < c.x ? 1 : -1
        let yDir: CGFloat = a.y < c.y ? -1 : 1
        
        let bendStart = CGPoint(x: b.x, y: b.y + bendSize * yDir)
        let bendEnd = CGPoint(x: b.x + bendSize * xDir, y: b.y)
        
        path.addLine(to: bendStart)
        path.addQuadCurve(to: bendEnd, control: b)
    }
    
    return path
}

/// Calculate distance between two points
private func pointDistance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
    return sqrt(pow(b.x - a.x, 2) + pow(b.y - a.y, 2))
}
