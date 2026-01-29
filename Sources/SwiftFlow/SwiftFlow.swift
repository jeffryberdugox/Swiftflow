//
//  SwiftFlow.swift
//  SwiftFlow
//
//  Main entry point for the SwiftFlow package.
//  Re-exports all public types for convenient importing.
//

import Foundation
import SwiftUI

// MARK: - Public API Summary
//
// SwiftFlow 2.0 provides a clean, layered API for building node-based editors.
//
// ## Quick Start (Simple Usage)
//
// ```swift
// import SwiftFlow
//
// CanvasView(nodes: $nodes, edges: $edges) { node, isSelected in
//     MyNodeView(node: node, isSelected: isSelected)
// }
// .onConnectionCreated { s, sp, t, tp in
//     edges.append(MyEdge(...))
// }
// ```
//
// ## With Controller (Advanced Usage)
//
// ```swift
// @StateObject var controller = CanvasController(config: .default)
//
// CanvasView(nodes: $nodes, edges: $edges, controller: controller) { ... }
//
// controller.zoomIn()
// controller.select(node: id)
// controller.perform(.moveNodes(ids: selected, delta: offset))
// ```
//
// ## Configuration with Sub-Configs
//
// ```swift
// let config = CanvasConfig(
//     zoom: ZoomConfig(min: 0.5, max: 3.0),
//     grid: .snapping,
//     interaction: .default,
//     edge: EdgeConfig(pathStyle: .smoothStep())
// )
// ```

// MARK: - Protocols (FlowNode.swift, FlowEdge.swift, FlowPort.swift)
// - FlowNode: Protocol for nodes in the flow
// - FlowEdge: Protocol for connections between nodes
// - FlowPort: Protocol for connection points on nodes
// - PathCalculator: Protocol for edge path calculation

// MARK: - Core Types (Core/Types/)
// - RGBAColor: Platform-independent color (no SwiftUI)
// - CanvasPoint, ScreenPoint: Type-safe coordinate wrappers
// - CanvasRect, CanvasSize: Canvas-space geometry types
// - InteractionMode: User interaction mode enum
// - InteractionPermissions: Granular permissions
// - EdgePathStyle: Edge rendering style enum
// - ResizeAnchor: Anchor point for resize operations

// MARK: - Core Models (Core/Models/)
// - FlowTransform: Offset and scale transformation (with type-safe conversions)
// - SelectionState: Current selection state
// - ConnectionState: Connection in progress
// - DragState: Drag operation state
// - GridPattern: Grid visual pattern
// - AlignmentResult: Result of helper lines alignment calculation

// MARK: - Commands (Core/Commands/)
// - CanvasCommand: Atomic operations enum
// - CanvasTransaction: Grouped commands for batch undo
// - TransactionBuilder: Result builder for transactions
// - UndoStack: History management class (replaces UndoRedoManager)

// MARK: - State Pipeline (Core/State/)
// - CanvasEnvironment: Bridge between controller and user data
// - NodeEdit: Atomic node change description
// - EdgeEdit: Atomic edge change description

// MARK: - Configuration (Core/Config/)
// - CanvasConfig: Main canvas configuration (with sub-configs)
// - ZoomConfig: Zoom behavior settings
// - GridConfig: Grid appearance and snap
// - GridStyle: Grid visual styling (uses RGBAColor)
// - InteractionConfig: Interaction mode settings
// - EdgeConfig: Edge appearance settings
// - HistoryConfig: Undo/redo settings
// - AutoPanConfig: Auto-pan behavior settings
// - HelperLinesConfig: Alignment guides configuration (with haptic feedback support)
// - HelperLinesStyle: Helper lines visual styling

// MARK: - Caches (Core/Caches/)
// - NodesBoundsCache: Cached node bounds calculation
// - PortPositionsCache: Cached port positions

// MARK: - Controller (Controller/)
// - CanvasController: Central controller for all canvas operations
// - AdvancedAccess: Direct manager access for power users

// MARK: - Managers (Managers/)
// - PanZoomManager: Viewport pan and zoom (with type-safe methods)
// - DragManager: Node dragging with snap (with type-safe methods)
// - SelectionManager: Node and edge selection
// - ConnectionManager: Connection creation
// - EdgeHoverManager: Edge hover detection
// - PortPositionRegistry: Port position tracking
// - KeyboardShortcutsManager: Keyboard handling
// - CopyPasteManager: Clipboard operations
// - BoxSelectionManager: Marquee selection
// - HelperLinesManager: Alignment guides calculation

// MARK: - Views (Views/)
// - CanvasView: Main canvas view (supports both simple and controller patterns)
// - EdgeView: Edge rendering
// - ConnectionPreviewView: Connection in progress preview
// - HelperLinesView: Alignment guides rendering
// - CanvasGridView: Grid background (accepts GridConfig)
// - MiniMapView: Miniature overview
// - ControlsView: Zoom and fit controls
// - NodeToolbarView: Contextual node actions
// - PanelView: Positioned overlay panel

// MARK: - MiniMap (Views/MiniMap/)
// - MiniMapController: Minimap state management (throttled updates)

// MARK: - Modifiers (Views/Modifiers/)
// - CanvasModifiers: Fluent configuration modifiers
// - CanvasTransformModifier: Transform application
// - ScrollGestureModifier: Scroll/pinch gestures

// MARK: - Path Calculators (Core/Geometry/)
// - BezierPathCalculator: Smooth bezier curves
// - SmoothStepPathCalculator: Orthogonal paths
// - StraightPathCalculator: Direct lines

// MARK: - Examples (Examples/)
// - BasicExample: Simple usage demonstration
// - AdvancedExample: Controller-based usage
// - CustomNodeExample: Custom node views
// - NestedNodesExample: Parent-child nodes

// MARK: - Public Helpers (Utils/PublicHelpers.swift)
// Path calculation helpers:
// - getBezierPath: Calculate bezier curve path
// - getSmoothStepPath: Calculate orthogonal path
// - getStraightPath: Calculate straight line path
// - getBezierEdgeCenter: Get bezier edge center point
// - getSimpleEdgeCenter: Get straight edge center point
//
// Bounds calculation helpers:
// - getRectOfNodes: Get bounding rectangle of nodes
// - getBoundsOfRects: Combine two rectangles
// - getTransformForBounds: Calculate fit transform
//
// Node query helpers:
// - getNodesInside: Get nodes in rectangular area
// - connectionExists: Check if connection exists
//
// Coordinate conversion helpers:
// - screenToCanvas: Convert screen to canvas coordinates
// - canvasToScreen: Convert canvas to screen coordinates
//
// Utility helpers:
// - clamp: Clamp value between min and max
// - distance: Calculate distance between points
// - isPointNearLine: Check if point is near line segment
