# 🎵 SwiftFlow for Vibecoders

> **For developers who code with AI assistants (Cursor, GitHub Copilot, etc.)**

This guide helps you and your AI coding buddy work effectively with SwiftFlow. It's optimized for natural language prompts and quick iterations.

---

## 🚀 Quick Start Prompts

### "Create a basic node editor"

```swift
import SwiftUI
import SwiftFlow

struct MyNode: FlowNode, Codable {
    let id: UUID
    var position: CGPoint
    var width: CGFloat = 200
    var height: CGFloat = 100
    var title: String
    
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
            Text(node.title)
                .frame(width: node.width, height: node.height)
                .background(isSelected ? Color.blue : Color.white)
                .cornerRadius(8)
                .shadow(radius: 2)
        }
        .onConnectionCreated { src, srcPort, tgt, tgtPort in
            edges.append(BasicEdge(
                id: UUID(),
                sourceNodeId: src,
                sourcePortId: srcPort,
                targetNodeId: tgt,
                targetPortId: tgtPort
            ))
        }
    }
}
```

### "Add a node with multiple input/output ports"

```swift
struct ProcessorNode: FlowNode, Codable {
    let id: UUID
    var position: CGPoint
    var width: CGFloat = 250
    var height: CGFloat = 150
    
    var inputPorts: [any FlowPort] {
        [
            BasicPort(id: UUID(), position: .left(offset: -40)),
            BasicPort(id: UUID(), position: .left(offset: 0)),
            BasicPort(id: UUID(), position: .left(offset: 40))
        ]
    }
    
    var outputPorts: [any FlowPort] {
        [
            BasicPort(id: UUID(), position: .right(offset: -20)),
            BasicPort(id: UUID(), position: .right(offset: 20))
        ]
    }
}
```

### "Add a toolbar with common actions"

```swift
struct EditorWithToolbar: View {
    @State private var nodes: [MyNode] = []
    @State private var edges: [BasicEdge] = []
    @State private var controller: CanvasController?
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button("➕ Add Node") { addNode() }
                Button("🗑️ Delete") { controller?.deleteSelectedNodes() }
                Button("↩️ Undo") { controller?.undo() }
                Button("↪️ Redo") { controller?.redo() }
                Button("🎯 Fit View") { controller?.fitView() }
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            // Canvas
            CanvasView(nodes: $nodes, edges: $edges) { node, isSelected in
                MyNodeView(node: node, isSelected: isSelected)
            }
            .onControllerCreated { controller = $0 }
            .onConnectionCreated { src, srcPort, tgt, tgtPort in
                edges.append(BasicEdge(
                    id: UUID(),
                    sourceNodeId: src,
                    sourcePortId: srcPort,
                    targetNodeId: tgt,
                    targetPortId: tgtPort
                ))
            }
        }
    }
    
    func addNode() {
        let newNode = MyNode(
            id: UUID(),
            position: .zero,
            title: "New Node"
        )
        nodes.append(newNode)
        controller?.centerOnNodes([newNode.id])
    }
}
```

---

## 🎨 Styling Prompts

### "Make edges blue with arrows"

```swift
CanvasView(nodes: $nodes, edges: $edges) { node, isSelected in
    MyNodeView(node: node)
}
.edgeColor(.blue)
.edgeWidth(2.0)
.showEdgeMarkers(true)
```

### "Add a minimap in bottom right"

```swift
CanvasView(nodes: $nodes, edges: $edges) { node, isSelected in
    MyNodeView(node: node)
}
.miniMap(
    position: .bottomRight,
    size: CGSize(width: 200, height: 150),
    nodeColor: .blue,
    backgroundColor: .white.opacity(0.95)
)
```

### "Use smooth curved edges"

```swift
CanvasView(nodes: $nodes, edges: $edges) { node, isSelected in
    MyNodeView(node: node)
}
.edgeStyle(.bezier)  // or .smoothStep, .straight
```

---

## 💡 Common Scenarios

### Scenario 1: "I want to add nodes by clicking on the canvas"

```swift
CanvasView(nodes: $nodes, edges: $edges) { node, isSelected in
    MyNodeView(node: node)
}
.onCanvasTapped { location, viewport in
    // Convert screen tap to canvas coordinates
    let canvasPos = screenToCanvas(location, viewport: viewport)
    
    let newNode = MyNode(
        id: UUID(),
        position: canvasPos,
        title: "Node \(nodes.count + 1)"
    )
    nodes.append(newNode)
}
```

### Scenario 2: "I want to save/load the canvas"

```swift
// Saving
func saveCanvas() {
    let data = CanvasData(nodes: nodes, edges: edges)
    if let encoded = try? JSONEncoder().encode(data) {
        UserDefaults.standard.set(encoded, forKey: "canvas")
    }
}

// Loading
func loadCanvas() {
    guard let data = UserDefaults.standard.data(forKey: "canvas"),
          let decoded = try? JSONDecoder().decode(CanvasData<MyNode>.self, from: data) else {
        return
    }
    nodes = decoded.nodes
    edges = decoded.edges
}

struct CanvasData<Node: FlowNode & Codable>: Codable {
    var nodes: [Node]
    var edges: [BasicEdge]
}
```

### Scenario 3: "I want custom node colors based on type"

```swift
enum NodeType: String, Codable {
    case input, process, output
    
    var color: Color {
        switch self {
        case .input: return .green
        case .process: return .blue
        case .output: return .orange
        }
    }
}

struct TypedNode: FlowNode, Codable {
    let id: UUID
    var position: CGPoint
    var width: CGFloat = 200
    var height: CGFloat = 100
    var type: NodeType
    var title: String
    
    var inputPorts: [any FlowPort] {
        type == .input ? [] : [BasicPort(id: UUID(), position: .left)]
    }
    
    var outputPorts: [any FlowPort] {
        type == .output ? [] : [BasicPort(id: UUID(), position: .right)]
    }
}

// In your view:
CanvasView(nodes: $nodes, edges: $edges) { node, isSelected in
    VStack {
        Text(node.title)
            .font(.headline)
        Text(node.type.rawValue)
            .font(.caption)
            .foregroundColor(.white.opacity(0.7))
    }
    .frame(width: node.width, height: node.height)
    .background(node.type.color)
    .cornerRadius(8)
    .overlay(
        RoundedRectangle(cornerRadius: 8)
            .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
    )
}
```

### Scenario 4: "I want to detect when connections are made"

```swift
CanvasView(nodes: $nodes, edges: $edges) { node, isSelected in
    MyNodeView(node: node)
}
.onConnectionCreated { sourceId, sourcePortId, targetId, targetPortId in
    print("Connected: \(sourceId) → \(targetId)")
    
    let newEdge = BasicEdge(
        id: UUID(),
        sourceNodeId: sourceId,
        sourcePortId: sourcePortId,
        targetNodeId: targetId,
        targetPortId: targetPortId
    )
    edges.append(newEdge)
    
    // Trigger any custom logic here
    processNewConnection(from: sourceId, to: targetId)
}
```

### Scenario 5: "I want keyboard shortcuts"

```swift
CanvasView(nodes: $nodes, edges: $edges) { node, isSelected in
    MyNodeView(node: node)
}
.onControllerCreated { controller = $0 }
.onKeyPress(.delete) {
    controller?.deleteSelectedNodes()
    return .handled
}
.onKeyPress("a", modifiers: .command) {
    // Select all
    nodes.forEach { controller?.selectNode(id: $0.id) }
    return .handled
}
.onKeyPress("z", modifiers: .command) {
    controller?.undo()
    return .handled
}
.onKeyPress("z", modifiers: [.command, .shift]) {
    controller?.redo()
    return .handled
}
```

---

## 🐛 Common Issues & Fixes

### Issue: "My nodes appear in the wrong place after zooming"

**Problem**: You're using screen coordinates instead of canvas coordinates.

**Fix**: Always work in canvas space for node positions.

```swift
// ❌ WRONG
node.position = gesture.location

// ✅ CORRECT
let canvasPos = screenToCanvas(gesture.location, viewport: viewport)
node.position = canvasPos
```

---

### Issue: "Edges don't connect to my ports correctly"

**Problem**: Port offsets are from edges, not corners.

**Fix**: Use the PortPosition enum correctly.

```swift
// ❌ WRONG - trying to put port at top-left corner
BasicPort(id: UUID(), position: .top(offset: -node.width/2))

// ✅ CORRECT - offset is from center of edge
BasicPort(id: UUID(), position: .top(offset: -50))
```

---

### Issue: "Undo/Redo doesn't work"

**Problem**: You're modifying state directly instead of using controller commands.

**Fix**: Use the controller for state changes you want tracked.

```swift
// ❌ WRONG - not tracked
nodes.removeAll { $0.id == selectedId }

// ✅ CORRECT - tracked for undo/redo
controller?.deleteNode(id: selectedId)
```

---

### Issue: "My custom node type won't compile"

**Problem**: Missing required protocol conformances.

**Fix**: Ensure FlowNode conformance is complete.

```swift
struct MyNode: FlowNode, Codable {
    let id: UUID                    // ✅ Required
    var position: CGPoint           // ✅ Required
    var width: CGFloat = 200        // ✅ Required
    var height: CGFloat = 100       // ✅ Required
    
    var inputPorts: [any FlowPort] {   // ✅ Required
        [BasicPort(id: UUID(), position: .left)]
    }
    
    var outputPorts: [any FlowPort] {  // ✅ Required
        [BasicPort(id: UUID(), position: .right)]
    }
}
```

---

## 🎯 AI Prompt Templates

### Template 1: Create Custom Node Type

```
Create a SwiftFlow node type called [NodeName] that:
- Has [number] input ports on the [left/top/etc] side
- Has [number] output ports on the [right/bottom/etc] side
- Stores [property1: Type] and [property2: Type]
- Is Codable for persistence
- Has a default size of [width]x[height]
```

### Template 2: Style the Canvas

```
Style my SwiftFlow canvas with:
- [color] edges with [width]pt thickness
- [bezier/smoothStep/straight] edge style
- [show/hide] edge markers
- A minimap in the [position] corner
- [color] background
```

### Template 3: Add Interaction

```
Add a [button/gesture/keyboard shortcut] that:
- [action description]
- Updates the canvas by [specific behavior]
- Uses the CanvasController to [operation]
```

---

## 🔥 Pro Tips

### Tip 1: Use Enums for Node Types

```swift
enum NodeCategory: String, Codable {
    case input, transform, output, utility
}

struct CategorizedNode: FlowNode, Codable {
    let id: UUID
    var position: CGPoint
    var width: CGFloat = 200
    var height: CGFloat = 100
    var category: NodeCategory
    var title: String
    
    // Ports based on category
    var inputPorts: [any FlowPort] {
        category == .input ? [] : [BasicPort(id: UUID(), position: .left)]
    }
    
    var outputPorts: [any FlowPort] {
        category == .output ? [] : [BasicPort(id: UUID(), position: .right)]
    }
}
```

### Tip 2: Create Node Templates

```swift
extension MyNode {
    static func input(at position: CGPoint) -> MyNode {
        MyNode(id: UUID(), position: position, title: "Input", type: .input)
    }
    
    static func process(at position: CGPoint, title: String) -> MyNode {
        MyNode(id: UUID(), position: position, title: title, type: .process)
    }
    
    static func output(at position: CGPoint) -> MyNode {
        MyNode(id: UUID(), position: position, title: "Output", type: .output)
    }
}

// Usage:
nodes.append(.input(at: CGPoint(x: 100, y: 100)))
nodes.append(.process(at: CGPoint(x: 300, y: 100), title: "Transform"))
nodes.append(.output(at: CGPoint(x: 500, y: 100)))
```

### Tip 3: Validate Connections

```swift
func isValidConnection(from sourceNode: MyNode, to targetNode: MyNode) -> Bool {
    // Prevent cycles
    if wouldCreateCycle(from: sourceNode.id, to: targetNode.id) {
        return false
    }
    
    // Type checking
    if sourceNode.outputType != targetNode.inputType {
        return false
    }
    
    // Max connections
    let existingConnections = edges.filter { $0.targetNodeId == targetNode.id }
    if existingConnections.count >= targetNode.maxInputs {
        return false
    }
    
    return true
}

// Use in onConnectionCreated:
.onConnectionCreated { src, srcPort, tgt, tgtPort in
    guard let srcNode = nodes.first(where: { $0.id == src }),
          let tgtNode = nodes.first(where: { $0.id == tgt }),
          isValidConnection(from: srcNode, to: tgtNode) else {
        return  // Don't create the edge
    }
    
    edges.append(BasicEdge(...))
}
```

### Tip 4: Auto-Layout Nodes

```swift
func layoutNodes() {
    let spacing: CGFloat = 250
    let startX: CGFloat = 100
    var currentY: CGFloat = 100
    
    for (index, node) in nodes.enumerated() {
        nodes[index].position = CGPoint(
            x: startX + (CGFloat(index % 3) * spacing),
            y: currentY
        )
        
        if (index + 1) % 3 == 0 {
            currentY += spacing
        }
    }
    
    controller?.fitView()
}
```

---

## 📚 Quick Reference

### Essential Imports
```swift
import SwiftUI
import SwiftFlow
```

### Minimal Node
```swift
struct MinimalNode: FlowNode, Codable {
    let id: UUID
    var position: CGPoint
    var width: CGFloat = 200
    var height: CGFloat = 100
    var inputPorts: [any FlowPort] { [] }
    var outputPorts: [any FlowPort] { [] }
}
```

### Minimal Canvas
```swift
@State private var nodes: [MyNode] = []
@State private var edges: [BasicEdge] = []

var body: some View {
    CanvasView(nodes: $nodes, edges: $edges) { node, isSelected in
        Text("Node")
            .frame(width: node.width, height: node.height)
            .background(Color.white)
    }
}
```

### Common Modifiers
```swift
.edgeStyle(.bezier)
.edgeColor(.blue)
.edgeWidth(2.0)
.showEdgeMarkers(true)
.miniMap(position: .bottomRight)
.onControllerCreated { controller = $0 }
.onConnectionCreated { ... }
.onNodeMoved { id, newPos in ... }
```

---

## 🌟 Example: Complete Node Editor

Here's a full example you can copy and modify:

```swift
import SwiftUI
import SwiftFlow

// MARK: - Node Definition
struct ProcessNode: FlowNode, Codable {
    let id: UUID
    var position: CGPoint
    var width: CGFloat = 220
    var height: CGFloat = 120
    var title: String
    var color: Color
    
    var inputPorts: [any FlowPort] {
        [BasicPort(id: UUID(), position: .left)]
    }
    
    var outputPorts: [any FlowPort] {
        [BasicPort(id: UUID(), position: .right)]
    }
    
    enum CodingKeys: String, CodingKey {
        case id, position, width, height, title, color
    }
    
    init(id: UUID, position: CGPoint, title: String, color: Color) {
        self.id = id
        self.position = position
        self.title = title
        self.color = color
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        position = try container.decode(CGPoint.self, forKey: .position)
        width = try container.decode(CGFloat.self, forKey: .width)
        height = try container.decode(CGFloat.self, forKey: .height)
        title = try container.decode(String.self, forKey: .title)
        let colorString = try container.decode(String.self, forKey: .color)
        color = Color.fromString(colorString)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(position, forKey: .position)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encode(title, forKey: .title)
        try container.encode(color.toString(), forKey: .color)
    }
}

// MARK: - Main Editor View
struct NodeEditorView: View {
    @State private var nodes: [ProcessNode] = []
    @State private var edges: [BasicEdge] = []
    @State private var controller: CanvasController?
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar
            
            // Canvas
            CanvasView(nodes: $nodes, edges: $edges) { node, isSelected in
                NodeView(node: node, isSelected: isSelected)
            }
            .edgeStyle(.bezier)
            .edgeColor(.blue)
            .showEdgeMarkers(true)
            .miniMap(position: .bottomRight)
            .onControllerCreated { controller = $0 }
            .onConnectionCreated { src, srcPort, tgt, tgtPort in
                edges.append(BasicEdge(
                    id: UUID(),
                    sourceNodeId: src,
                    sourcePortId: srcPort,
                    targetNodeId: tgt,
                    targetPortId: tgtPort
                ))
            }
        }
    }
    
    var toolbar: some View {
        HStack(spacing: 12) {
            Button(action: addNode) {
                Label("Add Node", systemImage: "plus.circle.fill")
            }
            
            Button(action: { controller?.deleteSelectedNodes() }) {
                Label("Delete", systemImage: "trash")
            }
            
            Divider()
            
            Button(action: { controller?.undo() }) {
                Label("Undo", systemImage: "arrow.uturn.backward")
            }
            
            Button(action: { controller?.redo() }) {
                Label("Redo", systemImage: "arrow.uturn.forward")
            }
            
            Divider()
            
            Button(action: { controller?.fitView() }) {
                Label("Fit View", systemImage: "arrow.up.left.and.arrow.down.right")
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
    
    func addNode() {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink]
        let newNode = ProcessNode(
            id: UUID(),
            position: CGPoint(x: 100, y: 100),
            title: "Node \(nodes.count + 1)",
            color: colors.randomElement()!
        )
        nodes.append(newNode)
        controller?.centerOnNodes([newNode.id])
    }
}

// MARK: - Node View
struct NodeView: View {
    let node: ProcessNode
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text(node.title)
                .font(.headline)
                .foregroundColor(.white)
            
            Text("ID: \(node.id.uuidString.prefix(8))")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(width: node.width, height: node.height)
        .background(node.color)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
        )
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Color Extensions
extension Color {
    func toString() -> String {
        if self == .blue { return "blue" }
        if self == .green { return "green" }
        if self == .orange { return "orange" }
        if self == .purple { return "purple" }
        if self == .pink { return "pink" }
        return "gray"
    }
    
    static func fromString(_ string: String) -> Color {
        switch string {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        default: return .gray
        }
    }
}
```

---

## 🎓 Learning Path

1. **Start Simple**: Copy the minimal example above
2. **Add Interactions**: Try the toolbar buttons
3. **Customize Nodes**: Change colors, sizes, add properties
4. **Handle Connections**: Add validation and logic
5. **Save/Load**: Implement persistence
6. **Advanced Features**: MiniMap, helper lines, custom gestures

---

## 🔗 Resources

- **Full Documentation**: [SwiftFlow Docs](https://jeffryberdugox.github.io/SwiftFlow/documentation/swiftflow/)
- **Getting Started**: [Tutorial](https://jeffryberdugox.github.io/SwiftFlow/documentation/swiftflow/gettingstarted)
- **Coordinate System**: [Deep Dive](https://jeffryberdugox.github.io/SwiftFlow/documentation/swiftflow/coordinatesystem)
- **GitHub**: [Issues & Discussions](https://github.com/jeffryberdugox/SwiftFlow)

---

**Happy Vibing! 🎵✨**

Use this guide with your AI coding assistant to build amazing node-based interfaces in SwiftUI. When in doubt, ask your AI to reference this guide.
