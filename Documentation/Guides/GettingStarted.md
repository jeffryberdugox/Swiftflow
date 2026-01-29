# Getting Started with SwiftFlow

This guide will help you create your first node-based editor with SwiftFlow.

## Installation

Add SwiftFlow to your project using Swift Package Manager:

```swift
dependencies: [
    .package(path: "../Packages/SwiftFlow")
]
```

## Quick Start

### 1. Define Your Node Type

```swift
import SwiftFlow

struct MyNode: FlowNode, Codable, Identifiable {
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

### 2. Define Your Edge Type

```swift
struct MyEdge: FlowEdge, Codable, Identifiable {
    let id: UUID
    var sourceNodeId: UUID
    var sourcePortId: UUID
    var targetNodeId: UUID
    var targetPortId: UUID
}
```

### 3. Create Your View

```swift
struct MyFlowEditor: View {
    @State private var nodes: [MyNode] = []
    @State private var edges: [MyEdge] = []
    
    var body: some View {
        CanvasView(nodes: $nodes, edges: $edges) { node, isSelected in
            // Your custom node view
            NodeView(node: node, isSelected: isSelected)
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

## Configuration

### Using Presets

```swift
// Default configuration
CanvasView(nodes: $nodes, edges: $edges, config: .default) { ... }

// Minimal (no grid, no minimap)
CanvasView(nodes: $nodes, edges: $edges, config: .minimal) { ... }

// Presentation mode (view only)
CanvasView(nodes: $nodes, edges: $edges, config: .presentation) { ... }
```

### Custom Configuration

```swift
let config = CanvasConfig(
    zoom: ZoomConfig(min: 0.5, max: 2.0),
    grid: GridConfig.snapping,
    interaction: .default,
    edge: EdgeConfig(pathStyle: .smoothStep())
)

CanvasView(nodes: $nodes, edges: $edges, config: config) { ... }
```

## Using the Controller

For programmatic control, use a `CanvasController`:

```swift
struct MyFlowEditor: View {
    @State private var nodes: [MyNode] = []
    @State private var edges: [MyEdge] = []
    @StateObject private var controller = CanvasController()
    
    var body: some View {
        VStack {
            // Toolbar
            HStack {
                Button("Zoom In") { controller.zoomIn() }
                Button("Zoom Out") { controller.zoomOut() }
                Button("Fit View") { controller.fitView() }
                Button("Undo") { controller.undo() }
                    .disabled(!controller.canUndo)
            }
            
            // Canvas with controller
            CanvasView(
                nodes: $nodes,
                edges: $edges,
                controller: controller
            ) { node, isSelected in
                NodeView(node: node, isSelected: isSelected)
            }
        }
    }
}
```

## Commands and Transactions

### Single Commands

```swift
// Execute single operations
controller.perform(.moveNodes(ids: selectedIds, delta: CGSize(width: 10, height: 0)))
controller.perform(.deleteSelection)
controller.perform(.createEdge(sourceNode: s, sourcePort: sp, targetNode: t, targetPort: tp))
```

### Transactions (Batch Undo)

```swift
// Multiple operations as one undo
controller.transaction("Auto Layout") {
    .moveNodeTo(id: node1, position: CanvasPoint(x: 100, y: 100))
    .moveNodeTo(id: node2, position: CanvasPoint(x: 300, y: 100))
    .moveNodeTo(id: node3, position: CanvasPoint(x: 500, y: 100))
}

// Single undo reverts all three moves
controller.undo()
```

## Callbacks and Modifiers

```swift
CanvasView(nodes: $nodes, edges: $edges) { node, isSelected in
    NodeView(node: node, isSelected: isSelected)
}
.onNodeMoved { node, newPosition in
    print("Node moved to \(newPosition)")
}
.onSelectionChanged { selectedIds in
    print("Selected \(selectedIds.count) nodes")
}
.onConnectionCreated { s, sp, t, tp in
    // Handle new connection
}
.miniMap(.bottomTrailing)
.grid(.dots, snap: true)
```

## Type-Safe Coordinates

SwiftFlow includes optional type-safe coordinate types:

```swift
// Screen vs Canvas coordinates
let screenPoint = ScreenPoint(x: 100, y: 200)
let canvasPoint = controller.transform.toCanvas(screenPoint)

// Viewport center sentinel
controller.zoomIn(at: .viewportCenter)

// Rectangle conversion
let viewportRect = controller.transform.toCanvasRect(
    CGRect(origin: .zero, size: viewportSize)
)
```

## Accessing Canvas Data

The controller provides methods to access current canvas state:

```swift
// Get current nodes and edges
let nodes = controller.getNodes()
let edges = controller.getEdges()

// Get specific element
if let node = controller.getNode(id: nodeId) {
    print("Node position: \(node.wrappedValue.position)")
}

// Export complete state
let state = controller.toObject()
print("Current zoom: \(state["viewport"]!["zoom"]!)")
```

## Drag & Drop from Outside Canvas

Use `project()` to convert external drag coordinates to canvas space:

```swift
.onDrop(of: [.text]) { providers, location in
    // Convert drop location to canvas coordinates
    let canvasPosition = controller.project(location)
    
    // Create node at that position
    let newNode = MyNode(
        id: UUID(),
        title: "Dropped Node",
        position: canvasPosition
    )
    nodes.append(newNode)
    
    return true
}
```

## Next Steps

- Check out the [API Reference](../API-Reference.md) for complete documentation
- See [Examples](../../Examples/) for working code
- Read the [Migration Guide](../../MIGRATION.md) if upgrading from 1.x
