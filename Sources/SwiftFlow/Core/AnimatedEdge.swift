//
//  AnimatedEdge.swift
//  SwiftFlow
//
//  Animated edge support with flowing dashed lines.
//

import SwiftUI

/// Configuration for animated edges
public struct AnimatedEdgeConfig: Codable {
    /// Whether animation is enabled
    public var isAnimated: Bool
    
    /// Animation duration in seconds
    public var duration: Double
    
    /// Dash pattern for animated line
    public var dashPattern: [CGFloat]
    
    /// Animation direction (true = forward, false = reverse)
    public var forward: Bool
    
    public init(
        isAnimated: Bool = false,
        duration: Double = 1.0,
        dashPattern: [CGFloat] = [5, 5],
        forward: Bool = true
    ) {
        self.isAnimated = isAnimated
        self.duration = duration
        self.dashPattern = dashPattern
        self.forward = forward
    }
}

/// Animated edge shape with flowing dashed lines
public struct AnimatedEdgeShape: Shape {
    let path: Path
    var animationPhase: CGFloat
    let dashPattern: [CGFloat]
    
    public var animatableData: CGFloat {
        get { animationPhase }
        set { animationPhase = newValue }
    }
    
    public func path(in rect: CGRect) -> Path {
        return path
    }
}

/// Helper to create animated stroke style
public func createAnimatedStroke(
    config: AnimatedEdgeConfig,
    phase: CGFloat,
    lineWidth: CGFloat = 2.0
) -> StrokeStyle {
    if config.isAnimated {
        return StrokeStyle(
            lineWidth: lineWidth,
            lineCap: .round,
            lineJoin: .round,
            dash: config.dashPattern,
            dashPhase: phase
        )
    } else {
        return StrokeStyle(
            lineWidth: lineWidth,
            lineCap: .round,
            lineJoin: .round
        )
    }
}

/// View for animated edge path
public struct AnimatedEdgeView: View {
    let path: Path
    let config: AnimatedEdgeConfig
    let color: Color
    let lineWidth: CGFloat
    
    @State private var phase: CGFloat = 0
    
    public init(
        path: Path,
        config: AnimatedEdgeConfig,
        color: Color = .primary,
        lineWidth: CGFloat = 2.0
    ) {
        self.path = path
        self.config = config
        self.color = color
        self.lineWidth = lineWidth
    }
    
    public var body: some View {
        path
            .stroke(
                color,
                style: createAnimatedStroke(config: config, phase: phase, lineWidth: lineWidth)
            )
            .onAppear {
                if config.isAnimated {
                    let totalDash = config.dashPattern.reduce(0, +)
                    withAnimation(
                        .linear(duration: config.duration)
                        .repeatForever(autoreverses: false)
                    ) {
                        phase = config.forward ? -totalDash : totalDash
                    }
                }
            }
    }
}

/// Protocol extension to add animation support to edges
public protocol AnimatedFlowEdge: FlowEdge {
    var animationConfig: AnimatedEdgeConfig? { get set }
}

// Default implementation
public extension AnimatedFlowEdge {
    var animationConfig: AnimatedEdgeConfig? {
        get { nil }
        set { }
    }
}
