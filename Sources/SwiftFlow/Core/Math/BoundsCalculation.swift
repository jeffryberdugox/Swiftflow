//
//  BoundsCalculation.swift
//  SwiftFlow
//
//  Utilities for calculating bounds and working with rectangles.
//  All calculations work in Canvas space where node.position is the top-left corner.
//

import Foundation
import CoreGraphics

// MARK: - Coordinate System Note

/*
 All bounds calculations in this file work in **Canvas Space**:
 - node.position is the **top-left corner** of the node
 - node.bounds is the full rectangle from (position.x, position.y) to (position.x + width, position.y + height)
 - All CGRect and CGPoint values are in canvas coordinates (logical world space)
 
 These calculations are independent of viewport transforms (pan/zoom).
 */

// MARK: - Bounds Calculation

/// Calculate the bounding rectangle that contains all given nodes
/// - Parameter nodes: Array of nodes to calculate bounds for
/// - Returns: Bounding rectangle or nil if no nodes provided
public func calculateNodesBounds<Node: FlowNode>(_ nodes: [Node]) -> CGRect? {
    guard !nodes.isEmpty else { return nil }
    
    var minX = CGFloat.infinity
    var minY = CGFloat.infinity
    var maxX = -CGFloat.infinity
    var maxY = -CGFloat.infinity
    
    for node in nodes {
        let bounds = node.bounds
        minX = min(minX, bounds.minX)
        minY = min(minY, bounds.minY)
        maxX = max(maxX, bounds.maxX)
        maxY = max(maxY, bounds.maxY)
    }
    
    return CGRect(
        x: minX,
        y: minY,
        width: maxX - minX,
        height: maxY - minY
    )
}

/// Calculate the bounding rectangle for specific node IDs
/// - Parameters:
///   - nodeIds: Set of node IDs to include
///   - nodes: All available nodes
/// - Returns: Bounding rectangle or nil if no matching nodes
public func calculateNodesBounds<Node: FlowNode>(
    for nodeIds: Set<UUID>,
    in nodes: [Node]
) -> CGRect? {
    let selectedNodes = nodes.filter { nodeIds.contains($0.id) }
    return calculateNodesBounds(selectedNodes)
}

// MARK: - Rectangle Utilities

/// Convert a rectangle to a box representation
public struct Box: Equatable, Sendable {
    public var x: CGFloat
    public var y: CGFloat
    public var x2: CGFloat
    public var y2: CGFloat
    
    public init(x: CGFloat, y: CGFloat, x2: CGFloat, y2: CGFloat) {
        self.x = x
        self.y = y
        self.x2 = x2
        self.y2 = y2
    }
    
    public init(rect: CGRect) {
        self.x = rect.minX
        self.y = rect.minY
        self.x2 = rect.maxX
        self.y2 = rect.maxY
    }
    
    public var rect: CGRect {
        CGRect(x: x, y: y, width: x2 - x, height: y2 - y)
    }
    
    public var width: CGFloat { x2 - x }
    public var height: CGFloat { y2 - y }
}

/// Get the combined bounds of two boxes
public func getBoundsOfBoxes(_ box1: Box, _ box2: Box) -> Box {
    return Box(
        x: min(box1.x, box2.x),
        y: min(box1.y, box2.y),
        x2: max(box1.x2, box2.x2),
        y2: max(box1.y2, box2.y2)
    )
}

/// Get the combined bounds of two rectangles
public func getBoundsOfRects(_ rect1: CGRect, _ rect2: CGRect) -> CGRect {
    let box1 = Box(rect: rect1)
    let box2 = Box(rect: rect2)
    return getBoundsOfBoxes(box1, box2).rect
}

/// Calculate the overlapping area of two rectangles
/// - Returns: Area of overlap, or 0 if no overlap
public func getOverlappingArea(_ rectA: CGRect, _ rectB: CGRect) -> CGFloat {
    let xOverlap = max(0, min(rectA.maxX, rectB.maxX) - max(rectA.minX, rectB.minX))
    let yOverlap = max(0, min(rectA.maxY, rectB.maxY) - max(rectA.minY, rectB.minY))
    return xOverlap * yOverlap
}

/// Check if two rectangles intersect
public func rectsIntersect(_ rect1: CGRect, _ rect2: CGRect) -> Bool {
    return rect1.intersects(rect2)
}

/// Check if a point is inside a rectangle
public func pointInRect(_ point: CGPoint, _ rect: CGRect) -> Bool {
    return rect.contains(point)
}

// MARK: - Viewport Calculation

/// Calculate the transform needed to fit bounds within a viewport
/// - Parameters:
///   - bounds: Content bounds to fit
///   - viewportSize: Size of the viewport
///   - padding: Padding around the content
///   - minZoom: Minimum allowed zoom
///   - maxZoom: Maximum allowed zoom
/// - Returns: Transform that fits the content in the viewport
public func getViewportForBounds(
    bounds: CGRect,
    viewportSize: CGSize,
    padding: CGFloat = 50,
    minZoom: CGFloat = 0.1,
    maxZoom: CGFloat = 4.0
) -> FlowTransform {
    guard bounds.width > 0, bounds.height > 0 else {
        return .identity
    }
    
    let paddedWidth = viewportSize.width - padding * 2
    let paddedHeight = viewportSize.height - padding * 2
    
    let xZoom = paddedWidth / bounds.width
    let yZoom = paddedHeight / bounds.height
    
    var zoom = min(xZoom, yZoom)
    zoom = max(minZoom, min(maxZoom, zoom))
    
    // Calculate center of bounds
    let boundsCenterX = bounds.midX
    let boundsCenterY = bounds.midY
    
    // Calculate offset to center the content
    let offsetX = viewportSize.width / 2 - boundsCenterX * zoom
    let offsetY = viewportSize.height / 2 - boundsCenterY * zoom

    return FlowTransform(
        offset: CGPoint(x: offsetX, y: offsetY),
        scale: zoom
    )
}

// MARK: - Clamp Utilities

/// Clamp a value between min and max
public func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
    return max(minValue, min(maxValue, value))
}

/// Clamp a point within a coordinate extent
public func clampPosition(
    _ position: CGPoint,
    extent: (min: CGPoint, max: CGPoint),
    nodeSize: CGSize = .zero
) -> CGPoint {
    return CGPoint(
        x: clamp(position.x, min: extent.min.x, max: extent.max.x - nodeSize.width),
        y: clamp(position.y, min: extent.min.y, max: extent.max.y - nodeSize.height)
    )
}
