# Port Positioning

Flexible port positioning with presets and custom offsets.

## Overview

SwiftFlow provides a flexible port positioning system that adapts to node size changes. Ports can use presets that automatically adjust, or fixed positions for complete control.

## Using Presets

Built-in presets automatically adapt to node size:

```swift
struct MyPort: FlowPort {
    let id = UUID()
    let position: PortPosition = .right
    
    // Port at right-center (adapts to node height during resize)
    let layout = PortLayout(preset: .rightCenter)
}
```

### Available Presets

- `.leftTop`, `.leftCenter`, `.leftBottom`
- `.rightTop`, `.rightCenter`, `.rightBottom`
- `.topLeft`, `.topCenter`, `.topRight`
- `.bottomLeft`, `.bottomCenter`, `.bottomRight`

## Custom Offsets

Add offsets to presets for fine-tuned positioning:

```swift
// Port at right-center, offset 10px right and 5px up
let layout = PortLayout(
    preset: .rightCenter,
    offset: CGPoint(x: 10, y: -5)
)

// Convenience helpers
let layout1 = PortLayout.leftCenter(offsetY: 20)
let layout2 = PortLayout.topCenter(offsetX: -10)
```

## Fully Custom Positions

For complete control, use fixed positions:

```swift
// Port at fixed position (50, 30) from node top-left
let layout = PortLayout(preset: .custom(CGPoint(x: 50, y: 30)))

// Or use the convenience method
let layout = PortLayout.custom(CGPoint(x: 50, y: 30))
```

## Adapting to Resize

Preset positions automatically adjust when nodes are resized:

```swift
// Before resize: node is 200x100
// Port at rightCenter is at (200, 50)

// After resize to 400x200
// Port at rightCenter is now at (400, 100)
// Layout automatically recalculated!
```

## Port Position in Different Spaces

Port positions exist in three coordinate spaces:

1. **Node-local**: Relative to node's top-left corner (from `PortLayout`)
2. **Canvas**: Absolute position in canvas (node.position + nodeLocal)
3. **Screen**: Rendered position (canvas transformed by viewport)

SwiftFlow handles all conversions automatically.

## Usage Examples

### Multiple Ports with Offsets

```swift
struct DataNode: FlowNode {
    // ...
    
    var inputPorts: [any FlowPort] {
        [
            DataPort(id: UUID(), layout: .leftTop(offsetY: 20)),
            DataPort(id: UUID(), layout: .leftTop(offsetY: 60)),
            DataPort(id: UUID(), layout: .leftTop(offsetY: 100))
        ]
    }
    
    var outputPorts: [any FlowPort] {
        [
            DataPort(id: UUID(), layout: .rightCenter)
        ]
    }
}
```

### Custom Port Positioning

```swift
struct CustomPort: FlowPort {
    let id: UUID
    let position: PortPosition
    
    // Port in top-right quadrant
    var layout: PortLayout {
        PortLayout(
            preset: .custom(CGPoint(x: 150, y: 25)),
            offset: .zero
        )
    }
}
```

## See Also

- ``PortLayout``
- ``PortPosition``
- <doc:CoordinateSystem>
