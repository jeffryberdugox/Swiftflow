# SwiftFlow

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS%2013.0+-lightgrey.svg)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![SwiftPM](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager)
[![Documentation](https://img.shields.io/badge/docs-Swift%20DocC-blue)](https://jeffryberdugox.github.io/SwiftFlow/documentation/swiftflow/)

A modern, declarative node-based editor framework for SwiftUI.

> Inspired by [React Flow](https://reactflow.dev/), SwiftFlow brings professional node-based editing to the Swift ecosystem.

---

## ✨ Features

- **Declarative API** — Built entirely with SwiftUI for seamless integration
- **Interactive Nodes** — Drag, resize, multi-select with keyboard shortcuts
- **Flexible Edges** — Bezier, SmoothStep, and Straight paths with custom markers
- **Three-Space Coordinates** — Predictable positioning that eliminates common bugs
- **Command Pattern** — Full undo/redo support for all operations
- **Interactive MiniMap** — Bird's-eye view with navigation
- **Helper Lines** — Snap-to-align with visual guides and haptic feedback
- **Zero Dependencies** — Lightweight and easy to integrate

---

## 🚀 Quick Start

```swift
import SwiftUI
import SwiftFlow

struct MyNode: FlowNode, Codable {
    let id: UUID
    var position: CGPoint
    var width: CGFloat = 200
    var height: CGFloat = 100
    
    var inputPorts: [any FlowPort] {
        [BasicPort(id: UUID(), position: .left)]
    }
    var outputPorts: [any FlowPort] {
        [BasicPort(id: UUID(), position: .right)]
    }
}

struct ContentView: View {
    @State private var nodes: [MyNode] = []
    @State private var edges: [BasicEdge] = []
    
    var body: some View {
        CanvasView(nodes: $nodes, edges: $edges) { node, isSelected in
            Text("Node")
                .frame(width: node.width, height: node.height)
                .background(Color.white)
                .cornerRadius(8)
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
```

**👉 [Read the full Getting Started guide](https://jeffryberdugox.github.io/SwiftFlow/documentation/swiftflow/gettingstarted)**

---

## 📦 Installation

### Swift Package Manager

Add SwiftFlow to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/jeffryberdugox/SwiftFlow.git", from: "1.0.0")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/jeffryberdugox/SwiftFlow`
3. Add to your target

---

## 📚 Documentation

SwiftFlow uses **Swift-DocC** for interactive, Xcode-integrated documentation.

### Quick Access

- **[Online Documentation](https://jeffryberdugox.github.io/SwiftFlow/documentation/swiftflow/)** — Browse online
- **[Getting Started](https://jeffryberdugox.github.io/SwiftFlow/documentation/swiftflow/gettingstarted)** — Step-by-step tutorial
- **[API Reference](https://jeffryberdugox.github.io/SwiftFlow/documentation/swiftflow/)** — Complete API documentation
- **[Coordinate System](https://jeffryberdugox.github.io/SwiftFlow/documentation/swiftflow/coordinatesystem)** — Understanding the three-space architecture

### In Xcode

After adding SwiftFlow to your project:
- **Option+Click** on any symbol → Instant documentation
- **Product → Build Documentation** (⌃⌘⇧D) → Browse everything

> Documentation is automatically available in Xcode through Quick Help. No extra setup needed!

---

## 🎯 What Can You Build?

- **Visual Programming Tools** — Node-based coding environments
- **Workflow Editors** — Automation and process builders  
- **Diagram Applications** — Flowcharts, mind maps, UML
- **Data Pipeline Builders** — ETL and data processing tools
- **State Machine Editors** — Visual state management
- **Audio/Video Processing** — Node-based effects chains

---

## 💡 Core Concepts

SwiftFlow is built around three key protocols:

- **`FlowNode`** — Nodes in your graph (position, size, ports)
- **`FlowEdge`** — Connections between nodes
- **`FlowPort`** — Connection points on nodes

Everything else is built on top of these simple primitives.

[Learn more in the documentation →](https://jeffryberdugox.github.io/SwiftFlow/documentation/swiftflow/)

---

## 🛠️ Requirements

- macOS 13.0+
- Swift 5.9+
- Xcode 15.0+

---

## 🤝 Contributing

Contributions are welcome! We appreciate your interest in improving SwiftFlow.

- **Found a bug?** [Open an issue](https://github.com/jeffryberdugox/SwiftFlow/issues/new)
- **Have a feature idea?** [Start a discussion](https://github.com/jeffryberdugox/SwiftFlow/discussions)
- **Want to contribute code?** Check out our [Contributing Guide](CONTRIBUTING.md)

Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before participating.

---

## ⚖️ License

SwiftFlow is released under the MIT License. See [LICENSE](LICENSE) for details.

```
MIT License - Copyright (c) 2026 Jeffry Berdugo
```

---

## 🙏 Acknowledgments

SwiftFlow was heavily inspired by and built upon the excellent work of the open-source community.

### Primary Inspirations

SwiftFlow wouldn't exist without the incredible work of these projects:

- **[React Flow](https://reactflow.dev/)** — A heartfelt thank you to the React Flow team for pioneering accessible node-based editors on the web. Your elegant API design, thoughtful coordinate system architecture, and battle-tested interaction patterns served as the foundation for SwiftFlow's approach. We learned so much from studying your implementation.

Thank you for making your work open source and for building a community where others can learn and grow. 💙

---

## 📞 Support

- **Documentation**: [Swift-DocC Documentation](https://jeffryberdugox.github.io/SwiftFlow/documentation/swiftflow/)
- **Issues**: [GitHub Issues](https://github.com/jeffryberdugox/SwiftFlow/issues)
- **Discussions**: [GitHub Discussions](https://github.com/jeffryberdugox/SwiftFlow/discussions)

---

**Made with ❤️ by [Jeffry Berdugo](https://github.com/jeffryberdugox)**
