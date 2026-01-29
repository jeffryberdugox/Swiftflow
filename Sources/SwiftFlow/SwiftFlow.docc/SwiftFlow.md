# ``SwiftFlow``

A modern, declarative node-based editor framework for SwiftUI.

## Overview

SwiftFlow brings the power of professional node-based editors to the Swift ecosystem. Inspired by React Flow and Vue Flow, it provides a declarative API that feels natural in SwiftUI applications.

Perfect for building:
- Visual programming tools
- Workflow editors
- Diagram applications
- Data pipeline builders
- State machine editors

### Key Features

- **Declarative API**: Built entirely with SwiftUI for seamless integration
- **Interactive Nodes**: Drag, resize, multi-select with keyboard shortcuts
- **Flexible Edges**: Multiple styles (Bezier, SmoothStep, Straight) with markers
- **Coordinate Clarity**: Three-space architecture eliminates positioning bugs
- **Command Pattern**: Full undo/redo support for all operations
- **Zero Dependencies**: Lightweight and easy to integrate

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:QuickStart>
- ``CanvasView``
- ``CanvasController``

### Protocols

- ``FlowNode``
- ``FlowEdge``
- ``FlowPort``

### Configuration

- ``CanvasConfig``
- ``ZoomConfig``
- ``GridConfig``
- ``InteractionConfig``
- ``EdgeConfig``

### Core Types

- ``FlowTransform``
- ``SelectionState``
- ``RGBAColor``
- ``CanvasPoint``
- ``ScreenPoint``

### Commands & Operations

- ``CanvasCommand``
- ``CanvasTransaction``

### Advanced

- <doc:CoordinateSystem>
- <doc:PortPositioning>
- ``AdvancedAccess``
- ``FlowStore``

### Events & Callbacks

- ``NodeDragEvent``
- ``ConnectionStartEvent``
- ``ViewportChangeEvent``

### Helper Functions

- ``getBezierPath(sourceX:sourceY:targetX:targetY:sourcePosition:targetPosition:curvature:)``
- ``getSmoothStepPath(sourceX:sourceY:targetX:targetY:sourcePosition:targetPosition:borderRadius:)``
- ``getRectOfNodes(_:)``
