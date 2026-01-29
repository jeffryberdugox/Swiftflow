//
//  PublicHelpers.swift
//  SwiftFlow
//
//  Public utility functions for geometric calculations and node/edge operations.
//  Provides reactive API surface for public helpers.
//

import Foundation
import SwiftUI

// MARK: - Path Calculation Helpers

/// Calculate a bezier path between two points
/// - Parameters:
///   - sourceX: Source X coordinate
///   - sourceY: Source Y coordinate
///   - targetX: Target X coordinate
///   - targetY: Target Y coordinate
///   - sourcePosition: Source port position
///   - targetPosition: Target port position
///   - curvature: Curvature factor (0.0 to 1.0, default 0.25)
/// - Returns: Path result with path and label position
public func getBezierPath(
    sourceX: CGFloat,
    sourceY: CGFloat,
    targetX: CGFloat,
    targetY: CGFloat,
    sourcePosition: PortPosition = .right,
    targetPosition: PortPosition = .left,
    curvature: CGFloat = 0.25
) -> PathResult {
    let calculator = BezierPathCalculator(curvature: curvature)
    return calculator.calculatePath(
        from: CGPoint(x: sourceX, y: sourceY),
        to: CGPoint(x: targetX, y: targetY),
        sourcePosition: sourcePosition,
        targetPosition: targetPosition
    )
}

/// Calculate a smooth step (orthogonal) path between two points
/// - Parameters:
///   - sourceX: Source X coordinate
///   - sourceY: Source Y coordinate
///   - targetX: Target X coordinate
///   - targetY: Target Y coordinate
///   - sourcePosition: Source port position
///   - targetPosition: Target port position
///   - borderRadius: Corner radius (default 8)
/// - Returns: Path result with path and label position
public func getSmoothStepPath(
    sourceX: CGFloat,
    sourceY: CGFloat,
    targetX: CGFloat,
    targetY: CGFloat,
    sourcePosition: PortPosition = .right,
    targetPosition: PortPosition = .left,
    borderRadius: CGFloat = 8
) -> PathResult {
    let calculator = SmoothStepPathCalculator(borderRadius: borderRadius)
    return calculator.calculatePath(
        from: CGPoint(x: sourceX, y: sourceY),
        to: CGPoint(x: targetX, y: targetY),
        sourcePosition: sourcePosition,
        targetPosition: targetPosition
    )
}

/// Calculate a straight line path between two points
/// - Parameters:
///   - sourceX: Source X coordinate
///   - sourceY: Source Y coordinate
///   - targetX: Target X coordinate
///   - targetY: Target Y coordinate
/// - Returns: Path result with path and label position
public func getStraightPath(
    sourceX: CGFloat,
    sourceY: CGFloat,
    targetX: CGFloat,
    targetY: CGFloat
) -> PathResult {
    let calculator = StraightPathCalculator()
    return calculator.calculatePath(
        from: CGPoint(x: sourceX, y: sourceY),
        to: CGPoint(x: targetX, y: targetY),
        sourcePosition: .right,
        targetPosition: .left
    )
}

/// Calculate the center point of a bezier edge for label placement
/// - Parameters:
///   - sourceX: Source X coordinate
///   - sourceY: Source Y coordinate
///   - sourceControlX: Source control point X
///   - sourceControlY: Source control point Y
///   - targetX: Target X coordinate
///   - targetY: Target Y coordinate
///   - targetControlX: Target control point X
///   - targetControlY: Target control point Y
/// - Returns: Tuple with center coordinates and offsets
public func getBezierEdgeCenter(
    sourceX: CGFloat,
    sourceY: CGFloat,
    sourceControlX: CGFloat,
    sourceControlY: CGFloat,
    targetX: CGFloat,
    targetY: CGFloat,
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

/// Calculate the center point of a straight edge for label placement
/// - Parameters:
///   - sourceX: Source X coordinate
///   - sourceY: Source Y coordinate
///   - targetX: Target X coordinate
///   - targetY: Target Y coordinate
/// - Returns: Tuple with center coordinates
public func getSimpleEdgeCenter(
    sourceX: CGFloat,
    sourceY: CGFloat,
    targetX: CGFloat,
    targetY: CGFloat
) -> (centerX: CGFloat, centerY: CGFloat) {
    let centerX = (sourceX + targetX) / 2
    let centerY = (sourceY + targetY) / 2
    return (centerX, centerY)
}

// MARK: - Bounds Calculation Helpers

/// Get the bounding rectangle of an array of nodes
/// - Parameter nodes: Array of nodes
/// - Returns: Bounding rectangle in canvas coordinates, or nil if no nodes
public func getRectOfNodes<Node: FlowNode>(_ nodes: [Node]) -> CGRect? {
    return calculateNodesBounds(nodes)
}

/// Calculate the transform needed to fit bounds within a viewport
/// - Parameters:
///   - bounds: Content bounds to fit
///   - viewportSize: Size of the viewport
///   - minZoom: Minimum zoom level
///   - maxZoom: Maximum zoom level
///   - padding: Padding around content (default 50)
/// - Returns: Transform with offset and scale
public func getTransformForBounds(
    bounds: CGRect,
    viewportSize: CGSize,
    minZoom: CGFloat,
    maxZoom: CGFloat,
    padding: CGFloat = 50
) -> FlowTransform {
    return getViewportForBounds(
        bounds: bounds,
        viewportSize: viewportSize,
        padding: padding,
        minZoom: minZoom,
        maxZoom: maxZoom
    )
}

// MARK: - Node Query Helpers

/// Get nodes that are completely or partially inside a rectangular area
/// - Parameters:
///   - rect: Selection rectangle
///   - nodes: Array of nodes to check
///   - partially: Whether to include partially intersecting nodes (default true)
/// - Returns: Array of nodes within the rectangle
public func getNodesInside<Node: FlowNode>(
    rect: CGRect,
    nodes: [Node],
    partially: Bool = true
) -> [Node] {
    return getNodesInRect(rect: rect, nodes: nodes, partially: partially)
}

/// Check if an edge connection already exists
/// - Parameters:
///   - connection: Connection to check
///   - edges: Existing edges
/// - Returns: True if connection exists
public func connectionExists(
    sourceNode: UUID,
    sourcePort: UUID,
    targetNode: UUID,
    targetPort: UUID,
    edges: [any FlowEdge]
) -> Bool {
    return edges.contains { edge in
        edge.sourceNodeId == sourceNode &&
        edge.sourcePortId == sourcePort &&
        edge.targetNodeId == targetNode &&
        edge.targetPortId == targetPort
    }
}

// MARK: - Coordinate Conversion Helpers

/// Convert a screen point to canvas coordinates using a transform
/// - Parameters:
///   - point: Point in screen coordinates
///   - transform: Current transform (offset and scale)
/// - Returns: Point in canvas coordinates
public func screenToCanvas(
    point: CGPoint,
    transform: FlowTransform
) -> CGPoint {
    return transform.screenToCanvas(point)
}

/// Convert a canvas point to screen coordinates using a transform
/// - Parameters:
///   - point: Point in canvas coordinates
///   - transform: Current transform (offset and scale)
/// - Returns: Point in screen coordinates
public func canvasToScreen(
    point: CGPoint,
    transform: FlowTransform
) -> CGPoint {
    return transform.canvasToScreen(point)
}

// MARK: - Utility Helpers

/// Clamp a value between min and max
/// - Parameters:
///   - value: Value to clamp
///   - min: Minimum value
///   - max: Maximum value
/// - Returns: Clamped value
public func clamp<T: Comparable>(_ value: T, min minValue: T, max maxValue: T) -> T {
    return max(minValue, min(maxValue, value))
}

/// Calculate the distance between two points
/// - Parameters:
///   - p1: First point
///   - p2: Second point
/// - Returns: Distance between points
public func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
    let dx = p2.x - p1.x
    let dy = p2.y - p1.y
    return sqrt(dx * dx + dy * dy)
}

/// Check if a point is near a line segment
/// - Parameters:
///   - point: Point to check
///   - lineStart: Start of line segment
///   - lineEnd: End of line segment
///   - threshold: Distance threshold (default 10)
/// - Returns: True if point is within threshold of line
public func isPointNearLine(
    point: CGPoint,
    lineStart: CGPoint,
    lineEnd: CGPoint,
    threshold: CGFloat = 10
) -> Bool {
    let dx = lineEnd.x - lineStart.x
    let dy = lineEnd.y - lineStart.y
    let length = sqrt(dx * dx + dy * dy)
    
    guard length > 0 else { return false }
    
    let dot = ((point.x - lineStart.x) * dx + (point.y - lineStart.y) * dy) / (length * length)
    let closestX = lineStart.x + dot * dx
    let closestY = lineStart.y + dot * dy
    
    let dist = distance(point, CGPoint(x: closestX, y: closestY))
    return dist <= threshold
}
