//
//  PanZoomManager.swift
//  SwiftFlow
//
//  Manages pan and zoom state for the canvas.
//

import Foundation
import SwiftUI
import Combine

/// Manages the pan and zoom state of the canvas
@MainActor
public class PanZoomManager: ObservableObject {
    // MARK: - Published Properties
    
    /// Current transform state (offset and scale)
    @Published public var transform: FlowTransform
    
    // MARK: - Configuration
    
    /// Minimum allowed zoom level
    public var minZoom: CGFloat
    
    /// Maximum allowed zoom level
    public var maxZoom: CGFloat
    
    /// Size of the viewport (set by the canvas view)
    public var viewportSize: CGSize = .zero
    
    // MARK: - Initialization
    
    public init(
        initialTransform: FlowTransform = .identity,
        minZoom: CGFloat = 0.1,
        maxZoom: CGFloat = 4.0
    ) {
        self.transform = initialTransform
        self.minZoom = minZoom
        self.maxZoom = maxZoom
    }
    
    // MARK: - Pan Operations
    
    /// Apply a pan delta to the current offset
    /// - Parameter delta: Pan delta in screen coordinates
    public func pan(by delta: CGSize) {
        transform = transform.panned(by: delta)
    }
    
    /// Set the pan offset directly
    /// - Parameter offset: New offset in screen coordinates
    public func setOffset(_ offset: CGPoint) {
        transform.offset = offset
    }
    
    // MARK: - Zoom Operations
    
    /// Apply a zoom factor centered at a point
    /// - Parameters:
    ///   - factor: Zoom factor (> 1 = zoom in, < 1 = zoom out)
    ///   - center: Center point for zooming in screen coordinates
    public func zoom(by factor: CGFloat, at center: CGPoint) {
        transform = transform.zoomed(
            by: factor,
            at: center,
            minScale: minZoom,
            maxScale: maxZoom
        )
    }
    
    /// Apply a zoom factor centered at a type-safe screen point
    /// - Parameters:
    ///   - factor: Zoom factor (> 1 = zoom in, < 1 = zoom out)
    ///   - anchor: Center point for zooming (type-safe)
    public func zoom(by factor: CGFloat, at anchor: ScreenPoint) {
        zoom(by: factor, at: anchor.cgPoint)
    }
    
    /// Set zoom to a specific scale centered at a point
    /// - Parameters:
    ///   - scale: Target scale
    ///   - center: Center point for zooming
    public func setZoom(_ scale: CGFloat, at center: CGPoint) {
        transform = transform.withScale(
            scale,
            at: center,
            minScale: minZoom,
            maxScale: maxZoom
        )
    }
    
    /// Set zoom to a specific scale centered at a type-safe screen point
    /// - Parameters:
    ///   - scale: Target scale
    ///   - anchor: Center point for zooming (type-safe)
    public func setZoom(_ scale: CGFloat, at anchor: ScreenPoint) {
        setZoom(scale, at: anchor.cgPoint)
    }
    
    /// Set zoom to a specific scale centered at viewport center
    /// - Parameter scale: Target scale
    public func setZoom(_ scale: CGFloat) {
        let center = CGPoint(
            x: viewportSize.width / 2,
            y: viewportSize.height / 2
        )
        setZoom(scale, at: center)
    }
    
    /// Zoom in by a standard factor (20%)
    /// - Parameter center: Center point for zooming (defaults to viewport center)
    public func zoomIn(at center: CGPoint? = nil, factor: CGFloat = 1.2) {
        let zoomCenter = center ?? CGPoint(
            x: viewportSize.width / 2,
            y: viewportSize.height / 2
        )
        zoom(by: factor, at: zoomCenter)
    }
    
    /// Zoom out by a standard factor (20%)
    /// - Parameter center: Center point for zooming (defaults to viewport center)
    public func zoomOut(at center: CGPoint? = nil, factor: CGFloat = 0.8) {
        let zoomCenter = center ?? CGPoint(
            x: viewportSize.width / 2,
            y: viewportSize.height / 2
        )
        zoom(by: factor, at: zoomCenter)
    }
    
    /// Check if at minimum zoom
    public var isAtMinZoom: Bool {
        transform.scale <= minZoom
    }
    
    /// Check if at maximum zoom
    public var isAtMaxZoom: Bool {
        transform.scale >= maxZoom
    }
    
    // MARK: - Fit to View
    
    /// Adjust transform to fit given bounds within the viewport
    /// - Parameters:
    ///   - bounds: Content bounds to fit
    ///   - padding: Padding around the content
    ///   - animated: Whether to animate the transition (not implemented in this version)
    public func fitToView(bounds: CGRect, padding: CGFloat = 50) {
        guard viewportSize.width > 0, viewportSize.height > 0 else {
            return
        }

        let newTransform = getViewportForBounds(
            bounds: bounds,
            viewportSize: viewportSize,
            padding: padding,
            minZoom: minZoom,
            maxZoom: maxZoom
        )

        transform = newTransform
    }
    
    /// Fit all nodes in the viewport
    /// - Parameters:
    ///   - nodes: Nodes to fit
    ///   - padding: Padding around the content
    public func fitNodes<Node: FlowNode>(_ nodes: [Node], padding: CGFloat = 50) {
        guard let bounds = calculateNodesBounds(nodes) else {
            return
        }

        fitToView(bounds: bounds, padding: padding)
    }
    
    // MARK: - Reset
    
    /// Reset transform to identity (no pan, zoom = 1.0)
    public func reset() {
        transform = .identity
    }
    
    /// Reset to a specific zoom level centered in the viewport
    /// - Parameter zoom: Target zoom level
    public func reset(to zoom: CGFloat) {
        transform = FlowTransform(offset: .zero, scale: zoom)
    }
    
    // MARK: - Coordinate Conversion
    
    /// Convert a point from screen coordinates to canvas coordinates
    /// - Parameter screenPoint: Point in screen coordinates
    /// - Returns: Point in canvas coordinates
    public func screenToCanvas(_ screenPoint: CGPoint) -> CGPoint {
        return transform.screenToCanvas(screenPoint)
    }
    
    /// Convert a point from canvas coordinates to screen coordinates
    /// - Parameter canvasPoint: Point in canvas coordinates
    /// - Returns: Point in screen coordinates
    public func canvasToScreen(_ canvasPoint: CGPoint) -> CGPoint {
        return transform.canvasToScreen(canvasPoint)
    }
    
    // MARK: - Type-Safe Coordinate Conversion
    
    /// Convert a screen point to canvas point (type-safe)
    /// - Parameter point: Point in screen coordinates
    /// - Returns: Point in canvas coordinates
    public func toCanvas(_ point: ScreenPoint) -> CanvasPoint {
        return transform.toCanvas(point)
    }
    
    /// Convert a canvas point to screen point (type-safe)
    /// - Parameter point: Point in canvas coordinates
    /// - Returns: Point in screen coordinates
    public func toScreen(_ point: CanvasPoint) -> ScreenPoint {
        return transform.toScreen(point)
    }
    
    /// Convert a screen rect to canvas rect (type-safe)
    /// - Parameter rect: Rect in screen coordinates
    /// - Returns: Rect in canvas coordinates
    public func toCanvas(_ rect: CGRect) -> CanvasRect {
        return transform.toCanvasRect(rect)
    }
    
    /// Get the viewport center in screen coordinates (type-safe)
    public var viewportCenter: ScreenPoint {
        ScreenPoint(x: viewportSize.width / 2, y: viewportSize.height / 2)
    }
    
    /// Get the viewport rect in canvas coordinates
    public var viewportRectCanvas: CanvasRect {
        transform.toCanvasRect(CGRect(origin: .zero, size: viewportSize))
    }
}
