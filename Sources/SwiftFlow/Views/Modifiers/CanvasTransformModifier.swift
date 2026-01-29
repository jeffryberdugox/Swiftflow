//
//  CanvasTransformModifier.swift
//  SwiftFlow
//
//  View modifier that applies canvas transform (scale and offset).
//

import SwiftUI

/// View modifier that applies the canvas transform to content
public struct CanvasTransformModifier: ViewModifier {
    let transform: FlowTransform
    let optimizeRendering: Bool
    
    public init(transform: FlowTransform, optimizeRendering: Bool = true) {
        self.transform = transform
        self.optimizeRendering = optimizeRendering
    }
    
    public func body(content: Content) -> some View {
        // CRITICAL FIX: Only use .id() when optimization is disabled
        // The .id() forces complete view recreation on every transform change
        let transformedContent = content
            .transformEffect(
                CGAffineTransform(
                    a: transform.scale,
                    b: 0,
                    c: 0,
                    d: transform.scale,
                    tx: transform.offset.x,
                    ty: transform.offset.y
                )
            )
        
        if optimizeRendering {
            return AnyView(transformedContent)
        } else {
            // Legacy behavior: force re-render with .id()
            return AnyView(
                transformedContent
                    .id("transform-\(transform.scale)-\(transform.offset.x)-\(transform.offset.y)")
            )
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Apply a canvas transform to this view
    /// - Parameters:
    ///   - transform: The transform to apply
    ///   - optimizeRendering: Whether to optimize rendering (removes .id() that forces re-render). Default is true.
    /// - Returns: Transformed view
    func canvasTransform(_ transform: FlowTransform, optimizeRendering: Bool = true) -> some View {
        modifier(CanvasTransformModifier(transform: transform, optimizeRendering: optimizeRendering))
    }
}
