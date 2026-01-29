//
//  EdgeMarkerView.swift
//  SwiftFlow
//
//  Marker shapes for edge endpoints (arrows, dots, etc.)
//

import SwiftUI

// MARK: - Marker Shape Protocol

/// Protocol for marker shapes
public protocol MarkerShape: Shape {
    init(at: CGPoint, angle: Double, size: CGFloat)
}

// MARK: - Arrow Marker

/// Standard arrow marker (open arrow)
public struct ArrowMarker: MarkerShape {
    let at: CGPoint
    let angle: Double
    let size: CGFloat
    
    public init(at: CGPoint, angle: Double, size: CGFloat = 8) {
        self.at = at
        self.angle = angle
        self.size = size
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Arrow points
        let tip = at
        let left = CGPoint(
            x: at.x - size * cos(angle - .pi / 6),
            y: at.y - size * sin(angle - .pi / 6)
        )
        let right = CGPoint(
            x: at.x - size * cos(angle + .pi / 6),
            y: at.y - size * sin(angle + .pi / 6)
        )
        
        path.move(to: tip)
        path.addLine(to: left)
        path.move(to: tip)
        path.addLine(to: right)
        
        return path
    }
}

// MARK: - Closed Arrow Marker

/// Filled arrow marker (closed arrow)
public struct ClosedArrowMarker: MarkerShape {
    let at: CGPoint
    let angle: Double
    let size: CGFloat
    
    public init(at: CGPoint, angle: Double, size: CGFloat = 8) {
        self.at = at
        self.angle = angle
        self.size = size
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Arrow points
        let tip = at
        let left = CGPoint(
            x: at.x - size * cos(angle - .pi / 6),
            y: at.y - size * sin(angle - .pi / 6)
        )
        let right = CGPoint(
            x: at.x - size * cos(angle + .pi / 6),
            y: at.y - size * sin(angle + .pi / 6)
        )
        
        path.move(to: tip)
        path.addLine(to: left)
        path.addLine(to: right)
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Dot Marker

/// Circular dot marker
public struct DotMarker: MarkerShape {
    let at: CGPoint
    let angle: Double
    let size: CGFloat
    
    public init(at: CGPoint, angle: Double, size: CGFloat = 8) {
        self.at = at
        self.angle = angle
        self.size = size
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let radius = size / 2
        path.addEllipse(in: CGRect(
            x: at.x - radius,
            y: at.y - radius,
            width: size,
            height: size
        ))
        
        return path
    }
}

// MARK: - Marker View

/// View that renders a marker based on configuration
public struct EdgeMarkerRendererView: View {
    let marker: EdgeMarker
    let position: CGPoint
    let angle: Double
    let defaultColor: Color
    
    public init(
        marker: EdgeMarker,
        position: CGPoint,
        angle: Double,
        defaultColor: Color
    ) {
        self.marker = marker
        self.position = position
        self.angle = angle
        self.defaultColor = defaultColor
    }
    
    public var body: some View {
        Group {
            switch marker.type {
            case .arrow:
                ArrowMarker(at: position, angle: angle, size: marker.size)
                    .stroke(markerColor, lineWidth: 2)
                
            case .arrowClosed:
                ClosedArrowMarker(at: position, angle: angle, size: marker.size)
                    .fill(markerColor)
                
            case .dot:
                DotMarker(at: position, angle: angle, size: marker.size)
                    .fill(markerColor)
                
            case .none:
                EmptyView()
            }
        }
    }
    
    private var markerColor: Color {
        if let color = marker.color {
            return Color(color)
        }
        return defaultColor
    }
}

// MARK: - Preview

#Preview("Arrow Markers") {
    Canvas { context, size in
        // Open arrow
        let arrow1 = ArrowMarker(at: CGPoint(x: 100, y: 50), angle: 0, size: 12)
        context.stroke(arrow1.path(in: CGRect(origin: .zero, size: size)), with: .color(.blue), lineWidth: 2)
        
        // Closed arrow
        let arrow2 = ClosedArrowMarker(at: CGPoint(x: 100, y: 100), angle: .pi/4, size: 12)
        context.fill(arrow2.path(in: CGRect(origin: .zero, size: size)), with: .color(.green))
        
        // Dot marker
        let dot = DotMarker(at: CGPoint(x: 100, y: 150), angle: 0, size: 12)
        context.fill(dot.path(in: CGRect(origin: .zero, size: size)), with: .color(.red))
    }
    .frame(width: 200, height: 200)
}

#Preview("Edge Marker Renderer") {
    VStack(spacing: 30) {
        EdgeMarkerRendererView(
            marker: EdgeMarker(type: .arrow, position: .target),
            position: CGPoint(x: 100, y: 50),
            angle: 0,
            defaultColor: .blue
        )
        
        EdgeMarkerRendererView(
            marker: EdgeMarker(type: .arrowClosed, position: .target),
            position: CGPoint(x: 100, y: 50),
            angle: .pi/4,
            defaultColor: .green
        )
        
        EdgeMarkerRendererView(
            marker: EdgeMarker(type: .dot, position: .target),
            position: CGPoint(x: 100, y: 50),
            angle: 0,
            defaultColor: .red
        )
    }
    .frame(width: 200, height: 200)
}
