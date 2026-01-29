# Quick Start

Get up and running with SwiftFlow in minutes.

## Installation

Add SwiftFlow to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/jeffryberdugox/SwiftFlow.git", from: "1.0.0")
]
```

### Accessing Documentation

After adding SwiftFlow to your project:

**In Xcode (Instant Help):**
- **Option+Click** on any SwiftFlow type (like `CanvasView`) to see Quick Help
- Click "Open in Developer Documentation" for the full interactive documentation

**Building Full Documentation:**
- Go to **Product → Build Documentation** (⌃⌘⇧D)
- Browse all articles, guides, and API reference interactively

**Online:**
- [Browse online documentation](https://jeffryberdugox.github.io/Swiftflow/documentation/swiftflow/)

> **Note:** Documentation is automatically available in Xcode through Quick Help. You don't need to download anything extra!

## Minimal Example

Here's the simplest possible SwiftFlow application:

```swift
import SwiftUI
import SwiftFlow

struct ContentView: View {
    @State private var nodes: [BasicNode] = [
        BasicNode(id: UUID(), title: "Start", position: CGPoint(x: 100, y: 100)),
        BasicNode(id: UUID(), title: "End", position: CGPoint(x: 300, y: 100))
    ]
    
    @State private var edges: [BasicEdge] = []
    
    var body: some View {
        CanvasView(nodes: $nodes, edges: $edges) { node, isSelected in
            Text(node.title)
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 2)
        }
        .onConnectionCreated { s, sp, t, tp in
            edges.append(BasicEdge(
                id: UUID(),
                sourceNodeId: s,
                sourcePortId: sp,
                targetNodeId: t,
                targetPortId: tp
            ))
        }
    }
}

struct BasicNode: FlowNode, Codable {
    let id: UUID
    var title: String
    var position: CGPoint
    var width: CGFloat = 120
    var height: CGFloat = 60
    
    var inputPorts: [any FlowPort] {
        [BasicPort(id: UUID(), position: .left)]
    }
    
    var outputPorts: [any FlowPort] {
        [BasicPort(id: UUID(), position: .right)]
    }
}

struct BasicPort: FlowPort, Codable {
    let id: UUID
    var position: PortPosition
}

struct BasicEdge: FlowEdge, Codable {
    let id: UUID
    var sourceNodeId: UUID
    var sourcePortId: UUID
    var targetNodeId: UUID
    var targetPortId: UUID
}
```

That's it! You now have a working node editor with:
- Interactive node dragging
- Connection creation between ports
- Zoom and pan support
- Multi-selection

## See Also

- <doc:GettingStarted>
- ``CanvasView``
- ``FlowNode``
