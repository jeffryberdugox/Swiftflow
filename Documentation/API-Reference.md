# SwiftFlow API Reference

Complete API reference for SwiftFlow 1.0.

## Table of Contents

- [Core Types](#core-types)
- [Enumerations](#enumerations)
- [Events](#events)
- [Component Props](#component-props)
- [CanvasController](#canvascontroller)
- [FlowStore](#flowstore)
- [Configuration](#configuration)
- [Commands](#commands)
- [Views](#views)
- [Protocols](#protocols)
- [Public Helpers](#public-helpers)
- [Error Handling](#error-handling)

---

## Core Types

### RGBAColor

Platform-independent color representation.

```swift
public struct RGBAColor: Equatable, Sendable, Codable, Hashable {
    public var red: CGFloat
    public var green: CGFloat
    public var blue: CGFloat
    public var alpha: CGFloat
    
    // Presets
    public static let clear: RGBAColor
    public static let black: RGBAColor
    public static let white: RGBAColor
    public static let gray: RGBAColor
    
    // Methods
    public func withAlpha(_ alpha: CGFloat) -> RGBAColor
    public func lightened(by amount: CGFloat) -> RGBAColor
    public func darkened(by amount: CGFloat) -> RGBAColor
}
```

### Coordinate Types

Type-safe coordinate wrappers.

```swift
// Canvas coordinates (where nodes live)
public struct CanvasPoint: Equatable, Sendable, Hashable, Codable {
    public var x: CGFloat
    public var y: CGFloat
    public var cgPoint: CGPoint { get }
    public static let zero: CanvasPoint
}

// Screen coordinates (where user interacts)
public struct ScreenPoint: Equatable, Sendable, Hashable, Codable {
    public var x: CGFloat
    public var y: CGFloat
    public var cgPoint: CGPoint { get }
    public static let zero: ScreenPoint
    public static let viewportCenter: ScreenPoint
}

// Canvas rectangle
public struct CanvasRect: Equatable, Sendable, Hashable, Codable {
    public var origin: CanvasPoint
    public var size: CGSize
    public var cgRect: CGRect { get }
    public func contains(_ point: CanvasPoint) -> Bool
    public func union(_ other: CanvasRect) -> CanvasRect
}
```

### InteractionMode

Defines how users interact with the canvas.

```swift
public enum InteractionMode: Equatable, Sendable {
    case edit           // Full editing
    case viewOnly       // Pan/zoom only
    case selectOnly     // Select but not move
    case connectOnly    // Create connections only
    case custom(InteractionPermissions)
}

public struct InteractionPermissions: Equatable, Sendable, Hashable {
    public var canSelect: Bool
    public var canDrag: Bool
    public var canConnect: Bool
    public var canResize: Bool
    public var canBoxSelect: Bool
    public var canUseKeyboard: Bool
    
    public static let all: InteractionPermissions
    public static let none: InteractionPermissions
}
```

### EdgePathStyle

Edge rendering styles.

```swift
public enum EdgePathStyle: Equatable, Sendable, Hashable {
    case bezier(curvature: CGFloat = 0.25)
    case smoothStep(borderRadius: CGFloat = 8)
    case straight
    
    public static let `default`: EdgePathStyle
}
```

---

## Enumerations

### ConnectionLineType

Type of line for connection preview during dragging.

```swift
public enum ConnectionLineType: Equatable, Sendable, Hashable, Codable {
    case bezier(curvature: CGFloat = 0.25)
    case smoothStep(borderRadius: CGFloat = 8)
    case straight
    case inherit  // Use same style as configured edges
    
    public static let `default`: ConnectionLineType
}
```

### ConnectionMode

Mode for creating connections between nodes.

```swift
public enum ConnectionMode: Equatable, Sendable, Hashable, Codable {
    case strict  // Only outputs to inputs
    case loose   // Any direction allowed
    
    public static let `default`: ConnectionMode
}
```

### SelectionMode

Selection behavior mode.

```swift
public enum SelectionMode: Equatable, Sendable, Hashable, Codable {
    case full     // Full selection with multi-select
    case partial  // Nodes only, no edges
    case none     // No selection allowed
    
    public static let `default`: SelectionMode
}
```

### PanOnScrollMode

Scroll behavior mode.

```swift
public enum PanOnScrollMode: Equatable, Sendable, Hashable, Codable {
    case zoom       // Scroll to zoom (default)
    case horizontal // Scroll to pan horizontally
    case vertical   // Scroll to pan vertically
    case free       // Scroll to pan in both directions
    
    public static let `default`: PanOnScrollMode
}
```

### ResizeControlVariant

Resize control variant.

```swift
public enum ResizeControlVariant: Equatable, Sendable, Hashable, Codable {
    case handle   // Single handle at bottom-right
    case corners  // Handles on all four corners
    case edges    // Handles on all edges (4 corners + 4 edges)
    case none     // No resize controls
    
    public static let `default`: ResizeControlVariant
}
```

### MarkerType

Type of marker for edge endpoints.

```swift
public enum MarkerType: Equatable, Sendable, Hashable, Codable {
    case arrow        // Standard arrow
    case arrowClosed  // Filled arrow
    case dot          // Circular dot
    case none         // No marker
    
    public static let `default`: MarkerType
}

public struct EdgeMarker: Equatable, Sendable, Hashable, Codable {
    public var type: MarkerType
    public var position: MarkerPosition  // .source or .target
    public var size: CGFloat
    public var color: RGBAColor?
    
    // Presets
    public static let targetArrow: EdgeMarker
    public static let targetArrowClosed: EdgeMarker
    public static let targetDot: EdgeMarker
    public static let sourceArrow: EdgeMarker
}
```

---

## Events

### Node Events

```swift
// Node drag event
public struct NodeDragEvent: Equatable, Sendable {
    public let nodeId: UUID
    public let position: CGPoint
    public let delta: CGSize
    public let isDragging: Bool
    public let timestamp: Date
}

// Node mouse event
public struct NodeMouseEvent: Equatable, Sendable {
    public let nodeId: UUID
    public let position: CGPoint
    public let eventType: MouseEventType  // .click, .doubleClick, .contextMenu, etc.
    public let modifiers: EventModifiers
    public let timestamp: Date
}

// Node resize event
public struct NodeResizeEvent: Equatable, Sendable {
    public let nodeId: UUID
    public let size: CGSize
    public let previousSize: CGSize
    public let anchor: ResizeAnchor
    public let isResizing: Bool
    public let timestamp: Date
}
```

### Edge Events

```swift
// Edge mouse event
public struct EdgeMouseEvent: Equatable, Sendable {
    public let edgeId: UUID
    public let position: CGPoint
    public let eventType: MouseEventType
    public let modifiers: EventModifiers
    public let timestamp: Date
}

// Edge update event
public struct EdgeUpdateEvent: Equatable, Sendable {
    public let edgeId: UUID
    public let oldSource: (nodeId: UUID, portId: UUID)
    public let oldTarget: (nodeId: UUID, portId: UUID)
    public let newSource: (nodeId: UUID, portId: UUID)?
    public let newTarget: (nodeId: UUID, portId: UUID)?
    public let timestamp: Date
}
```

### Connection Events

```swift
// Connection start event
public struct ConnectionStartEvent: Equatable, Sendable {
    public let sourceNodeId: UUID
    public let sourcePortId: UUID
    public let position: CGPoint
    public let portPosition: PortPosition
    public let isFromInput: Bool
    public let timestamp: Date
}

// Connection end event
public struct ConnectionEndEvent: Equatable, Sendable {
    public let sourceNodeId: UUID
    public let sourcePortId: UUID
    public let targetNodeId: UUID?
    public let targetPortId: UUID?
    public let position: CGPoint
    public let wasSuccessful: Bool
    public let timestamp: Date
}
```

### Canvas Events

```swift
// Canvas mouse event
public struct CanvasMouseEvent: Equatable, Sendable {
    public let position: CGPoint
    public let screenPosition: CGPoint
    public let eventType: MouseEventType
    public let modifiers: EventModifiers
    public let timestamp: Date
}

// Viewport change event
public struct ViewportChangeEvent: Equatable, Sendable {
    public let transform: FlowTransform
    public let previousTransform: FlowTransform
    public let viewportSize: CGSize
    public let changeType: ViewportChangeType  // .zoom, .pan, .fit, .reset
    public let timestamp: Date
}

// Selection change event
public struct SelectionChangeEvent: Equatable, Sendable {
    public let selectedNodes: Set<UUID>
    public let selectedEdges: Set<UUID>
    public let previousSelectedNodes: Set<UUID>
    public let previousSelectedEdges: Set<UUID>
    public let timestamp: Date
}
```

---

## Component Props

### BackgroundProps

Props for canvas background/grid.

```swift
public struct BackgroundProps: Equatable, Sendable, Hashable {
    public var visible: Bool
    public var pattern: GridPattern
    public var size: CGFloat
    public var color: RGBAColor
    public var lineWidth: CGFloat
    public var backgroundColor: RGBAColor
    
    // Convert to GridConfig
    public func toGridConfig() -> GridConfig
    
    // Presets
    public static let `default`: BackgroundProps
    public static let dots: BackgroundProps
    public static let lines: BackgroundProps
    public static let hidden: BackgroundProps
}
```

### MiniMapProps

Props for minimap component.

```swift
public struct MiniMapProps: Equatable, Sendable {
    public var position: PanelPosition
    public var width: CGFloat
    public var height: CGFloat
    public var backgroundColor: RGBAColor
    public var nodeColor: RGBAColor
    public var selectedNodeColor: RGBAColor?
    public var maskColor: RGBAColor
    public var pannable: Bool
    public var zoomable: Bool
    public var clickToMove: Bool
    
    // Convert to MiniMapConfig
    public func toMiniMapConfig() -> MiniMapConfig
    
    // Presets
    public static let `default`: MiniMapProps
    public static let compact: MiniMapProps
    public static let large: MiniMapProps
}
```

### ControlsProps

Props for controls component.

```swift
public struct ControlsProps: Equatable, Sendable, Hashable {
    public var position: PanelPosition
    public var showZoomIn: Bool
    public var showZoomOut: Bool
    public var showFitView: Bool
    public var showInteractive: Bool
    public var buttonSize: CGFloat
    
    // Presets
    public static let `default`: ControlsProps
    public static let minimal: ControlsProps
    public static let full: ControlsProps
}
```

### PanelProps

Generic props for positioned panels.

```swift
public struct PanelProps: Equatable, Sendable, Hashable {
    public var position: PanelPosition
    public var padding: CGFloat
    public var backgroundColor: RGBAColor?
    public var borderColor: RGBAColor?
    public var shadow: Bool
    
    // Presets
    public static let `default`: PanelProps
    public static let card: PanelProps
}
```

### NodeProps & EdgeProps

Configuration wrappers for nodes and edges.

```swift
public struct NodeProps: Equatable, Sendable {
    public var type: String?
    public var draggable: Bool
    public var selectable: Bool
    public var connectable: Bool
    public var resizable: Bool
    public var zIndex: Double
    
    // Presets
    public static let `default`: NodeProps
    public static let locked: NodeProps
}

public struct EdgeProps: Equatable, Sendable {
    public var type: String?
    public var animated: Bool
    public var selectable: Bool
    public var updatable: Bool
    public var markerStart: EdgeMarker?
    public var markerEnd: EdgeMarker?
    
    // Presets
    public static let `default`: EdgeProps
    public static let animated: EdgeProps
}
```

---

## CanvasController

Central controller for canvas operations.

### Properties

```swift
@MainActor
public class CanvasController: ObservableObject {
    // Published state
    @Published public private(set) var transform: FlowTransform
    @Published public private(set) var selection: SelectionState
    @Published public private(set) var isDragging: Bool
    @Published public private(set) var isConnecting: Bool
    @Published public private(set) var connectionPreview: ConnectionState?
    @Published public private(set) var viewportSize: CGSize
    
    // Configuration
    public let config: CanvasConfig
    
    // Undo/Redo
    public var canUndo: Bool { get }
    public var canRedo: Bool { get }
    public var undoName: String? { get }
    public var redoName: String? { get }
    
    // Advanced access
    public var advanced: AdvancedAccess { get }
}
```

### Initialization

```swift
public init(config: CanvasConfig = .default)
```

### Command API

```swift
// Execute single command
@discardableResult
public func perform(_ command: CanvasCommand) -> Bool

// Execute transaction (multiple commands as one undo)
public func transaction(_ name: String, @TransactionBuilder commands: () -> [CanvasCommand])
```

### Convenience Methods

```swift
// Zoom
public func zoomIn(at anchor: ScreenPoint = .viewportCenter)
public func zoomOut(at anchor: ScreenPoint = .viewportCenter)
public func zoom(to scale: CGFloat, at anchor: ScreenPoint = .viewportCenter)

// Pan
public func pan(by delta: CGSize)
public func panToCenter(_ point: CanvasPoint)

// Fit
public func fitView(padding: CGFloat = 50)
public func fitNodes(_ ids: Set<UUID>, padding: CGFloat = 50)
public func resetView()

// Selection
public func select(node id: UUID, additive: Bool = false)
public func select(nodes ids: Set<UUID>, additive: Bool = false)
public func select(edge id: UUID, additive: Bool = false)
public func selectAll()
public func clearSelection()

// Delete
public func deleteSelection()
public func deleteNodes(_ ids: Set<UUID>)
public func deleteEdges(_ ids: Set<UUID>)

// Resize
public func resizeNode(id: UUID, toWidth: CGFloat, anchor: ResizeAnchor = .topLeft) -> Bool
public func resizeNode(id: UUID, byScale: CGFloat, anchor: ResizeAnchor = .topLeft) -> Bool
public func resizeNode(id: UUID, to: CGSize, anchor: ResizeAnchor = .topLeft) -> Bool
public func resizeSelection(byScale: CGFloat) -> [Bool]

// Undo/Redo
public func undo()
public func redo()
```

### Viewport Utilities

```swift
// Coordinate Conversion
public func project(_ point: CGPoint) -> CGPoint
public func project(_ point: ScreenPoint) -> CanvasPoint
public func unproject(_ point: CGPoint) -> CGPoint
public func unproject(_ point: CanvasPoint) -> ScreenPoint

// Data Access
public func getNodes() -> [AnyFlowNode]
public func getEdges() -> [any FlowEdge]
public func getElements() -> (nodes: [AnyFlowNode], edges: [any FlowEdge])
public func getNode(id: UUID) -> AnyFlowNode?
public func getEdge(id: UUID) -> (any FlowEdge)?

// State Export
public func toObject() -> [String: Any]
```

**Usage Examples:**

```swift
// Convert screen coordinates to canvas (for drag & drop)
let canvasPosition = controller.project(screenPoint)

// Access current data
let allNodes = controller.getNodes()
let allEdges = controller.getEdges()
let (nodes, edges) = controller.getElements()

// Export state for persistence
let state = controller.toObject()
// state["viewport"]["zoom"] // Current zoom level
// state["nodeCount"] // Number of nodes
```

---

## FlowStore

High-level reactive store for flow operations.

### Overview

`FlowStore` provides a reactive API with published properties and high-level operations.

```swift
@MainActor
public class FlowStore<Node: FlowNode, Edge: FlowEdge>: ObservableObject {
    @Published public var nodes: [Node]
    @Published public var edges: [Edge]
    @Published public var selectedNodes: Set<UUID>
    @Published public var selectedEdges: Set<UUID>
    @Published public var viewport: FlowTransform
    @Published public var isDragging: Bool
    @Published public var isConnecting: Bool
}
```

### Node Operations

```swift
// Get/Set nodes
public func getNodes() -> [Node]
public func setNodes(_ newNodes: [Node])

// Add nodes
public func addNode(_ node: Node)
public func addNodes(_ nodesToAdd: [Node])

// Remove nodes
public func removeNodes(_ ids: Set<UUID>)

// Get specific node
public func getNode(id: UUID) -> Node?

// Update node
public func updateNode(id: UUID, update: (Node) -> Node)

// Get filtered nodes
public func getNodesData(ids: Set<UUID>) -> [Node]
```

### Edge Operations

```swift
// Get/Set edges
public func getEdges() -> [Edge]
public func setEdges(_ newEdges: [Edge])

// Add edges
public func addEdge(_ edge: Edge)
public func addEdges(_ edgesToAdd: [Edge])

// Remove edges
public func removeEdges(_ ids: Set<UUID>)

// Get specific edge
public func getEdge(id: UUID) -> Edge?

// Update edge
public func updateEdge(id: UUID, update: (Edge) -> Edge)

// Get filtered edges
public func getEdgesData(ids: Set<UUID>) -> [Edge]
```

### Graph Queries

```swift
// Get connected edges
public func getConnectedEdges(nodeIds: Set<UUID>) -> [Edge]

// Get incoming/outgoing nodes
public func getIncomers(nodeId: UUID) -> [Node]
public func getOutgoers(nodeId: UUID) -> [Node]

// Get intersecting nodes
public func getIntersectingNodes(nodeId: UUID) -> [Node]

// Get nodes in area
public func getNodesInside(rect: CGRect, partially: Bool = true) -> [Node]
```

### Selection Operations

```swift
// Select nodes
public func selectNode(_ id: UUID, additive: Bool = false)
public func selectNodes(_ ids: Set<UUID>, additive: Bool = false)

// Select edges
public func selectEdge(_ id: UUID, additive: Bool = false)

// Select all / clear
public func selectAll()
public func clearSelection()

// Get selected
public func getSelectedNodes() -> [Node]
public func getSelectedEdges() -> [Edge]
```

### Viewport Operations

```swift
// Set/get viewport
public func setViewport(_ transform: FlowTransform)
public func getViewport() -> FlowTransform

// Coordinate conversion
public func screenToCanvas(_ point: CGPoint) -> CGPoint
public func canvasToScreen(_ point: CGPoint) -> CGPoint
```

### Reactive Observers

Helper classes for reactive observation:

```swift
// Observe nodes data
@MainActor
public class NodesDataObserver<Node: FlowNode>: ObservableObject {
    @Published public var nodes: [Node]
    public func get(id: UUID) -> Node?
}

// Observe edges data
@MainActor
public class EdgesDataObserver<Edge: FlowEdge>: ObservableObject {
    @Published public var edges: [Edge]
    public func get(id: UUID) -> Edge?
}

// Observe viewport
@MainActor
public class ViewportObserver: ObservableObject {
    @Published public var viewport: FlowTransform
}

// Observe selection
@MainActor
public class SelectionObserver: ObservableObject {
    @Published public var selectedNodes: Set<UUID>
    @Published public var selectedEdges: Set<UUID>
    public var hasSelection: Bool { get }
}
```

**Usage Example:**

```swift
// Create store
let store = FlowStore<MyNode, MyEdge>()

// Use in SwiftUI
@StateObject var nodesObserver = NodesDataObserver(store: store)
@StateObject var viewportObserver = ViewportObserver(store: store)

// Reactive updates
store.addNode(newNode)  // Automatically publishes change
```

---

## Configuration

### CanvasConfig

Main configuration structure.

```swift
public struct CanvasConfig {
    public var zoom: ZoomConfig
    public var grid: GridConfig
    public var interaction: InteractionConfig
    public var edge: EdgeConfig
    public var miniMap: MiniMapConfig?
    public var history: HistoryConfig
    public var autoPan: AutoPanConfig
    public var helperLines: HelperLinesConfig
    
    // Presets
    public static let `default`: CanvasConfig
    public static let minimal: CanvasConfig
    public static let presentation: CanvasConfig
}
```

### Sub-Configs

```swift
// Zoom
public struct ZoomConfig {
    public var min: CGFloat
    public var max: CGFloat
    public var initial: CGFloat
    public var doubleClickEnabled: Bool
    public var scrollEnabled: Bool
    public var stepFactor: CGFloat
    public var panOnScrollMode: PanOnScrollMode    // NEW: zoom, horizontal, vertical, or free
    
    public static let `default`: ZoomConfig
    public static let restricted: ZoomConfig
    public static let disabled: ZoomConfig
}

// Grid
public struct GridConfig {
    public var visible: Bool
    public var size: CGFloat
    public var snap: Bool
    public var pattern: GridPattern
    public var style: GridStyle
    
    public static let `default`: GridConfig
    public static let hidden: GridConfig
    public static let snapping: GridConfig
}

// Interaction
public struct InteractionConfig {
    public var mode: InteractionMode
    public var dragThreshold: CGFloat
    public var connectionMode: ConnectionMode      // NEW: strict or loose
    public var selectionMode: SelectionMode        // NEW: full, partial, or none
    
    public static let `default`: InteractionConfig
    public static let viewOnly: InteractionConfig
}

// Edge
public struct EdgeConfig {
    public var pathStyle: EdgePathStyle
    public var strokeStyle: EdgeStrokeStyle
    public var animated: Bool
    public var animationDuration: TimeInterval
    public var showLabels: Bool
    public var sourceMarker: EdgeMarker?           // NEW: marker at source
    public var targetMarker: EdgeMarker?           // NEW: marker at target
    public var connectionLineType: ConnectionLineType  // NEW: preview line style
    
    public static let `default`: EdgeConfig
    public static let straight: EdgeConfig
    public static let animated: EdgeConfig
}

// History
public struct HistoryConfig {
    public var enabled: Bool
    public var maxUndoCount: Int
    
    public static let `default`: HistoryConfig
    public static let disabled: HistoryConfig
}

// AutoPan
public struct AutoPanConfig {
    public var enabled: Bool
    public var speed: CGFloat
    public var threshold: CGFloat
    
    public static let `default`: AutoPanConfig
    public static let disabled: AutoPanConfig
}

// Helper Lines
public struct HelperLinesConfig {
    public var enabled: Bool
    public var threshold: CGFloat
    public var snapToGuides: Bool
    public var showCenterGuides: Bool
    public var showEdgeGuides: Bool
    public var hapticFeedback: Bool
    public var style: HelperLinesStyle
    
    public static let `default`: HelperLinesConfig
    public static let snapping: HelperLinesConfig
    public static let visualOnly: HelperLinesConfig
    public static let disabled: HelperLinesConfig
}

// Helper Lines Style
public struct HelperLinesStyle {
    public var lineColor: RGBAColor      // Color with opacity (alpha channel)
    public var lineWidth: CGFloat        // Line thickness in points
    public var dashPattern: [CGFloat]    // Empty array for solid, [5,3] for dashed
    
    public static let `default`: HelperLinesStyle
    public static let dashed: HelperLinesStyle
    public static let subtle: HelperLinesStyle
}
```

**Style Customization Examples:**

```swift
// Custom red semi-transparent line
HelperLinesStyle(
    lineColor: RGBAColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.6),
    lineWidth: 2.0
)

// Bright green thick line
HelperLinesStyle(
    lineColor: RGBAColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0),
    lineWidth: 3.0
)

// Subtle gray dashed line
HelperLinesStyle(
    lineColor: RGBAColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.3),
    lineWidth: 1.0,
    dashPattern: [8, 4]  // 8 points line, 4 points gap
)

// Ultra-thin purple line
HelperLinesStyle(
    lineColor: RGBAColor(red: 0.8, green: 0.0, blue: 1.0, alpha: 0.7),
    lineWidth: 0.5
)
```

---

## Commands

### CanvasCommand

Atomic operations for the command pattern.

```swift
public enum CanvasCommand: Equatable, Sendable {
    // Viewport
    case setTransform(FlowTransform)
    case zoom(to: CGFloat, anchor: ScreenPoint)
    case zoomBy(factor: CGFloat, anchor: ScreenPoint)
    case pan(by: CGSize)
    case panToCenter(CanvasPoint)
    case fitView(padding: CGFloat)
    case fitNodes(ids: Set<UUID>, padding: CGFloat)
    case resetView
    
    // Selection
    case select(nodeIds: Set<UUID>, edgeIds: Set<UUID>, additive: Bool)
    case selectAll
    case clearSelection
    case toggleNodeSelection(UUID)
    case toggleEdgeSelection(UUID)
    
    // Nodes
    case moveNodes(ids: Set<UUID>, delta: CGSize)
    case moveNodeTo(id: UUID, position: CanvasPoint)
    case resizeNode(id: UUID, newSize: CGSize, anchor: ResizeAnchor)
    case resizeNodeByScale(id: UUID, scaleFactor: CGFloat, anchor: ResizeAnchor)
    case resizeNodeToWidth(id: UUID, newWidth: CGFloat, anchor: ResizeAnchor)
    case deleteNodes(ids: Set<UUID>)
    case setNodeParent(id: UUID, parentId: UUID?)
    case setNodeZIndex(id: UUID, zIndex: Double)
    case bringToFront(ids: Set<UUID>)
    case sendToBack(ids: Set<UUID>)
    
    // Edges
    case createEdge(sourceNode: UUID, sourcePort: UUID, targetNode: UUID, targetPort: UUID)
    case deleteEdges(ids: Set<UUID>)
    
    // Compound
    case deleteSelection
    case duplicate(nodeIds: Set<UUID>)
    case copy(nodeIds: Set<UUID>)
    case cut(nodeIds: Set<UUID>)
    case paste(at: CanvasPoint?)
    
    // Properties
    public var isUndoable: Bool { get }
    public var undoName: String? { get }
}
```

### CanvasTransaction

Groups commands for batch undo.

```swift
public struct CanvasTransaction: Equatable, Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let commands: [CanvasCommand]
    public let timestamp: Date
}

// Result builder for transactions
@resultBuilder
public struct TransactionBuilder {
    public static func buildBlock(_ commands: CanvasCommand...) -> [CanvasCommand]
}
```

---

## Views

### CanvasView

Main canvas view.

```swift
public struct CanvasView<Node: FlowNode, Edge: FlowEdge, NodeContent: View>: View {
    // Simple init
    public init(
        nodes: Binding<[Node]>,
        edges: Binding<[Edge]>,
        config: CanvasConfig = .default,
        @ViewBuilder nodeContent: @escaping (Node, Bool) -> NodeContent
    )
    
    // Advanced init with controller
    public init(
        nodes: Binding<[Node]>,
        edges: Binding<[Edge]>,
        controller: CanvasController,
        @ViewBuilder nodeContent: @escaping (Node, Bool) -> NodeContent
    )
}
```

### Modifiers

```swift
// Callbacks
.onNodeMoved { node, position in }
.onSelectionChanged { nodeIds in }
.onConnectionCreated { sourceNode, sourcePort, targetNode, targetPort in }
.onNodeResized { node, size in }
.onNodesDeleted { nodeIds, edgeIds in }

// Configuration
.miniMap(.bottomTrailing)
.grid(.dots, snap: true)
.controls(.topLeft)
.interactionMode(.edit)
.nodeToolbar { node, manager, actions in ... }
.edgeAccessory { edge, position, isHovering, dragManager in ... }
```

---

## Protocols

### FlowNode

```swift
public protocol FlowNode: Identifiable where ID == UUID {
    var id: UUID { get }
    var position: CGPoint { get set }
    var width: CGFloat { get set }
    var height: CGFloat { get set }
    var parentId: UUID? { get set }
    var zIndex: Double { get set }
    var inputPorts: [any FlowPort] { get }
    var outputPorts: [any FlowPort] { get }
}
```

### FlowEdge

```swift
public protocol FlowEdge: Identifiable where ID == UUID {
    var id: UUID { get }
    var sourceNodeId: UUID { get }
    var sourcePortId: UUID { get }
    var targetNodeId: UUID { get }
    var targetPortId: UUID { get }
}
```

### FlowPort

```swift
public protocol FlowPort: Identifiable where ID == UUID {
    var id: UUID { get }
    var position: PortPosition { get }
}
```

---

## Node Resizing

### Overview

SwiftFlow supports interactive node resizing with aspect ratio preservation, minimum size constraints, and full undo/redo support.

### Features

- **Visual Resize Handle**: Appears at bottom-right corner of selected nodes
- **Aspect Ratio Preservation**: Maintains original proportions during resize
- **Minimum Size Constraints**: Configurable via `minNodeWidth` and `minNodeHeight`
- **Drag Threshold**: 3-point threshold prevents accidental resizing
- **Port Position Updates**: Ports automatically recalculate positions after resize
- **Full Undo/Redo**: All resize operations are undoable

### Configuration

```swift
let config = CanvasConfig(
    enableNodeResizing: true,
    minNodeWidth: 80,
    minNodeHeight: 60,
    preserveAspectRatio: true,
    interaction: InteractionConfig(
        mode: .edit,
        dragThreshold: 3.0
    )
)
```

### Interactive Resizing

Users can resize nodes by:
1. Selecting a node (must have `isResizable = true`)
2. Hovering over the bottom-right corner (resize handle appears)
3. Dragging the handle to resize

The top-left corner remains fixed while the node scales uniformly.

### Custom Resize Handle Overlay

You can hide the default handle and provide your own overlay content:

```swift
SwiftFlow.CanvasView(nodes: $nodes, edges: $edges)
    .resizeHandle(config: ResizeHandleConfig(isVisible: false, inset: 6))
    .resizeOverlay { node, isSelected, resizeManager in
        if isSelected && node.isResizable {
            MyCustomResizeHandle(isActive: resizeManager.isResizing)
        }
    }
```

Notes:
- The overlay is positioned at the bottom-right corner by default.
- Use `ResizeHandleConfig.inset` to control spacing from the node border.
- The resize gesture is still managed internally by SwiftFlow and attached to your overlay.

### Programmatic API

```swift
// Resize to specific width (preserves aspect ratio)
controller.resizeNode(id: nodeId, toWidth: 300)

// Resize by scale factor
controller.resizeNode(id: nodeId, byScale: 2.0)  // Double the size
controller.resizeNode(id: nodeId, byScale: 0.5) // Half the size

// Resize to specific size
controller.resizeNode(
    id: nodeId,
    to: CGSize(width: 400, height: 200)
)

// Resize all selected nodes
controller.resizeSelection(byScale: 1.5)
```

### Anchor Points

The anchor determines which point stays fixed during resize:

```swift
// Bottom-right resize (default) - top-left stays fixed
controller.resizeNode(id: nodeId, to: newSize, anchor: .topLeft)

// Top-left resize - bottom-right stays fixed
controller.resizeNode(id: nodeId, to: newSize, anchor: .bottomRight)

// Center resize - center stays fixed (grows equally)
controller.resizeNode(id: nodeId, to: newSize, anchor: .center)
```

Available anchors: `.topLeft`, `.topRight`, `.bottomLeft`, `.bottomRight`, `.top`, `.bottom`, `.left`, `.right`, `.center`

### Port Position Updates

When a node is resized, its ports automatically update their positions:

```swift
// Ports with presets adapt to new size
let port = BasicPort(
    id: UUID(),
    position: .right,
    layout: .rightCenter  // Stays at right center of node
)

// After resize from 200x100 to 400x200:
// Port position updates from (200, 50) to (400, 100) automatically
```

### Callbacks

```swift
CanvasView(nodes: $nodes, edges: $edges, config: config) { node, isSelected in
    NodeView(node: node, isSelected: isSelected)
}
.onNodeResized { node, newSize in
    print("Node \(node.id) resized to \(newSize)")
    // Update your data model here
}
```

### Undo/Redo

```swift
// Resize operations are automatically undoable
controller.resizeNode(id: nodeId, byScale: 2.0)

// Undo restores original size and position
controller.undo()

// Redo re-applies the resize
controller.redo()

// Check undo/redo availability
if controller.canUndo {
    print("Can undo: \(controller.undoName ?? "")")
}
```

### Disable Resizing

```swift
// Disable for specific nodes
var node = MyNode(...)
node.isResizable = false

// Disable globally
let config = CanvasConfig(
    interaction: InteractionConfig(
        mode: .custom(InteractionPermissions(
            canSelect: true,
            canDrag: true,
            canConnect: true,
            canResize: false,  // Disable resizing
            canBoxSelect: true,
            canUseKeyboard: true
        ))
    )
)
```

### Advanced: Transactions

Group resize with other operations for atomic undo:

```swift
controller.transaction("Resize and Move") {
    .resizeNode(id: nodeId, newSize: CGSize(width: 300, height: 150), anchor: .topLeft)
    .moveNodes(ids: [nodeId], delta: CGSize(width: 50, height: 0))
}
// Single undo reverts both operations
```

### See Also

- ``CanvasController/resizeNode(id:toWidth:anchor:)``
- ``CanvasController/resizeNode(id:byScale:anchor:)``
- <doc:GettingStarted>

---

## Public Helpers

SwiftFlow provides helper functions for common operations.

### Path Calculation Helpers

```swift
// Calculate bezier path
public func getBezierPath(
    sourceX: CGFloat,
    sourceY: CGFloat,
    targetX: CGFloat,
    targetY: CGFloat,
    sourcePosition: PortPosition = .right,
    targetPosition: PortPosition = .left,
    curvature: CGFloat = 0.25
) -> PathResult

// Calculate smooth step (orthogonal) path
public func getSmoothStepPath(
    sourceX: CGFloat,
    sourceY: CGFloat,
    targetX: CGFloat,
    targetY: CGFloat,
    sourcePosition: PortPosition = .right,
    targetPosition: PortPosition = .left,
    borderRadius: CGFloat = 8
) -> PathResult

// Calculate straight line path
public func getStraightPath(
    sourceX: CGFloat,
    sourceY: CGFloat,
    targetX: CGFloat,
    targetY: CGFloat
) -> PathResult

// Get bezier edge center for label placement
public func getBezierEdgeCenter(
    sourceX: CGFloat,
    sourceY: CGFloat,
    sourceControlX: CGFloat,
    sourceControlY: CGFloat,
    targetX: CGFloat,
    targetY: CGFloat,
    targetControlX: CGFloat,
    targetControlY: CGFloat
) -> (centerX: CGFloat, centerY: CGFloat, offsetX: CGFloat, offsetY: CGFloat)

// Get simple edge center
public func getSimpleEdgeCenter(
    sourceX: CGFloat,
    sourceY: CGFloat,
    targetX: CGFloat,
    targetY: CGFloat
) -> (centerX: CGFloat, centerY: CGFloat)
```

### Bounds Calculation Helpers

```swift
// Get bounding rectangle of nodes
public func getRectOfNodes<Node: FlowNode>(_ nodes: [Node]) -> CGRect?

// Get combined bounds of rectangles
public func getBoundsOfRects(_ rect1: CGRect, _ rect2: CGRect) -> CGRect

// Calculate transform to fit bounds in viewport
public func getTransformForBounds(
    bounds: CGRect,
    viewportSize: CGSize,
    minZoom: CGFloat,
    maxZoom: CGFloat,
    padding: CGFloat = 0.1
) -> FlowTransform
```

### Node Query Helpers

```swift
// Get nodes in rectangular area
public func getNodesInside<Node: FlowNode>(
    rect: CGRect,
    nodes: [Node],
    partially: Bool = true
) -> [Node]

// Check if connection exists
public func connectionExists(
    sourceNode: UUID,
    sourcePort: UUID,
    targetNode: UUID,
    targetPort: UUID,
    edges: [any FlowEdge]
) -> Bool
```

### Coordinate Conversion Helpers

```swift
// Convert screen to canvas coordinates
public func screenToCanvas(
    point: CGPoint,
    transform: FlowTransform
) -> CGPoint

// Convert canvas to screen coordinates
public func canvasToScreen(
    point: CGPoint,
    transform: FlowTransform
) -> CGPoint
```

### Utility Helpers

```swift
// Clamp value between min and max
public func clamp<T: Comparable>(_ value: T, min minValue: T, max maxValue: T) -> T

// Calculate distance between points
public func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat

// Check if point is near line segment
public func isPointNearLine(
    point: CGPoint,
    lineStart: CGPoint,
    lineEnd: CGPoint,
    threshold: CGFloat = 10
) -> Bool
```

### Global Utility Functions

```swift
// Check if nodes are initialized
public func areNodesInitialized<Node: FlowNode>(_ nodes: [Node]) -> Bool

// Get visible nodes in viewport
public func getVisibleNodes<Node: FlowNode>(
    nodes: [Node],
    viewport: FlowTransform,
    viewportSize: CGSize,
    padding: CGFloat = 50
) -> [Node]
```

**Usage Examples:**

```swift
// Calculate a bezier path
let result = getBezierPath(
    sourceX: 100, sourceY: 100,
    targetX: 300, targetY: 200,
    curvature: 0.3
)

// Get nodes in area
let rect = CGRect(x: 0, y: 0, width: 500, height: 500)
let nodesInArea = getNodesInside(rect: rect, nodes: allNodes)

// Convert coordinates
let canvasPoint = screenToCanvas(
    point: CGPoint(x: 100, y: 100),
    transform: viewport
)
```

---

## Error Handling

### FlowError

SwiftFlow provides a comprehensive error system for operations.

```swift
public struct FlowError: Error, Equatable, Sendable {
    public let code: ErrorCode
    public let message: String
    public let context: [String: String]?
}
```

### Error Codes

```swift
public enum ErrorCode: String, Equatable, Sendable, Codable {
    // Node errors
    case nodeNotFound = "NODE_NOT_FOUND"
    case nodeMissingDimensions = "NODE_MISSING_DIMENSIONS"
    case nodeInvalid = "NODE_INVALID"
    
    // Edge errors
    case edgeNotFound = "EDGE_NOT_FOUND"
    case edgeInvalid = "EDGE_INVALID"
    case edgeSourceMissing = "EDGE_SOURCE_MISSING"
    case edgeTargetMissing = "EDGE_TARGET_MISSING"
    
    // Connection errors
    case connectionInvalid = "CONNECTION_INVALID"
    case connectionExists = "CONNECTION_EXISTS"
    case connectionCycle = "CONNECTION_CYCLE"
    case portNotFound = "PORT_NOT_FOUND"
    
    // Transform errors
    case transformInvalid = "TRANSFORM_INVALID"
    case zoomOutOfBounds = "ZOOM_OUT_OF_BOUNDS"
    
    // Command errors
    case commandFailed = "COMMAND_FAILED"
    case commandInvalid = "COMMAND_INVALID"
    
    // State errors
    case stateInvalid = "STATE_INVALID"
    case operationNotAllowed = "OPERATION_NOT_ALLOWED"
}
```

### Convenience Initializers

```swift
// Node errors
public static func nodeNotFound(id: UUID) -> FlowError
public static func edgeNotFound(id: UUID) -> FlowError

// Connection errors
public static func invalidConnection(reason: String) -> FlowError
public static func connectionExists() -> FlowError
public static func connectionCycle() -> FlowError
public static func portNotFound(id: UUID) -> FlowError

// Transform errors
public static func zoomOutOfBounds(value: CGFloat, min: CGFloat, max: CGFloat) -> FlowError

// Command errors
public static func commandFailed(reason: String) -> FlowError
public static func operationNotAllowed(reason: String) -> FlowError
```

### Error Checking

```swift
// Check if error matches specific code
public func isErrorOfType(_ error: Error, code: ErrorCode) -> Bool

// Extract FlowError from any error
public func asFlowError(_ error: Error) -> FlowError?
```

**Usage Example:**

```swift
do {
    try performOperation()
} catch let error as FlowError {
    switch error.code {
    case .nodeNotFound:
        print("Node not found: \(error.message)")
    case .connectionCycle:
        print("Would create cycle")
    default:
        print("Error: \(error.message)")
    }
}

// Or check error type
if isErrorOfType(error, code: .nodeNotFound) {
    // Handle node not found
}
```

---

## Additional Resources

- [Getting Started Guide](Guides/GettingStarted.md)
- [Architecture Guide](Architecture.md)
- [Coordinate System Guide](https://jeffryberdugox.github.io/SwiftFlow/documentation/swiftflow/coordinatesystem)
