//
//  ConnectionPreviewView.swift
//  SwiftFlow
//
//  Visual preview of a connection being drawn.
//

import SwiftUI

/// View that shows the connection being drawn
public struct ConnectionPreviewView: View {
    let connection: ConnectionState
    var pathCalculator: any PathCalculator
    var strokeColor: Color
    var validColor: Color
    var invalidColor: Color
    var lineWidth: CGFloat
    
    public init(
        connection: ConnectionState,
        pathCalculator: any PathCalculator = BezierPathCalculator(),
        strokeColor: Color = Color.blue,
        validColor: Color = Color.green,
        invalidColor: Color = Color.gray,
        lineWidth: CGFloat = 2
    ) {
        self.connection = connection
        self.pathCalculator = pathCalculator
        self.strokeColor = strokeColor
        self.validColor = validColor
        self.invalidColor = invalidColor
        self.lineWidth = lineWidth
    }
    
    public var body: some View {
        let sourcePos = connection.sourcePosition
        let targetPos = connection.currentPosition
        
        // Determine the port positions for path calculation
        let sourcePortPos = connection.sourcePortPosition
        let targetPortPos = connection.targetPortPosition ?? sourcePortPos.opposite
        
        let result = pathCalculator.calculatePath(
            from: sourcePos,
            to: targetPos,
            sourcePosition: sourcePortPos,
            targetPosition: targetPortPos
        )
        
        result.path
            .stroke(
                connection.isValid ? validColor : strokeColor,
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round,
                    lineJoin: .round,
                    dash: connection.isValid ? [] : [8, 4]
                )
            )
            .animation(.easeInOut(duration: 0.1), value: connection.isValid)
    }
}

// MARK: - Connection Endpoint Indicator

/// Visual indicator at the end of a connection preview
public struct ConnectionEndpoint: View {
    let position: CGPoint
    let isValid: Bool
    var size: CGFloat = 8
    var validColor: Color = .green
    var invalidColor: Color = .blue
    
    public var body: some View {
        Circle()
            .fill(isValid ? validColor : invalidColor)
            .frame(width: size, height: size)
            .position(position)
            .animation(.easeInOut(duration: 0.1), value: isValid)
    }
}

// MARK: - Preview

#Preview("Valid Connection") {
    ConnectionPreviewView(
        connection: ConnectionState(
            sourceNodeId: UUID(),
            sourcePortId: UUID(),
            sourcePosition: CGPoint(x: 100, y: 150),
            sourcePortPosition: .right,
            currentPosition: CGPoint(x: 300, y: 150),
            isValid: true
        )
    )
    .frame(width: 400, height: 300)
}

#Preview("Invalid Connection") {
    ConnectionPreviewView(
        connection: ConnectionState(
            sourceNodeId: UUID(),
            sourcePortId: UUID(),
            sourcePosition: CGPoint(x: 100, y: 150),
            sourcePortPosition: .right,
            currentPosition: CGPoint(x: 300, y: 200),
            isValid: false
        )
    )
    .frame(width: 400, height: 300)
}
