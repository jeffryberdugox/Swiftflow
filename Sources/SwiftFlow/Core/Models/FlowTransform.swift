//
//  FlowTransform.swift
//  SwiftFlow
//
//  Represents the transformation state of the canvas (pan offset and zoom scale).
//

import Foundation
import CoreGraphics

/// Represents the transformation state of the canvas.
/// Contains offset (pan) and scale (zoom) values.
public struct FlowTransform: Equatable, Sendable {
    /// Pan offset in screen coordinates
    public var offset: CGPoint
    
    /// Zoom scale factor (1.0 = 100%)
    public var scale: CGFloat
    
    /// Identity transform (no offset, scale = 1.0)
    public static let identity = FlowTransform(offset: .zero, scale: 1.0)
    
    public init(offset: CGPoint = .zero, scale: CGFloat = 1.0) {
        self.offset = offset
        self.scale = scale
    }
    
    // MARK: - Coordinate Conversion
    
    /// Convert a point from screen coordinates to canvas coordinates
    /// - Parameter point: Point in screen coordinates
    /// - Returns: Point in canvas coordinates
    public func screenToCanvas(_ point: CGPoint) -> CGPoint {
        return CGPoint(
            x: (point.x - offset.x) / scale,
            y: (point.y - offset.y) / scale
        )
    }
    
    /// Convert a point from canvas coordinates to screen coordinates
    /// - Parameter point: Point in canvas coordinates
    /// - Returns: Point in screen coordinates
    public func canvasToScreen(_ point: CGPoint) -> CGPoint {
        return CGPoint(
            x: point.x * scale + offset.x,
            y: point.y * scale + offset.y
        )
    }
    
    /// Convert a size from screen to canvas coordinates
    /// - Parameter size: Size in screen coordinates
    /// - Returns: Size in canvas coordinates
    public func screenToCanvas(_ size: CGSize) -> CGSize {
        return CGSize(
            width: size.width / scale,
            height: size.height / scale
        )
    }
    
    /// Convert a size from canvas to screen coordinates
    /// - Parameter size: Size in canvas coordinates
    /// - Returns: Size in screen coordinates
    public func canvasToScreen(_ size: CGSize) -> CGSize {
        return CGSize(
            width: size.width * scale,
            height: size.height * scale
        )
    }
    
    /// Convert a rectangle from screen to canvas coordinates
    /// - Parameter rect: Rectangle in screen coordinates
    /// - Returns: Rectangle in canvas coordinates
    public func screenToCanvas(_ rect: CGRect) -> CGRect {
        let origin = screenToCanvas(rect.origin)
        let size = screenToCanvas(rect.size)
        return CGRect(origin: origin, size: size)
    }
    
    /// Convert a rectangle from canvas to screen coordinates
    /// - Parameter rect: Rectangle in canvas coordinates
    /// - Returns: Rectangle in screen coordinates
    public func canvasToScreen(_ rect: CGRect) -> CGRect {
        let origin = canvasToScreen(rect.origin)
        let size = canvasToScreen(rect.size)
        return CGRect(origin: origin, size: size)
    }
    
    // MARK: - Transform Operations
    
    /// Apply a pan delta to the current offset
    /// - Parameter delta: Pan delta in screen coordinates
    /// - Returns: New transform with updated offset
    public func panned(by delta: CGSize) -> FlowTransform {
        return FlowTransform(
            offset: CGPoint(
                x: offset.x + delta.width,
                y: offset.y + delta.height
            ),
            scale: scale
        )
    }
    
    /// Apply a zoom factor centered at a specific point
    /// - Parameters:
    ///   - factor: Zoom factor to apply (> 1 = zoom in, < 1 = zoom out)
    ///   - center: Center point for zooming in screen coordinates
    ///   - minScale: Minimum allowed scale
    ///   - maxScale: Maximum allowed scale
    /// - Returns: New transform with updated scale and offset
    public func zoomed(
        by factor: CGFloat,
        at center: CGPoint,
        minScale: CGFloat = 0.1,
        maxScale: CGFloat = 4.0
    ) -> FlowTransform {
        let newScale = max(minScale, min(maxScale, scale * factor))
        
        // Adjust offset to zoom towards the center point
        let scaleChange = newScale / scale
        let newOffsetX = center.x - (center.x - offset.x) * scaleChange
        let newOffsetY = center.y - (center.y - offset.y) * scaleChange
        
        return FlowTransform(
            offset: CGPoint(x: newOffsetX, y: newOffsetY),
            scale: newScale
        )
    }
    
    /// Set zoom to a specific scale centered at a point
    /// - Parameters:
    ///   - newScale: Target scale
    ///   - center: Center point for zooming in screen coordinates
    ///   - minScale: Minimum allowed scale
    ///   - maxScale: Maximum allowed scale
    /// - Returns: New transform with updated scale and offset
    public func withScale(
        _ newScale: CGFloat,
        at center: CGPoint,
        minScale: CGFloat = 0.1,
        maxScale: CGFloat = 4.0
    ) -> FlowTransform {
        let clampedScale = max(minScale, min(maxScale, newScale))
        let factor = clampedScale / scale
        return zoomed(by: factor, at: center, minScale: minScale, maxScale: maxScale)
    }
}

// MARK: - CGAffineTransform Conversion

public extension FlowTransform {
    /// Convert to CGAffineTransform for use with SwiftUI transforms
    /// Uses the formula: screen = canvas * scale + offset
    var affineTransform: CGAffineTransform {
        CGAffineTransform(
            a: scale,
            b: 0,
            c: 0,
            d: scale,
            tx: offset.x,
            ty: offset.y
        )
    }
}

// MARK: - Type-Safe Coordinate Conversions

public extension FlowTransform {
    
    /// Convert a screen point to a canvas point (type-safe version).
    /// - Parameter point: Point in screen coordinates
    /// - Returns: Point in canvas coordinates
    func toCanvas(_ point: ScreenPoint) -> CanvasPoint {
        CanvasPoint(screenToCanvas(point.cgPoint))
    }
    
    /// Convert a canvas point to a screen point (type-safe version).
    /// - Parameter point: Point in canvas coordinates
    /// - Returns: Point in screen coordinates
    func toScreen(_ point: CanvasPoint) -> ScreenPoint {
        ScreenPoint(canvasToScreen(point.cgPoint))
    }
    
    /// Convert a screen rectangle to a canvas rectangle (type-safe version).
    /// - Parameter rect: Rectangle in screen coordinates
    /// - Returns: Rectangle in canvas coordinates
    func toCanvas(_ rect: ScreenRect) -> CanvasRect {
        CanvasRect(screenToCanvas(rect.cgRect))
    }
    
    /// Convert a canvas rectangle to a screen rectangle (type-safe version).
    /// - Parameter rect: Rectangle in canvas coordinates
    /// - Returns: Rectangle in screen coordinates
    func toScreen(_ rect: CanvasRect) -> ScreenRect {
        ScreenRect(canvasToScreen(rect.cgRect))
    }
    
    /// Convert a CGRect from screen to canvas coordinates, returning a CanvasRect.
    /// - Parameter rect: Rectangle in screen coordinates
    /// - Returns: Rectangle in canvas coordinates as CanvasRect
    func toCanvasRect(_ rect: CGRect) -> CanvasRect {
        CanvasRect(screenToCanvas(rect))
    }
    
    /// Convert a canvas size to a screen size.
    /// - Parameter size: Size in canvas coordinates
    /// - Returns: Size in screen coordinates
    func toScreen(_ size: CanvasSize) -> CGSize {
        canvasToScreen(size.cgSize)
    }
    
    /// Convert a screen size to a canvas size.
    /// - Parameter size: Size in screen coordinates
    /// - Returns: Size in canvas coordinates
    func toCanvas(_ size: CGSize) -> CanvasSize {
        CanvasSize(screenToCanvas(size))
    }
}
