# SwiftFlow Architecture

This document describes the internal architecture of SwiftFlow 1.0.

## Overview

SwiftFlow is organized into three distinct layers:

```
┌─────────────────────────────────────────────────────────────┐
│                       SwiftUI Layer                         │
│  CanvasView, MiniMapView, ControlsView, Modifiers          │
├─────────────────────────────────────────────────────────────┤
│                    Interaction Engine                       │
│  CanvasController, Managers, UndoStack, Caches             │
├─────────────────────────────────────────────────────────────┤
│                       Core Layer                            │
│  Protocols, Types, Commands, Math, Utils (Pure Swift)       │
└─────────────────────────────────────────────────────────────┘
```

## Core Layer (Pure Swift)

The Core layer contains no SwiftUI dependencies and can be used independently.

### Protocols

- **FlowNode**: Represents a node in the flow
- **FlowEdge**: Represents a connection between nodes
- **FlowPort**: Represents a connection point on a node

### Types

- **RGBAColor**: Platform-independent color
- **CanvasPoint/ScreenPoint**: Type-safe coordinates
- **CanvasRect**: Canvas-space rectangle
- **FlowTransform**: Offset and scale transformation
- **InteractionMode**: User interaction permissions
- **EdgePathStyle**: Edge rendering style

### Commands

- **CanvasCommand**: Atomic operations (move, delete, connect, etc.)
- **CanvasTransaction**: Grouped commands for batch undo
- **UndoStack**: History management

### Math & Utils

- **BoundsCalculation**: Calculate bounding boxes
- **SnapGrid**: Grid snapping logic
- **PathCalculators**: Bezier, SmoothStep, Straight paths

## Interaction Engine

The engine layer manages state and interaction logic.

### CanvasController

Central orchestrator that:
- Exposes published state for UI binding
- Provides command API for operations
- Manages internal managers
- Handles undo/redo

```swift
@MainActor
public class CanvasController: ObservableObject {
    // Published state
    @Published var transform: FlowTransform
    @Published var selection: SelectionState
    @Published var isDragging: Bool
    
    // Internal managers
    private lazy var panZoomManager: PanZoomManager
    private lazy var dragManager: DragManager
    private lazy var selectionManager: SelectionManager
    private lazy var connectionManager: ConnectionManager
    
    // Command execution
    func perform(_ command: CanvasCommand) -> Bool
    func transaction(_ name: String, commands: () -> [CanvasCommand])
}
```

### Managers

- **PanZoomManager**: Handles viewport transformation
- **DragManager**: Handles node dragging with snap
- **SelectionManager**: Manages node/edge selection
- **ConnectionManager**: Handles connection creation
- **EdgeHoverManager**: Tracks edge hover states
- **PortPositionRegistry**: Caches port positions

### Caches

- **NodesBoundsCache**: Caches combined node bounds
- **PortPositionsCache**: Caches port absolute positions

## SwiftUI Layer

The view layer for rendering and user interaction.

### Views

- **CanvasView**: Main canvas container
- **MiniMapView**: Miniature overview
- **ControlsView**: Zoom/fit controls
- **EdgeView**: Edge rendering
- **NodeToolbarView**: Contextual node actions

### Modifiers

Fluent API for configuration:

```swift
CanvasView(...)
    .miniMap(.bottomTrailing)
    .grid(.dots, snap: true)
    .onConnectionCreated { ... }
```

## Data Flow

```
User Action
    │
    ▼
┌─────────────┐     ┌─────────────────┐
│   Gesture   │ ──> │ CanvasController │
└─────────────┘     └────────┬────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │    Command     │
                    └────────┬───────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
        ┌─────────┐   ┌───────────┐   ┌──────────┐
        │ Manager │   │ Transform │   │ UndoStack│
        └────┬────┘   └─────┬─────┘   └──────────┘
             │              │
             ▼              ▼
      ┌────────────┐  ┌────────────┐
      │ Environment│  │  @Published│
      │ (Edits)    │  │  State     │
      └─────┬──────┘  └─────┬──────┘
            │               │
            ▼               ▼
    ┌──────────────┐  ┌────────────┐
    │ User's Data  │  │    UI      │
    │ (nodes/edges)│  │  Updates   │
    └──────────────┘  └────────────┘
```

## State Pipeline

### Source of Truth

- **User owns the data**: `nodes` and `edges` arrays
- **Controller owns the UI state**: `transform`, `selection`, `isDragging`

### CanvasEnvironment

Bridge between controller and user's data:

```swift
struct CanvasEnvironment<Node, Edge> {
    var getNodes: () -> [Node]
    var getEdges: () -> [Edge]
    var applyNodeEdits: ([NodeEdit]) -> Void
    var applyEdgeEdits: ([EdgeEdit]) -> Void
}
```

### Edit Types

Granular change descriptions:

```swift
enum NodeEdit {
    case move(id: UUID, to: CGPoint)
    case resize(id: UUID, size: CGSize)
    case delete(id: UUID)
    case setParent(id: UUID, parentId: UUID?)
}

enum EdgeEdit {
    case create(id: UUID, sourceNode: UUID, ...)
    case delete(id: UUID)
}
```

## Coordinate Systems

### Screen Coordinates
- Origin at viewport top-left
- Affected by zoom/pan
- Used for user interaction (mouse, touch)

### Canvas Coordinates
- Origin at canvas top-left (infinite canvas)
- Independent of zoom/pan
- Used for node positions

### Conversion

```swift
// Screen to Canvas
let canvasPoint = transform.screenToCanvas(screenPoint)

// Canvas to Screen
let screenPoint = transform.canvasToScreen(canvasPoint)

// Type-safe versions
let typedCanvas = transform.toCanvas(typedScreen)
```

## Performance Considerations

### Caching
- Node bounds are cached and invalidated on change
- Port positions are cached per node version
- Throttling prevents excessive updates

### Rendering
- Only visible nodes are fully rendered
- Edges use efficient path calculations
- MiniMap updates are throttled to 30fps

### Memory
- Undo history is limited (configurable)
- Caches can be manually invalidated
- Type-erased wrappers minimize generic code duplication
