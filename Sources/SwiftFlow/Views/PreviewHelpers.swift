//
//  PreviewHelpers.swift
//  SwiftFlow
//
//  Shared preview helpers for SwiftUI previews.
//

import SwiftUI

#if DEBUG

// MARK: - Preview Node

/// Preview implementation of FlowNode for testing
public struct PreviewNode: FlowNode, Codable {
    public let id: UUID
    public var position: CGPoint
    public var width: CGFloat
    public var height: CGFloat
    public var isDraggable: Bool
    public var isSelectable: Bool
    public var inputPorts: [any FlowPort]
    public var outputPorts: [any FlowPort]
    
    enum CodingKeys: String, CodingKey {
        case id, position, width, height, isDraggable, isSelectable
    }
    
    public init(
        id: UUID = UUID(),
        position: CGPoint = .zero,
        width: CGFloat = 200,
        height: CGFloat = 100,
        isDraggable: Bool = true,
        isSelectable: Bool = true,
        inputPorts: [any FlowPort] = [],
        outputPorts: [any FlowPort] = []
    ) {
        self.id = id
        self.position = position
        self.width = width
        self.height = height
        self.isDraggable = isDraggable
        self.isSelectable = isSelectable
        self.inputPorts = inputPorts.isEmpty ? [PreviewPort(position: .left)] : inputPorts
        self.outputPorts = outputPorts.isEmpty ? [PreviewPort(position: .right)] : outputPorts
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        position = try container.decode(CGPoint.self, forKey: .position)
        width = try container.decode(CGFloat.self, forKey: .width)
        height = try container.decode(CGFloat.self, forKey: .height)
        isDraggable = try container.decode(Bool.self, forKey: .isDraggable)
        isSelectable = try container.decode(Bool.self, forKey: .isSelectable)
        inputPorts = [PreviewPort(position: .left)]
        outputPorts = [PreviewPort(position: .right)]
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(position, forKey: .position)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encode(isDraggable, forKey: .isDraggable)
        try container.encode(isSelectable, forKey: .isSelectable)
    }
}

// MARK: - Preview Port

/// Preview implementation of FlowPort for testing
public struct PreviewPort: FlowPort {
    public let id: UUID
    public var position: PortPosition
    public var offset: CGFloat
    public var layout: PortLayout
    
    public init(
        id: UUID = UUID(),
        position: PortPosition = .right,
        offset: CGFloat = 0,
        layout: PortLayout? = nil
    ) {
        self.id = id
        self.position = position
        self.offset = offset
        // Use appropriate preset based on position
        if let layout = layout {
            self.layout = layout
        } else {
            switch position {
            case .left:
                self.layout = PortLayout(preset: .leftCenter)
            case .right:
                self.layout = PortLayout(preset: .rightCenter)
            case .top:
                self.layout = PortLayout(preset: .topCenter)
            case .bottom:
                self.layout = PortLayout(preset: .bottomCenter)
            }
        }
    }
}

// MARK: - Preview Edge

/// Preview implementation of FlowEdge for testing
public struct PreviewEdge: FlowEdge, Codable {
    public let id: UUID
    public var sourceNodeId: UUID
    public var sourcePortId: UUID
    public var targetNodeId: UUID
    public var targetPortId: UUID
    
    public init(
        id: UUID = UUID(),
        sourceNodeId: UUID,
        targetNodeId: UUID,
        sourcePortId: UUID = UUID(),
        targetPortId: UUID = UUID()
    ) {
        self.id = id
        self.sourceNodeId = sourceNodeId
        self.sourcePortId = sourcePortId
        self.targetNodeId = targetNodeId
        self.targetPortId = targetPortId
    }
}

// MARK: - Helper Functions

/// Create a set of preview nodes for testing
public func createPreviewNodes(count: Int = 3) -> [PreviewNode] {
    var nodes: [PreviewNode] = []
    for i in 0..<count {
        let x = CGFloat(i * 250)
        let y = CGFloat(100 + (i % 2) * 100)
        nodes.append(PreviewNode(position: CGPoint(x: x, y: y)))
    }
    return nodes
}

/// Create preview edges connecting nodes
public func createPreviewEdges(from nodes: [PreviewNode]) -> [PreviewEdge] {
    guard nodes.count >= 2 else { return [] }
    var edges: [PreviewEdge] = []
    for i in 0..<(nodes.count - 1) {
        edges.append(PreviewEdge(
            sourceNodeId: nodes[i].id,
            targetNodeId: nodes[i + 1].id
        ))
    }
    return edges
}

#endif
