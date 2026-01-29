//
//  GlassEffectModifier.swift
//  SwiftFlow
//
//  Glass effect modifier with fallback for older OS versions.
//

import SwiftUI

/// Applies glass effect on macOS 26+, falls back to ultraThinMaterial on older versions
struct GlassEffectModifier<S: InsettableShape>: ViewModifier {
    let shape: S
    
    func body(content: Content) -> some View {
        Group {
            if #available(macOS 26.0, iOS 18.2, *) {
                content
                    .modifier(GlassEffectModifierNew(shape: shape))
            } else {
                content
                    .background(.ultraThinMaterial, in: shape)
            }
        }
    }
}

@available(macOS 26.0, iOS 18.2, *)
private struct GlassEffectModifierNew<S: InsettableShape>: ViewModifier {
    let shape: S
    
    func body(content: Content) -> some View {
        if #available(macOS 15.0, *) {
            content.glassEffect(in: shape)
        } else {
            content
                .background(.ultraThinMaterial, in: shape)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        }
    }
}

// MARK: - View Extension

extension View {
    /// Applies glass effect with automatic fallback for older OS versions
    func glassBackground<S: InsettableShape>(in shape: S) -> some View {
        self.modifier(GlassEffectModifier(shape: shape))
    }
}
