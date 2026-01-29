//
//  AutoPan.swift
//  SwiftFlow
//
//  Utilities for auto-panning when dragging near canvas edges.
//

import Foundation
import CoreGraphics

/// Calculate auto-pan velocity based on cursor position relative to viewport bounds
/// - Parameters:
///   - position: Current cursor position in screen coordinates
///   - bounds: Viewport bounds
///   - speed: Maximum pan speed (pixels per frame)
///   - threshold: Distance from edge to start panning
/// - Returns: Pan velocity as (x, y) tuple
public func calculateAutoPan(
    position: CGPoint,
    bounds: CGSize,
    speed: CGFloat = 15,
    threshold: CGFloat = 40
) -> (x: CGFloat, y: CGFloat) {
    let xMovement = calculateAutoPanVelocity(
        value: position.x,
        min: threshold,
        max: bounds.width - threshold,
        speed: speed
    )
    
    let yMovement = calculateAutoPanVelocity(
        value: position.y,
        min: threshold,
        max: bounds.height - threshold,
        speed: speed
    )
    
    return (xMovement, yMovement)
}

/// Calculate velocity for a single axis
/// - Parameters:
///   - value: Current position on axis
///   - min: Minimum position before panning starts
///   - max: Maximum position before panning starts
///   - speed: Maximum pan speed
/// - Returns: Velocity (negative = pan left/up, positive = pan right/down)
private func calculateAutoPanVelocity(
    value: CGFloat,
    min: CGFloat,
    max: CGFloat,
    speed: CGFloat
) -> CGFloat {
    if value < min {
        // Near left/top edge - pan in negative direction
        let factor = clamp((min - value) / min, min: 0, max: 1)
        return -factor * speed
    } else if value > max {
        // Near right/bottom edge - pan in positive direction
        let factor = clamp((value - max) / min, min: 0, max: 1)
        return factor * speed
    }
    return 0
}

/// Check if auto-pan should be active
/// - Parameters:
///   - position: Current cursor position
///   - bounds: Viewport bounds
///   - threshold: Distance from edge threshold
/// - Returns: True if position is in auto-pan zone
public func isInAutoPanZone(
    position: CGPoint,
    bounds: CGSize,
    threshold: CGFloat = 40
) -> Bool {
    return position.x < threshold ||
           position.x > bounds.width - threshold ||
           position.y < threshold ||
           position.y > bounds.height - threshold
}
