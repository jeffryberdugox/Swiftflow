# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- iOS and iPadOS support
- Custom edge path calculators API
- Animation system for node transitions
- Collaborative editing support
- Performance improvements for large graphs (1000+ nodes)

---

## [1.0.0] - 2026-01-29

### Added

#### Core Features
- **Declarative Canvas API**: SwiftUI-native canvas view with reactive state management
- **Three-Space Coordinate System**: Canvas, Screen, and Node-local coordinate spaces
- **Command Pattern**: Atomic operations with full undo/redo support
- **Type-Safe Protocols**: `FlowNode`, `FlowEdge`, and `FlowPort` for extensibility

#### Node System
- Interactive node dragging with snap-to-grid support
- Multi-node selection and manipulation
- Parent-child node relationships (nested nodes)
- Node resizing with aspect ratio preservation
- Customizable node content through SwiftUI view builders
- Z-index layering control
- Node extent constraints (boundary limits)

#### Edge System
- Multiple edge styles: Bezier, SmoothStep, and Straight
- Edge markers (arrows, dots) for source and target endpoints
- Edge labels with customizable positioning
- Edge accessories (custom views along edge path)
- Edge hover detection and interaction
- Animated edges support
- Custom edge styling per edge

#### Interaction Features
- **Pan & Zoom**: Smooth viewport navigation with configurable limits
- **Box Selection**: Marquee selection with modifier key support
- **Keyboard Shortcuts**: Copy, paste, delete, undo, redo with full customization
- **Helper Lines**: Alignment guides with snap-to-align and haptic feedback
- **Auto-pan**: Automatic viewport panning during drag near edges
- **Connection Creation**: Drag from ports to create connections
- **Connection Drop API**: Create nodes dynamically when dropping connections on canvas

#### Visual Components
- **MiniMap**: Bird's-eye view with interactive navigation
  - Draggable viewport indicator
  - Zoom on scroll
  - Click-to-move navigation
  - Customizable appearance (colors, borders, node labels)
- **Grid Background**: Dots or lines pattern with snap-to-grid
- **Controls**: Built-in zoom and fit-view controls
- **Node Toolbar**: Contextual actions for selected nodes

#### Configuration System
- Modular configuration with sub-configs:
  - `ZoomConfig`: Zoom limits and behavior
  - `GridConfig`: Grid appearance and snapping
  - `InteractionConfig`: User interaction permissions
  - `EdgeConfig`: Edge rendering and styling
  - `HistoryConfig`: Undo/redo settings
  - `AutoPanConfig`: Auto-pan behavior
  - `HelperLinesConfig`: Alignment guide settings
- Preset configurations: `.default`, `.minimal`, `.presentation`
- Fluent modifier API for configuration

#### Developer Experience
- **Comprehensive Documentation**:
  - Complete API reference (1500+ lines)
  - Architecture guide
  - Coordinate system guide
  - Getting started tutorial
- **Code Examples**:
  - Complete examples in documentation
  - Quick Start guide with working code
  - API Reference with usage examples
- **Testing**:
  - Unit tests for core functionality
  - Integration tests
  - Performance tests
  - Coordinate system tests
- **Type Safety**:
  - Type-safe coordinate wrappers (`CanvasPoint`, `ScreenPoint`)
  - Platform-independent color type (`RGBAColor`)
  - Compile-time safety for operations

#### Performance
- **Caching System**:
  - Node bounds cache
  - Port positions cache
  - Edge path cache
- **Optimized Rendering**:
  - Throttled MiniMap updates (30 FPS)
  - Efficient path calculations
  - Viewport culling for large graphs

#### Public API
- **CanvasController**: Central controller for all operations
  - Published state for UI binding
  - Command API for operations
  - Transaction API for batch undo
  - Viewport utilities (project/unproject)
  - Data access methods
- **FlowStore**: Vue Flow-compatible reactive store
  - Reactive observers for nodes, edges, viewport, selection
  - Graph query helpers
  - High-level operations
- **Public Helper Functions**:
  - Path calculation helpers
  - Bounds calculation helpers
  - Node query helpers
  - Coordinate conversion utilities

### Technical Details
- **Platforms**: macOS 13.0+
- **Swift Version**: 5.9+
- **Dependencies**: None (zero dependencies)
- **Architecture**: Three-layer design (Core, Engine, View)
- **Concurrency**: Full `@MainActor` safety
- **Memory Management**: Efficient caching with automatic invalidation

---

## Release Notes

### What's Special About 1.0.0

SwiftFlow 1.0.0 is a production-ready node-based editor framework for SwiftUI, inspired by the excellent web-based editors [React Flow](https://reactflow.dev/) and [Vue Flow](https://vueflow.dev/). 

Key differentiators:
- **Pure SwiftUI**: Native integration with the Apple ecosystem
- **Zero Dependencies**: Lightweight and easy to integrate
- **Type-Safe**: Leverages Swift's type system for compile-time safety
- **Coordinate Clarity**: Eliminates common positioning bugs with explicit coordinate spaces
- **Command Pattern**: Professional undo/redo system
- **Comprehensive Docs**: Extensive documentation and examples

### Migration from Pre-1.0

This is the first stable release. Future releases will maintain backward compatibility following semantic versioning.

### Known Limitations

- Currently macOS only (iOS/iPadOS support planned)
- Maximum tested graph size: ~500 nodes (performance optimization ongoing)
- Custom edge path calculators not yet exposed as public API

---

## Links

- [GitHub Repository](https://github.com/jeffryberdugox/SwiftFlow)
- [Documentation](https://jeffryberdugox.github.io/Swiftflow/documentation/swiftflow/)
- [Issue Tracker](https://github.com/jeffryberdugox/SwiftFlow/issues)

[Unreleased]: https://github.com/jeffryberdugox/SwiftFlow/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/jeffryberdugox/SwiftFlow/releases/tag/v1.0.0
