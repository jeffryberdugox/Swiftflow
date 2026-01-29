//
//  HelperLinesView.swift
//  SwiftFlow
//
//  View that renders helper lines (alignment guides) on the canvas.
//

import SwiftUI

/// Renders helper lines (alignment guides) during node dragging
struct HelperLinesView: View {
    let horizontalGuides: [CGFloat]
    let verticalGuides: [CGFloat]
    let config: HelperLinesConfig
    let transform: FlowTransform
    let viewportSize: CGSize
    
    var body: some View {
        Canvas { context, size in
            let color = config.style.lineColor.color
            
            // Convert Canvas size from screen to canvas coordinates
            // The Canvas is inside a transformed container, so we draw in canvas coordinates
            // but need to know the canvas dimensions to draw lines across the visible area
            let canvasSize = transform.screenToCanvas(size)
            
            // Draw vertical guides (X positions)
            // Use canvas coordinates directly since we're inside the transformed container
            for x in verticalGuides {
                let path = Path { p in
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: canvasSize.height))
                }
                
                if config.style.dashPattern.isEmpty {
                    context.stroke(path, with: .color(color), lineWidth: config.style.lineWidth)
                } else {
                    context.stroke(
                        path,
                        with: .color(color),
                        style: StrokeStyle(
                            lineWidth: config.style.lineWidth,
                            dash: config.style.dashPattern
                        )
                    )
                }
            }
            
            // Draw horizontal guides (Y positions)
            // Use canvas coordinates directly since we're inside the transformed container
            for y in horizontalGuides {
                let path = Path { p in
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: canvasSize.width, y: y))
                }
                
                if config.style.dashPattern.isEmpty {
                    context.stroke(path, with: .color(color), lineWidth: config.style.lineWidth)
                } else {
                    context.stroke(
                        path,
                        with: .color(color),
                        style: StrokeStyle(
                            lineWidth: config.style.lineWidth,
                            dash: config.style.dashPattern
                        )
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Preview

#Preview("Helper Lines") {
    HelperLinesView(
        horizontalGuides: [100, 200],
        verticalGuides: [150, 250, 350],
        config: HelperLinesConfig(),
        transform: FlowTransform(),
        viewportSize: CGSize(width: 400, height: 300)
    )
    .frame(width: 400, height: 300)
    .background(Color.gray.opacity(0.1))
}

#Preview("Single Guide Lines") {
    HelperLinesView(
        horizontalGuides: [150],
        verticalGuides: [200],
        config: HelperLinesConfig(),
        transform: FlowTransform(),
        viewportSize: CGSize(width: 400, height: 300)
    )
    .frame(width: 400, height: 300)
    .background(Color.gray.opacity(0.1))
}
