# Getting Started

Build your first node-based editor with SwiftFlow.

## Overview

This guide walks you through creating a simple node-based editor using SwiftFlow. You'll learn the basics of nodes, edges, and canvas interaction.

## Installation

Add SwiftFlow to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/jeffryberdugox/SwiftFlow.git", from: "1.0.0")
]
```

> **Tip:** After adding SwiftFlow, use **Option+Click** on any type to see instant documentation in Xcode!

## Define Your Node Type

Start by creating a type that conforms to ``FlowNode``:

```swift
import SwiftFlow

struct MyNode: FlowNode, Codable {
    let id: UUID
    var title: String
    var position: CGPoint
    var width: CGFloat = 120
    var height: CGFloat = 60
    var parentId: UUID? = nil
    var zIndex: Double = 0
    
    var inputPorts: [any FlowPort] {
        [MyPort(id: UUID(), position: .left)]
    }
    
    var outputPorts: [any FlowPort] {
        [MyPort(id: UUID(), position: .right)]
    }
}

struct MyPort: FlowPort, Codable {
    let id: UUID
    var position: PortPosition
}
```

The `position` property represents the **top-left corner** of the node in canvas coordinates.

## Define Your Edge Type

Create a type that conforms to ``FlowEdge``:

```swift
struct MyEdge: FlowEdge, Codable {
    let id: UUID
    var sourceNodeId: UUID
    var sourcePortId: UUID
    var targetNodeId: UUID
    var targetPortId: UUID
}
```

## Create Your View

Use ``CanvasView`` to display your nodes and edges:

```swift
struct MyFlowEditor: View {
    @State private var nodes: [MyNode] = []
    @State private var edges: [MyEdge] = []
    
    var body: some View {
        CanvasView(nodes: $nodes, edges: $edges) { node, isSelected in
            // Custom node view
            Text(node.title)
                .frame(width: node.width, height: node.height)
                .background(isSelected ? Color.blue.opacity(0.2) : Color.white)
                .cornerRadius(8)
        }
        .onConnectionCreated { sourceNode, sourcePort, targetNode, targetPort in
            edges.append(MyEdge(
                id: UUID(),
                sourceNodeId: sourceNode,
                sourcePortId: sourcePort,
                targetNodeId: targetNode,
                targetPortId: targetPort
            ))
        }
    }
}
```

## Add Configuration

Customize the canvas behavior with ``CanvasConfig``:

```swift
let config = CanvasConfig(
    zoom: ZoomConfig(min: 0.5, max: 2.0),
    grid: GridConfig.snapping,
    interaction: .default,
    edge: EdgeConfig(pathStyle: .smoothStep())
)

CanvasView(nodes: $nodes, edges: $edges, config: config) { ... }
```

## Next Steps

- Learn about the <doc:CoordinateSystem>
- Explore <doc:PortPositioning> options
- See ``CanvasController`` for programmatic control
- Browse the full API reference for advanced usage

## See Also

- <doc:QuickStart>
- ``CanvasView``
- ``CanvasConfig``
