# Coordinate System

Understanding SwiftFlow's three-space coordinate architecture.

## Overview

SwiftFlow uses a three-space coordinate system inspired by game engines and professional node editors. This architecture ensures consistent positioning and eliminates common bugs.

## The Three Spaces

### Canvas Space (Logical World)

Canvas space is where your data lives. This space never changes when you zoom or pan—it's your source of truth.

**What lives here:**
- `node.position` — Top-left corner of each node
- `node.bounds` — Full rectangle of the node
- Edge endpoints
- Port positions (after conversion from node-local)

**Characteristics:**
- Origin: Arbitrary (typically `(0, 0)` but can be negative)
- Units: Logical canvas units
- Immutable during pan/zoom
- This is what you serialize/deserialize

**Example:**

```swift
// Node at canvas position (100, 200) with size 150x80
let node = MyNode(
    position: CGPoint(x: 100, y: 200),  // Top-left in canvas
    width: 150,
    height: 80
)

// Node bounds in canvas space
print(node.bounds)  // CGRect(x: 100, y: 200, width: 150, height: 80)

// Node center (calculated from top-left)
print(node.center)  // CGPoint(x: 175, y: 240)
```

### Screen Space (Viewport)

Screen space is the actual pixel/point coordinates in the SwiftUI view. This is where gestures report their locations.

**What lives here:**
- User interactions (mouse clicks, drag gestures)
- Rendered positions of nodes
- SwiftUI coordinate system

**Characteristics:**
- Origin: Top-left of the viewport
- Units: Screen points/pixels
- Changes with zoom/pan
- Affected by ``FlowTransform``

### Node-Local Space

Node-local space is relative to a node's top-left corner. Used for ports, resize handles, and internal layout.

**Characteristics:**
- Origin: Node's top-left corner
- Units: Points relative to node
- Range: X ∈ [0, width], Y ∈ [0, height]

**Example:**

```swift
// Port at right-center (node-local)
let portLayout = PortLayout(preset: .rightCenter)
let nodeLocalPos = portLayout.position(nodeSize: node.size) // (150, 40)

// Port in canvas space
let canvasPos = CGPoint(
    x: node.position.x + nodeLocalPos.x,  // 100 + 150 = 250
    y: node.position.y + nodeLocalPos.y   // 200 + 40 = 240
)
```

## Coordinate Conversion

Use ``CanvasController`` to convert between spaces:

```swift
// Screen to Canvas (for drag & drop)
let canvasPosition = controller.project(screenPoint)

// Canvas to Screen (for rendering)
let screenPosition = controller.unproject(canvasPoint)
```

## Type-Safe Coordinates

SwiftFlow provides type-safe wrappers:

```swift
let screenPoint = ScreenPoint(x: 100, y: 200)
let canvasPoint = controller.project(screenPoint)  // Returns CanvasPoint
```

## Best Practices

1. **Always store positions in canvas space** — Save `node.position`, not screen coordinates
2. **Use node.position for all data** — It represents the top-left corner
3. **Convert at boundaries** — Only convert between spaces when necessary
4. **Trust the framework** — SwiftFlow handles most conversions automatically

## Common Pitfalls

❌ **Don't do this:**
```swift
// Wrong: Storing screen coordinates
node.position = gestureLocation  // Screen space!
```

✅ **Do this instead:**
```swift
// Correct: Convert to canvas space first
node.position = controller.project(gestureLocation)
```

## See Also

- ``FlowTransform``
- ``CanvasPoint``
- ``ScreenPoint``
- ``CanvasController/project(_:)-8syqe``
