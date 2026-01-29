# SwiftFlow Coordinate System Guide

This guide explains the coordinate system architecture used throughout SwiftFlow, how to work with it correctly, and common patterns for avoiding coordinate-related bugs.

## Overview

SwiftFlow uses a **three-space coordinate system** inspired by game engines and professional node editors (Unreal Blueprint, Nuke, Figma). This architecture ensures consistent positioning, smooth interactions, and eliminates common bugs like "drift" during zoom/pan or resize operations.

---

## The Three Coordinate Spaces

### 1. Canvas Space (Logical World)

**Canvas space** is the logical coordinate system where all your data lives. This space never changes when you zoom or pan—it's your source of truth.

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

---

### 2. Screen Space (Viewport)

**Screen space** is the actual pixel/point coordinates in the SwiftUI view. This is what the user sees and where gestures report their locations.

**What lives here:**
- Gesture locations (`DragGesture.value.location`)
- Viewport size
- Rendered positions (after applying transform)
- UI elements (controls, overlays)

**Characteristics:**
- Origin: Top-left of the view (0, 0)
- Units: Points (on macOS/iOS)
- Changes with pan/zoom
- Affected by `FlowTransform`

**Example:**
```swift
// User drags at screen position (300, 400)
DragGesture()
    .onChanged { value in
        let screenPos = value.location  // CGPoint(x: 300, y: 400)
        
        // Convert to canvas before modifying nodes
        let canvasPos = transform.screenToCanvas(screenPos)
        
        // Now safe to use with node positions
        updateNodePosition(to: canvasPos)
    }
```

---

### 3. Node-Local Space

**Node-local space** is relative to an individual node's top-left corner. This is used for ports, resize handles, and internal node layout.

**What lives here:**
- Port offsets within a node
- Resize handle positions
- Custom node content layout

**Characteristics:**
- Origin: Node's top-left corner `(0, 0)`
- Range: `X ∈ [0, node.width]`, `Y ∈ [0, node.height]`
- Independent of node position
- Scales/adapts during resize (for presets)

**Example:**
```swift
// Port at right-center of node
let portLayout = PortLayout(preset: .rightCenter)

// For a 200x100 node, this calculates to:
let nodeLocalPos = portLayout.position(nodeSize: CGSize(width: 200, height: 100))
// → CGPoint(x: 200, y: 50)

// Convert to canvas coordinates
let canvasPos = CGPoint(
    x: node.position.x + nodeLocalPos.x,
    y: node.position.y + nodeLocalPos.y
)
```

---

## Coordinate Transformations

### Canvas ↔ Screen (via FlowTransform)

The `FlowTransform` handles all conversions between canvas and screen space. **Important**: The `offset` in FlowTransform is always in **screen space** (the pan translation), not canvas space.

```swift
// Transform contains pan offset (screen space) and zoom scale
let transform = FlowTransform(
    offset: CGPoint(x: 50, y: 30),  // Pan translation in SCREEN space
    scale: 2.0                       // 200% zoom
)

// Canvas → Screen
let canvasPoint = CGPoint(x: 100, y: 100)
let screenPoint = transform.canvasToScreen(canvasPoint)
// Formula: screenPoint = canvasPoint * scale + offset
// Result: CGPoint(x: 250, y: 230)

// Screen → Canvas
let backToCanvas = transform.screenToCanvas(screenPoint)
// Formula: canvasPoint = (screenPoint - offset) / scale
// Result: CGPoint(x: 100, y: 100) ✓
```

**Transform Architecture**:
- `offset`: Pan translation in screen space (where the camera moved to)
- `scale`: Zoom multiplier (1.0 = 100%, 2.0 = 200%)
- Apply order: `screen = canvas * scale + offset`

**Available conversions:**
- `screenToCanvas(_: CGPoint) -> CGPoint`
- `canvasToScreen(_: CGPoint) -> CGPoint`
- `screenToCanvas(_: CGSize) -> CGSize`
- `canvasToScreen(_: CGSize) -> CGSize`
- `screenToCanvas(_: CGRect) -> CGRect`
- `canvasToScreen(_: CGRect) -> CGRect`

---

### Node-Local ↔ Canvas

Node-local coordinates are converted using simple addition/subtraction:

```swift
// Node-Local → Canvas
let nodeLocalPoint = CGPoint(x: 50, y: 25)  // Port position within node
let nodeTopLeft = node.position              // e.g., CGPoint(x: 100, y: 200)

let canvasPoint = CGPoint(
    x: nodeTopLeft.x + nodeLocalPoint.x,  // 100 + 50 = 150
    y: nodeTopLeft.y + nodeLocalPoint.y   // 200 + 25 = 225
)

// Canvas → Node-Local
let canvasPoint = CGPoint(x: 150, y: 225)
let nodeLocalPoint = CGPoint(
    x: canvasPoint.x - nodeTopLeft.x,  // 150 - 100 = 50
    y: canvasPoint.y - nodeTopLeft.y   // 225 - 200 = 25
)
```

**Helper extensions:**
```swift
// Direct conversion helpers
let canvasPos = transform.nodeLocalToCanvas(localPoint, nodeTopLeft: node.position)
let localPos = transform.canvasToNodeLocal(canvasPoint, nodeTopLeft: node.position)

// Chained conversions
let screenPos = transform.nodeLocalToScreen(localPoint, nodeTopLeft: node.position)
let localPos = transform.screenToNodeLocal(screenPoint, nodeTopLeft: node.position)
```

---

## Golden Rules

Follow these rules to avoid coordinate bugs:

### 1. Always Know Which Space You're In

Name your variables clearly to indicate the coordinate space:

```swift
// ✅ GOOD: Clear naming
let canvasPosition = CGPoint(x: 100, y: 200)
let screenPosition = gesture.location
let nodeLocalOffset = CGPoint(x: 50, y: 25)

// ❌ BAD: Ambiguous naming
let position = CGPoint(x: 100, y: 200)  // Which space?
let point = gesture.location            // Where does this come from?
let offset = CGPoint(x: 50, y: 25)      // Offset from what?
```

### 2. Model = Canvas

Your data model always stores positions in canvas space:

```swift
// ✅ GOOD: Model in canvas space
struct MyNode: FlowNode {
    var position: CGPoint  // Canvas coordinates (top-left)
    var width: CGFloat
    var height: CGFloat
}

// ❌ BAD: Never store screen coordinates in model
struct BadNode {
    var screenPosition: CGPoint  // This will break on pan/zoom!
}
```

### 3. Camera = Transform

Pan and zoom only modify the transform, never the model:

```swift
// ✅ GOOD: Pan updates transform
func handlePan(_ delta: CGSize) {
    transform = transform.panned(by: delta)
    // Nodes don't move in canvas space!
}

// ❌ BAD: Moving nodes to simulate pan
func badPan(_ delta: CGSize) {
    for node in nodes {
        node.position.x += delta.width  // Wrong!
        node.position.y += delta.height
    }
}
```

### 4. View = Model × Camera

What the user sees is the canvas data transformed to screen. **Important**: SwiftUI's `.position()` expects the CENTER of a view, but our `node.position` is the TOP-LEFT in canvas space, so we must convert:

```swift
// Rendering with proper coordinate conversion
ZStack {
    ForEach(nodes) { node in
        NodeView(node: node)
            .frame(width: node.width, height: node.height)
            // CRITICAL: .position() expects CENTER, but node.position is TOP-LEFT
            // Convert top-left to center for SwiftUI
            .position(
                x: node.position.x + node.width / 2,
                y: node.position.y + node.height / 2
            )
    }
}
.modifier(CanvasTransformModifier(transform: transform))  // Applied to entire layer

// Alternative using offset (if your base layout uses top-left):
ZStack {
    ForEach(nodes) { node in
        NodeView(node: node)
            .frame(width: node.width, height: node.height)
            .offset(x: node.position.x, y: node.position.y)
    }
}
.modifier(CanvasTransformModifier(transform: transform))
```

### 5. Input = View → Model

Always convert gesture input to canvas before modifying nodes. **Gestures always report in screen space**, regardless of `coordinateSpace` modifiers:

```swift
// ✅ GOOD: Convert then modify
DragGesture()  // Reports in screen space
    .onChanged { value in
        // ALWAYS convert to canvas first
        let canvasPos = transform.screenToCanvas(value.location)
        node.position = canvasPos  // Canvas space ✓
    }

// Also correct with coordinateSpace (still need to convert):
DragGesture(coordinateSpace: .named("canvas"))
    .onChanged { value in
        // coordinateSpace only affects origin alignment,
        // still need to convert through transform
        let canvasPos = transform.screenToCanvas(value.location)
        node.position = canvasPos
    }

// ❌ BAD: Direct screen-to-model
DragGesture()
    .onChanged { value in
        node.position = value.location  // Wrong space!
    }
```

### 6. Never Mix Spaces

Always convert explicitly before calculations:

```swift
// ✅ GOOD: Explicit conversion
let screenRect = selectionRectangle  // Screen space
let canvasRect = transform.screenToCanvas(screenRect)
let intersects = node.bounds.intersects(canvasRect)  // Both canvas ✓

// ❌ BAD: Mixed spaces
let intersects = node.bounds.intersects(screenRect)  // Different spaces!
```

---

## Common Patterns

### Pattern 1: Drag Node

Maintain the grab point during drag. **Important**: Gestures report in screen space by default, even with `coordinateSpace: .named("canvas")` (which only affects coordinate origin, not the transform).

```swift
// 1. On drag start: capture initial state
var dragOffset: CGSize = .zero

func startDrag(at screenPoint: CGPoint) {
    // ALWAYS convert screen to canvas first
    let canvasPoint = transform.screenToCanvas(screenPoint)
    let nodeTopLeft = node.position
    
    // Offset from cursor to node's top-left
    dragOffset = CGSize(
        width: nodeTopLeft.x - canvasPoint.x,
        height: nodeTopLeft.y - canvasPoint.y
    )
}

// 2. On drag update: maintain offset
func updateDrag(to screenPoint: CGPoint) {
    // Convert screen to canvas
    let canvasPoint = transform.screenToCanvas(screenPoint)
    
    // New top-left = cursor + offset
    node.position = CGPoint(
        x: canvasPoint.x + dragOffset.width,
        y: canvasPoint.y + dragOffset.height
    )
}
```

**Note on coordinateSpace**: Using `.coordinateSpace(.named("canvas"))` on a DragGesture can help align coordinate origins with your canvas layer, but the gesture values still need conversion through `screenToCanvas()` because they don't automatically un-apply your visual transform (scale/offset). The safest approach is to always convert explicitly.

---

### Pattern 2: Zoom with Pivot

Keep the point under the cursor fixed during zoom:

```swift
func zoom(factor: CGFloat, at screenPivot: CGPoint) {
    // 1. Convert pivot to canvas BEFORE zoom
    let canvasPivot = transform.screenToCanvas(screenPivot)
    
    // 2. Apply new scale
    let newScale = clamp(transform.scale * factor, min: 0.1, max: 4.0)
    
    // 3. Adjust offset so canvasPivot stays under screenPivot
    let newOffset = CGPoint(
        x: screenPivot.x - canvasPivot.x * newScale,
        y: screenPivot.y - canvasPivot.y * newScale
    )
    
    transform = FlowTransform(offset: newOffset, scale: newScale)
}
```

---

### Pattern 3: Calculate Port Position

Use the new port positioning system:

```swift
// 1. Define port with preset + optional offset
struct MyPort: FlowPort {
    let id = UUID()
    let position: PortPosition = .right  // For edge path calculation
    let layout = PortLayout(preset: .rightCenter, offset: CGPoint(x: 5, y: 0))
}

// 2. Calculate canvas position
func portCanvasPosition(port: MyPort, node: MyNode) -> CGPoint {
    // Get node-local position from layout
    let nodeSize = CGSize(width: node.width, height: node.height)
    let nodeLocalPos = port.layout.position(nodeSize: nodeSize)
    
    // Convert to canvas coordinates
    return CGPoint(
        x: node.position.x + nodeLocalPos.x,
        y: node.position.y + nodeLocalPos.y
    )
}

// 3. During resize, layout adapts automatically
// Presets recalculate based on new node size
// Custom offsets stay fixed relative to top-left
```

---

### Pattern 4: Box Selection

Select nodes within a marquee rectangle:

```swift
func updateSelection(start: CGPoint, end: CGPoint) {
    // 1. Create selection rectangle in screen space
    let screenRect = CGRect(
        x: min(start.x, end.x),
        y: min(start.y, end.y),
        width: abs(end.x - start.x),
        height: abs(end.y - start.y)
    )
    
    // 2. Convert to canvas space
    let canvasRect = transform.screenToCanvas(screenRect)
    
    // 3. Check intersection with node bounds (all canvas)
    let selectedNodes = nodes.filter { node in
        canvasRect.intersects(node.bounds)
    }
}
```

---

### Pattern 5: Resize with Anchors

Handle different resize anchors correctly:

```swift
func resize(handle: ResizeHandle, delta: CGSize) {
    var newSize = initialSize
    var newTopLeft = initialPosition
    
    switch handle {
    case .topLeft:
        // Top-left moves with handle
        newSize.width = max(minWidth, initialSize.width - delta.width)
        newSize.height = max(minHeight, initialSize.height - delta.height)
        newTopLeft.x = initialPosition.x + (initialSize.width - newSize.width)
        newTopLeft.y = initialPosition.y + (initialSize.height - newSize.height)
        
    case .bottomRight:
        // Top-left stays fixed, only size changes
        newSize.width = max(minWidth, initialSize.width + delta.width)
        newSize.height = max(minHeight, initialSize.height + delta.height)
        // newTopLeft doesn't change
        
    case .right:
        // Only width changes, height and position stay
        newSize.width = max(minWidth, initialSize.width + delta.width)
    }
    
    node.width = newSize.width
    node.height = newSize.height
    node.position = newTopLeft
}
```

---

## Port Positioning System

SwiftFlow provides a flexible port positioning system with presets and custom offsets:

### Port Presets

Presets automatically adapt to node size changes:

```swift
// Built-in presets
PortPreset.topLeft        // (0, 0)
PortPreset.topCenter      // (width/2, 0)
PortPreset.topRight       // (width, 0)
PortPreset.leftCenter     // (0, height/2)
PortPreset.center         // (width/2, height/2)
PortPreset.rightCenter    // (width, height/2)
PortPreset.bottomLeft     // (0, height)
PortPreset.bottomCenter   // (width/2, height)
PortPreset.bottomRight    // (width, height)
PortPreset.custom(point)  // Fixed position
```

### Port Layout

Combine presets with custom offsets. **Important**: Custom offsets are in **absolute node-local coordinates** (not percentage). They don't automatically scale during resize - only presets adapt to size changes.

```swift
// Preset only (adapts to node size automatically)
let layout1 = PortLayout(preset: .rightCenter)

// Preset with fixed offset (offset stays constant during resize)
let layout2 = PortLayout(
    preset: .rightCenter,
    offset: CGPoint(x: 10, y: -5)  // Fixed 10px right, 5px up
)

// Fully custom position (fixed coordinates from top-left)
let layout3 = PortLayout(preset: .custom(CGPoint(x: 50, y: 30)))

// Convenience helpers
let layout4 = PortLayout.leftCenter(offsetY: 20)
let layout5 = PortLayout.topCenter(offsetX: -10)
```

**Resize Behavior**:
- **Presets** (`.rightCenter`, `.topCenter`, etc.) recalculate based on new node size
- **Custom offsets** stay fixed relative to top-left (don't scale)
- **Custom preset** (`.custom(point)`) stays at exact coordinates

If you want proportional ports that scale with the node, use a preset. If you want ports at fixed positions regardless of size, use custom or add fixed offsets.

### Using Port Layouts

```swift
struct MyPort: FlowPort {
    let id = UUID()
    let position: PortPosition = .right
    
    // Define layout (default uses preset from position)
    let layout = PortLayout(preset: .rightCenter, offset: CGPoint(x: 5, y: 0))
}

// Layout adapts to node size automatically
let nodeSize = CGSize(width: 200, height: 100)
let portPos = port.layout.position(nodeSize: nodeSize)
// → rightCenter (200, 50) + offset (5, 0) = (205, 50)
```

---

## MiniMap Coordinate System

The MiniMap component uses a **fourth coordinate space** to display a bird's-eye view of the entire canvas. Understanding how MiniMap coordinates work is crucial for customization and debugging.

### MiniMap Space

**MiniMap space** is a scaled-down representation of canvas space that fits within the minimap view bounds (e.g., 200x150 pixels).

**What lives here:**
- Scaled node representations
- Viewport indicator rectangle
- MiniMap gestures and interactions

**Characteristics:**
- Origin: Top-left of minimap view (0, 0)
- Units: Points (scaled from canvas)
- Fixed size defined by `MiniMapConfig`
- Independent rendering layer (overlay)

### MiniMap Coordinate Conversions

The `MiniMapViewModel` handles all conversions between Canvas and MiniMap space:

```swift
// 1. Calculate content bounds in canvas space
let contentBounds = calculateNodesBounds(nodes) + padding

// 2. Calculate scale to fit content in minimap
let scaleX = miniMapWidth / contentBounds.width
let scaleY = miniMapHeight / contentBounds.height
let miniMapScale = min(scaleX, scaleY)

// 3. Calculate centering offset (if content is smaller than minimap)
let scaledContentWidth = contentBounds.width * miniMapScale
let scaledContentHeight = contentBounds.height * miniMapScale
let miniMapOffset = CGPoint(
    x: (miniMapWidth - scaledContentWidth) / 2,
    y: (miniMapHeight - scaledContentHeight) / 2
)
```

### Canvas → MiniMap Conversion

```swift
func canvasToMiniMap(_ canvasPoint: CGPoint) -> CGPoint {
    // 1. Translate relative to content bounds
    let relativeToContent = CGPoint(
        x: canvasPoint.x - contentBounds.minX,
        y: canvasPoint.y - contentBounds.minY
    )
    
    // 2. Scale and apply centering offset
    return CGPoint(
        x: relativeToContent.x * miniMapScale + miniMapOffset.x,
        y: relativeToContent.y * miniMapScale + miniMapOffset.y
    )
}
```

**Example:**
```swift
// Node at canvas (100, 200)
let canvasPos = CGPoint(x: 100, y: 200)

// With contentBounds starting at (0, 0), scale 0.5, offset (10, 10):
// relativeToContent = (100, 200)
// scaled = (50, 100)
// miniMapPos = (60, 110)
let miniMapPos = viewModel.canvasToMiniMap(canvasPos)
```

### MiniMap → Canvas Conversion

```swift
func miniMapToCanvas(_ miniMapPoint: CGPoint) -> CGPoint {
    // 1. Remove centering offset and unscale
    let relative = CGPoint(
        x: (miniMapPoint.x - miniMapOffset.x) / miniMapScale,
        y: (miniMapPoint.y - miniMapOffset.y) / miniMapScale
    )
    
    // 2. Translate back to canvas coordinates
    return CGPoint(
        x: relative.x + contentBounds.minX,
        y: relative.y + contentBounds.minY
    )
}
```

**Example:**
```swift
// User clicks at (60, 110) in minimap
let miniMapPos = CGPoint(x: 60, y: 110)

// Inverse conversion:
// relative = (60 - 10, 110 - 10) / 0.5 = (100, 200)
// canvasPos = (100, 200) + (0, 0) = (100, 200)
let canvasPos = viewModel.miniMapToCanvas(miniMapPos)
```

### Viewport Indicator Calculation

The viewport indicator shows which part of the canvas is currently visible:

```swift
// 1. Calculate viewport rect in canvas space
let viewportTopLeftCanvas = panZoomManager.transform.screenToCanvas(.zero)
let viewportSizeCanvas = panZoomManager.transform.screenToCanvas(viewportSize)

let viewportRectCanvas = CGRect(
    origin: viewportTopLeftCanvas,
    size: viewportSizeCanvas
)

// 2. Convert to minimap space
let viewportRectMiniMap = canvasRectToMiniMapRect(viewportRectCanvas)
```

**Why this works:**
- `screenToCanvas(.zero)` gives us the canvas position of the top-left corner of the viewport
- `screenToCanvas(viewportSize)` gives us the size of the viewport in canvas units
- The resulting rectangle in canvas space is then converted to minimap space using the standard conversion

### MiniMap Interaction Pattern

When the user interacts with the minimap (drag, click, zoom), we convert the interaction to canvas space and update the main viewport:

```swift
// User drags viewport indicator in minimap
func handleViewportDrag(at miniMapLocation: CGPoint) {
    // 1. Convert minimap location to canvas position
    let canvasPos = viewModel.miniMapToCanvas(miniMapLocation)
    
    // 2. Calculate where viewport should be centered
    let viewportSizeCanvas = panZoomManager.transform.screenToCanvas(viewportSize)
    let newViewportTopLeftCanvas = CGPoint(
        x: canvasPos.x - viewportSizeCanvas.width / 2,
        y: canvasPos.y - viewportSizeCanvas.height / 2
    )
    
    // 3. Calculate new screen offset
    // Formula: screen = canvas * scale + offset
    // For viewport top-left at screen (0, 0):
    // 0 = newViewportTopLeftCanvas * scale + offset
    // offset = -newViewportTopLeftCanvas * scale
    let newOffset = CGPoint(
        x: -newViewportTopLeftCanvas.x * panZoomManager.transform.scale,
        y: -newViewportTopLeftCanvas.y * panZoomManager.transform.scale
    )
    
    panZoomManager.setOffset(newOffset)
}
```

### MiniMap Coordinate Flow

```
User clicks MiniMap (60, 110)
    ↓
MiniMap Space → Canvas Space
    viewModel.miniMapToCanvas() → (100, 200)
    ↓
Calculate new viewport position
    Center viewport at (100, 200)
    ↓
Canvas Space → Screen Space (Offset)
    Calculate offset for panZoomManager
    ↓
Update transform
    panZoomManager.setOffset(newOffset)
    ↓
Viewport indicator updates
    viewModel.updateViewportIndicator()
    ↓
Canvas Space → MiniMap Space
    Show new viewport rect in minimap
```

### Key Differences from Main Canvas

1. **Scale is Dynamic**: MiniMap scale adjusts to fit all content
2. **Centering Offset**: Content is centered if smaller than minimap
3. **No Direct Rendering**: MiniMap uses Canvas API for batch rendering
4. **Simplified Geometry**: Only node rectangles, no edges (for performance)

### MiniMap Bounds Caching

The MiniMap caches bounds and scale to avoid recalculation on every frame:

```swift
// Hash node positions to detect changes
private func calculateNodePositionsHash<Node: FlowNode>(_ nodes: [Node]) -> Int {
    var hasher = Hasher()
    for node in nodes {
        hasher.combine(node.position.x)
        hasher.combine(node.position.y)
        hasher.combine(node.width)
        hasher.combine(node.height)
    }
    return hasher.finalize()
}

// Only recalculate if nodes changed
let newHash = calculateNodePositionsHash(nodes)
guard newHash != nodePositionsHash || contentBounds == .zero else {
    return  // No changes, use cached values
}
```

This ensures smooth performance even with frequent viewport updates.

---

## Debugging Checklist

When you encounter coordinate bugs, ask yourself:

- [ ] Is this `CGPoint` in canvas, screen, node-local, or minimap space?
- [ ] Did I convert before using it in calculations?
- [ ] Am I mixing spaces (e.g., adding canvas offset to screen position)?
- [ ] Does this gesture use the correct `coordinateSpace`?
- [ ] Am I modifying the model (canvas) or the view (screen)?
- [ ] During zoom, am I maintaining the correct pivot point?
- [ ] For node-local calculations, am I using `node.position` (top-left) as the base?
- [ ] Are port positions being calculated from the correct origin?
- [ ] During resize, are anchors behaving as expected?
- [ ] For minimap interactions, am I converting to/from canvas space correctly?
- [ ] Is the viewport indicator calculating from the correct viewport bounds?

---

## Migration from Center-Anchored

If you have code that assumed `node.position` was the center:

```swift
// OLD (center-anchored):
let leftEdge = node.position.x - node.width / 2
let topEdge = node.position.y - node.height / 2
let center = node.position
let bounds = CGRect(
    x: node.position.x - node.width/2,
    y: node.position.y - node.height/2,
    width: node.width,
    height: node.height
)

// NEW (top-left anchored):
let leftEdge = node.position.x  // position IS the left edge
let topEdge = node.position.y   // position IS the top edge
let center = node.center        // calculated property
let bounds = node.bounds        // calculated from top-left
```

---

## Type-Safe Wrappers (Optional)

For additional safety, SwiftFlow provides type-safe coordinate wrappers:

```swift
// Explicit coordinate types
let canvas = CanvasPoint(CGPoint(x: 100, y: 200))
let screen = ScreenPoint(CGPoint(x: 300, y: 400))
let local = NodeLocalPoint(CGPoint(x: 50, y: 25))

// Type-safe transformations
let screenPos = transform.toScreen(canvas)  // CanvasPoint → ScreenPoint
let canvasPos = transform.toCanvas(screen)  // ScreenPoint → CanvasPoint

// Access underlying CGPoint
let point = canvas.value
```

---

## Best Practices Summary

1. **Name variables by space**: `canvasPos`, `screenPos`, `nodeLocalPos`
2. **Model in canvas**: Always store node positions in canvas coordinates
3. **Convert at boundaries**: Screen input → canvas, canvas → screen output
4. **Use FlowTransform**: Never manually apply pan/zoom to positions
5. **Leverage presets**: Use `PortLayout` for flexible port positioning
6. **Document assumptions**: Comment which space a function expects/returns
7. **Test thoroughly**: Verify drag, zoom, resize all work without drift

---

## Additional Resources

- See `CoordinateSpace.swift` for detailed technical documentation
- See `PortPositioning.swift` for port layout implementation
- See `FlowTransform.swift` for transformation math
- See `MiniMapViewModel.swift` for minimap coordinate conversions
- Check unit tests in `CoordinateSystemTests.swift` and `MiniMapTests.swift` for examples

---

**Questions or issues?** File an issue on GitHub with the `coordinate-system` label.
