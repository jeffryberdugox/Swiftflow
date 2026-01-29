//
//  EdgeLabel.swift
//  SwiftFlow
//
//  Edge label support for displaying text on edges.
//

import Foundation
import SwiftUI

/// Configuration for edge labels
public struct EdgeLabelConfig: Codable {
    /// Label text
    public var text: String
    
    /// Position along edge (0.0 = start, 0.5 = middle, 1.0 = end)
    public var position: CGFloat
    
    /// Background color for label
    public var backgroundColor: Color
    
    /// Text color
    public var textColor: Color
    
    /// Font size
    public var fontSize: CGFloat
    
    /// Padding around text
    public var padding: CGFloat
    
    /// Whether to show background
    public var showBackground: Bool
    
    public init(
        text: String,
        position: CGFloat = 0.5,
        backgroundColor: Color = Color(nsColor: .controlBackgroundColor),
        textColor: Color = .primary,
        fontSize: CGFloat = 12,
        padding: CGFloat = 4,
        showBackground: Bool = true
    ) {
        self.text = text
        self.position = max(0, min(1, position))
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.fontSize = fontSize
        self.padding = padding
        self.showBackground = showBackground
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case text, position, fontSize, padding, showBackground
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        position = try container.decode(CGFloat.self, forKey: .position)
        fontSize = try container.decode(CGFloat.self, forKey: .fontSize)
        padding = try container.decode(CGFloat.self, forKey: .padding)
        showBackground = try container.decode(Bool.self, forKey: .showBackground)
        backgroundColor = Color(nsColor: .controlBackgroundColor)
        textColor = .primary
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encode(position, forKey: .position)
        try container.encode(fontSize, forKey: .fontSize)
        try container.encode(padding, forKey: .padding)
        try container.encode(showBackground, forKey: .showBackground)
    }
}

/// View for rendering edge labels
/// NOTE: This view is kept for API compatibility but is not used directly.
/// Edge labels are now rendered in a separate layer in CanvasView for better performance and flexibility
/// for proper positioning and interactivity.
public struct EdgeLabelView: View {
    let label: EdgeLabelConfig
    let edgePath: Path
    
    public init(
        label: EdgeLabelConfig,
        edgePath: Path
    ) {
        self.label = label
        self.edgePath = edgePath
    }
    
    public var body: some View {
        if !label.text.isEmpty {
            Text(label.text)
                .font(.system(size: label.fontSize))
                .foregroundColor(label.textColor)
                .padding(label.padding)
                .background(
                    label.showBackground ?
                    AnyView(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(label.backgroundColor)
                            .shadow(color: Color.black.opacity(0.1), radius: 2)
                    ) : AnyView(EmptyView())
                )
                .position(calculateLabelPosition())
        }
    }
    
    private func calculateLabelPosition() -> CGPoint {
        // Get point at position along path
        // NOTE: No transform needed - this view should be rendered
        // inside the transformed canvas space (within .canvasTransform())
        let point = edgePath.trimmedPath(from: 0, to: label.position).currentPoint ?? .zero
        return point
    }
}

/// Protocol extension to add label support to edges
public protocol LabeledFlowEdge: FlowEdge {
    var label: EdgeLabelConfig? { get set }
}

// Default implementation
public extension LabeledFlowEdge {
    var label: EdgeLabelConfig? {
        get { nil }
        set { }
    }
}

/// Protocol extension to add disabled state to edges
public protocol DisableableFlowEdge: FlowEdge {
    var isDisabled: Bool { get set }
}

// Default implementation
public extension DisableableFlowEdge {
    var isDisabled: Bool {
        get { false }
        set { }
    }
}
