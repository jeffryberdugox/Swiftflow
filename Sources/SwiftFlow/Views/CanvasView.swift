//
//  CanvasView.swift
//  SwiftFlow
//
//  Main canvas view for displaying and interacting with flow nodes and edges.
//  Now supports both legacy initialization and new CanvasController-based initialization.
//

import SwiftUI
import Combine

/// Main canvas view for displaying and interacting with flow nodes and edges.
///
/// # Simple Usage (Recommended)
/// ```swift
/// CanvasView(nodes: $nodes, edges: $edges) { node, isSelected in
///     MyNodeView(node: node, isSelected: isSelected)
/// }
/// .onConnectionCreated { s, sp, t, tp in
///     edges.append(MyEdge(...))
/// }
/// ```
///
/// # Advanced Usage (with CanvasController)
/// ```swift
/// @StateObject var controller = CanvasController(config: .default)
///
/// CanvasView(nodes: $nodes, edges: $edges, controller: controller) { node, isSelected in
///     MyNodeView(node: node, isSelected: isSelected)
/// }
///
/// // External control
/// Button("Fit") { controller.fitView() }
/// Button("Zoom In") { controller.zoomIn() }
/// ```
public struct CanvasView<Node: FlowNode, Edge: FlowEdge, NodeContent: View>: View where Node: Codable, Edge: Codable {
    // MARK: - Bindings
    
    @Binding var nodes: [Node]
    @Binding var edges: [Edge]
    
    // MARK: - Configuration
    
    let config: CanvasConfig
    var keyboardConfig: KeyboardConfig
    let nodeContent: (Node, Bool) -> NodeContent
    
    // MARK: - Controller Support
    
    /// Internal controller (created automatically if no external controller provided)
    @StateObject private var internalController: CanvasController
    
    /// External controller wrapper (for observing external controller changes)
    @StateObject private var externalControllerWrapper: ExternalControllerWrapper
    
    /// Resize observer to trigger view updates during resize preview
    @StateObject private var resizeObserver = ResizeObserver()

    /// The active controller - returns external if provided, otherwise internal
    private var controller: CanvasController {
        externalControllerWrapper.controller ?? internalController
    }
    
    // Helper class to wrap and observe external controller
    private class ExternalControllerWrapper: ObservableObject {
        var controller: CanvasController?
        private var cancellable: AnyCancellable?
        
        init(controller: CanvasController? = nil) {
            self.controller = controller
            if let controller = controller {
                // Forward changes from controller to this wrapper
                cancellable = controller.objectWillChange.sink { [weak self] _ in
                    self?.objectWillChange.send()
                }
            }
        }
    }

    @MainActor
    private final class ResizeObserver: ObservableObject {
        @Published private(set) var tick: Int = 0
        private var cancellable: AnyCancellable?

        func bind(to manager: ResizeManager) {
            cancellable = manager.objectWillChange
                .sink { [weak self] _ in
                    self?.tick += 1
                }
        }
    }
    
    // MARK: - Legacy Managers (Exposed for backward compatibility)
    
    /// Access to pan/zoom manager for external control
    public var panZoomManager: PanZoomManager {
        controller.panZoomManager
    }
    
    /// Access to drag manager for external control
    public var dragManager: DragManager {
        controller.dragManager
    }
    
    /// Access to selection manager for external control
    public var selectionManager: SelectionManager {
        controller.selectionManager
    }
    
    /// Access to connection manager for external control
    public var connectionManager: ConnectionManager {
        controller.connectionManager
    }
    
    /// Access to edge hover manager for external control
    public var edgeHoverManager: EdgeHoverManager {
        controller.edgeHoverManager
    }
    
    /// Access to port position registry for external control
    public var portPositionRegistry: PortPositionRegistry {
        controller.portPositionRegistry
    }

    /// Access to resize manager for external control (observed for real-time resize updates)
    private var resizeManager: ResizeManager {
        controller.resizeManager
    }

    // MARK: - MiniMap Controller (New)
    
    @StateObject private var miniMapController = MiniMapController()
    
    // MARK: - Copy/Paste Manager (Type-specific)
    
    @StateObject private var copyPasteManager = CopyPasteManager<Node, Edge>()
    
    // MARK: - Local State
    
    @State private var viewportSize: CGSize = .zero
    @State private var showControls: Bool = true
    @State private var autoPanTimer: Timer?
    @State private var currentDragScreenPosition: CGPoint = .zero
    @State private var miniMapInitialized: Bool = false
    @State private var canvasInitialized: Bool = false

    // MARK: - Marquee Selection State
    
    @State private var marqueeStart: CGPoint? = nil
    @State private var marqueeEnd: CGPoint? = nil
    @State private var isMarqueeActive: Bool = false
    @State private var preMarqueeSelection: Set<UUID> = []
    
    // MARK: - Zoom Gesture State
    
    @State private var magnificationStartScale: CGFloat = 1.0
    
    // MARK: - Callbacks
    
    public var onNodeMoved: ((Node, CGPoint) -> Void)?
    public var onSelectionChanged: ((Set<UUID>) -> Void)?
    public var onConnectionCreated: ((UUID, UUID, UUID, UUID) -> Void)?
    public var onNodeResized: ((Node, CGSize) -> Void)?
    public var onNodesDeleted: ((Set<UUID>, Set<UUID>) -> Void)?
    public var onNodesPasted: (([Node], [Edge]) -> Void)?
    public var customActionHandler: CanvasActionHandler<Node, Edge>?
    public var onConnectionDroppedOnCanvas: ((ConnectionDropContext) -> ConnectionDropAction)?
    public var onTransformChanged: ((FlowTransform) -> Void)?

    // MARK: - Node Toolbar
    
    public var nodeToolbarContent: ((Node, PanZoomManager, NodeToolbarActions) -> AnyView)?
    public var nodeToolbarConfig: NodeToolbarConfig = .default
    public var onNodeEdit: ((Node) -> Void)?

    // MARK: - Resize Handle Customization

    public var resizeHandleConfig: ResizeHandleConfig = .default
    public var resizeOverlayContent: ((Node, Bool, ResizeManager) -> AnyView)?
    
    // MARK: - Edge Accessory
    
    public var edgeAccessoryContent: ((Edge, CGPoint, Bool, DragManager) -> AnyView)?
    public var edgeAccessoryConfig: EdgeAccessoryConfig = .default
    
    // MARK: - Canvas Controls Customization
    
    public var customControlsContent: ((PanZoomManager, [Node], AnyView) -> AnyView)?
    public var customControlsPosition: PanelPosition?
    
    // MARK: - MiniMap Customization
    
    public var customMiniMapContent: ((
        [Node],
        Set<UUID>,
        PanZoomManager,
        MiniMapController,
        MiniMapConfig,
        AnyView
    ) -> AnyView)?
    public var customMiniMapPosition: PanelPosition?
    
    // MARK: - Path Calculator
    
    private var pathCalculator: any PathCalculator {
        switch config.edge.pathStyle {
        case .bezier(let curvature):
            return BezierPathCalculator(curvature: curvature)
        case .smoothStep:
            return SmoothStepPathCalculator()
        case .straight:
            return StraightPathCalculator()
        }
    }
    
    // MARK: - Initialization (Simple)
    
    /// Creates a canvas view with the given configuration.
    /// - Parameters:
    ///   - nodes: Binding to the array of nodes
    ///   - edges: Binding to the array of edges
    ///   - config: Canvas configuration (default: .default)
    ///   - keyboardConfig: Keyboard shortcuts configuration
    ///   - nodeContent: View builder for node content
    public init(
        nodes: Binding<[Node]>,
        edges: Binding<[Edge]>,
        config: CanvasConfig = .default,
        keyboardConfig: KeyboardConfig = KeyboardConfig(),
        @ViewBuilder nodeContent: @escaping (Node, Bool) -> NodeContent
    ) {
        self._nodes = nodes
        self._edges = edges
        self.config = config
        self.keyboardConfig = keyboardConfig
        self.nodeContent = nodeContent
        
        // Create internal controller with config
        self._internalController = StateObject(wrappedValue: CanvasController(config: config))
        self._externalControllerWrapper = StateObject(wrappedValue: ExternalControllerWrapper())
    }
    
    // MARK: - Initialization (Advanced with Controller)
    
    /// Creates a canvas view with an external controller for advanced control.
    /// - Parameters:
    ///   - nodes: Binding to the array of nodes
    ///   - edges: Binding to the array of edges
    ///   - controller: External CanvasController for advanced control
    ///   - keyboardConfig: Keyboard shortcuts configuration
    ///   - nodeContent: View builder for node content
    public init(
        nodes: Binding<[Node]>,
        edges: Binding<[Edge]>,
        controller: CanvasController,
        keyboardConfig: KeyboardConfig = KeyboardConfig(),
        @ViewBuilder nodeContent: @escaping (Node, Bool) -> NodeContent
    ) {
        self._nodes = nodes
        self._edges = edges
        self.config = controller.config
        self.keyboardConfig = keyboardConfig
        self.nodeContent = nodeContent
        
        // Use dummy internal controller (won't be used)
        self._internalController = StateObject(wrappedValue: CanvasController())
        self._externalControllerWrapper = StateObject(wrappedValue: ExternalControllerWrapper(controller: controller))
    }
    
    // MARK: - Port Registry Cleanup

    private func cleanupDeletedNodePorts(currentNodeIds: Set<UUID>) {
        // Get all registered node IDs from the port registry
        let registeredNodeIds = Set(portPositionRegistry.allNodeLocalOffsets.compactMap { portId, _ in
            portPositionRegistry.nodeId(for: portId)
        })

        // Find nodes that are registered but no longer exist
        let deletedNodeIds = registeredNodeIds.subtracting(currentNodeIds)

        // Clean up ports for deleted nodes
        for nodeId in deletedNodeIds {
            portPositionRegistry.unregisterNode(nodeId: nodeId)
        }
    }

    // MARK: - Config Observer

    private func updateManagersFromConfig() {
        // Update DragManager
        controller.dragManager.snapToGrid = config.grid.snap
        controller.dragManager.gridSize = config.grid.size
        controller.dragManager.dragThreshold = config.interaction.dragThreshold
        controller.dragManager.autoPanEnabled = config.autoPan.enabled
        controller.dragManager.autoPanSpeed = config.autoPan.speed
        controller.dragManager.autoPanThreshold = config.autoPan.threshold

        // Update PanZoomManager
        controller.panZoomManager.minZoom = config.zoom.min
        controller.panZoomManager.maxZoom = config.zoom.max

        // Update SelectionManager
        controller.selectionManager.enableMultiSelection = config.interaction.permissions.canSelect
    }
    
    // MARK: - Controls Overlay
    
    @ViewBuilder
    private var controlsOverlay: some View {
        let shouldShow = config.showControls || customControlsContent != nil
        
        if shouldShow {
            let position = customControlsPosition ?? .bottomLeft
            
            PanelView(position: position) {
                if let customBuilder = customControlsContent {
                    customBuilder(
                        panZoomManager,
                        nodes,
                        AnyView(defaultControlsView)
                    )
                } else {
                    defaultControlsView
                }
            }
        }
    }
    
    private var defaultControlsView: some View {
        ControlsView(
            nodes: nodes,
            config: ControlsConfig(showLock: false),
            onZoomIn: { controller.zoomIn() },
            onZoomOut: { controller.zoomOut() },
            onFitView: { controller.fitView() }
        )
    }
    
    // MARK: - MiniMap Overlay
    
    @ViewBuilder
    private var miniMapOverlay: some View {
        let shouldShow = (config.miniMapConfig != nil) || customMiniMapContent != nil

        if shouldShow, let miniMapConfig = config.miniMapConfig {
            let position = customMiniMapPosition ?? miniMapConfig.position
            let padding = miniMapConfig.padding
            
            PanelView(position: position, padding: padding) {
                if let customBuilder = customMiniMapContent {
                    customBuilder(
                        nodes,
                        selectionManager.selectedNodes,
                        panZoomManager,
                        miniMapController,
                        miniMapConfig,
                        AnyView(defaultMiniMapView)
                    )
                } else {
                    defaultMiniMapView
                }
            }
        }
    }

    private var defaultMiniMapView: some View {
        MiniMapView(
            nodes: nodes,
            selectedNodes: selectionManager.selectedNodes,
            panZoomManager: panZoomManager,
            controller: miniMapController,
            config: config.miniMapConfig ?? MiniMapConfig()
        )
    }
    
    // MARK: - Body
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                canvasBackground
                
                // Grid
                if config.grid.visible {
                    CanvasGridView(
                        transform: controller.transform,
                        config: config.grid
                    )
                    .id("grid-\(config.grid.size)-\(config.grid.visible)-\(config.grid.pattern.rawValue)")
                }
                
                // Content layer with transform
                ZStack {
                    edgesLayer
                    connectionPreviewLayer
                    
                    // Helper lines (alignment guides)
                    if config.helperLines.enabled {
                        helperLinesLayer
                    }
                    
                    nodesLayer
                    resizeHandlesLayer
                }
                .canvasTransform(controller.transform)
                
                // Overlays
                controlsOverlay
                miniMapOverlay
                marqueeSelectionOverlay
                nodeToolbarOverlay
            }
            .clipped()
            .contentShape(Rectangle())
            .gesture(canvasTapGesture)
            .gesture(marqueeSelectionGesture)
            .gesture(canvasZoomGesture)
            .keyboardShortcuts(manager: controller.keyboardManager, isEnabled: config.interaction.permissions.canUseKeyboard)
            .scrollGesture(
                onScroll: { delta, phase in
                    let panDelta = CGSize(width: delta.width, height: delta.height)
                    controller.pan(by: panDelta)
                },
                onMagnify: { magnification, location in
                    let factor = 1.0 + magnification
                    controller.zoom(by: factor, at: ScreenPoint(location))
                },
                onDoubleClick: { location in
                    guard config.zoom.doubleClickEnabled else { return }
                    let targetZoom: CGFloat = controller.transform.scale >= 1.5 ? 1.0 : 2.0
                    controller.setZoom(targetZoom, at: ScreenPoint(location))
                }
            )
            .task(id: geometry.size) {
                if !canvasInitialized {
                    try? await Task.sleep(for: .milliseconds(50))
                }
                
                await MainActor.run {
                    let currentSize = geometry.size
                    viewportSize = currentSize
                    controller.setViewportSize(currentSize)
                    magnificationStartScale = controller.transform.scale
                    
                    if !canvasInitialized {
                        updateManagersFromConfig()
                        setupEnvironmentBridge()
                        canvasInitialized = true
                    }
                    
                    updateMiniMapBounds()
                }
            }
            .onChange(of: geometry.size) { newSize in
                viewportSize = newSize
                controller.setViewportSize(newSize)
                updateMiniMapBounds()
            }
            .onChange(of: config) { _ in
                updateManagersFromConfig()
            }
            .onChange(of: nodesHash) { _ in
                updateMiniMapBounds()
            }
            .onChange(of: controller.transform) { newTransform in
                updateMiniMapBounds()
                // Notify observers of transform change
                onTransformChanged?(newTransform)
            }
            .onChange(of: nodes.map(\.id)) { newNodeIds in
                // Clean up ports for deleted nodes
                cleanupDeletedNodePorts(currentNodeIds: Set(newNodeIds))
            }
        }
        .onAppear(perform: setupManagerCallbacks)
    }
    
    // MARK: - Environment Bridge
    
    private func setupEnvironmentBridge() {
        let environment = CanvasEnvironment(
            getNodes: { self.nodes },
            getEdges: { self.edges },
            applyNodeEdits: { edits in
                self.applyNodeEdits(edits)
            },
            applyEdgeEdits: { edits in
                self.applyEdgeEdits(edits)
            }
        )
        controller.setEnvironment(AnyCanvasEnvironment(environment))
    }
    
    private func applyNodeEdits(_ edits: [NodeEdit]) {
        for edit in edits {
            switch edit {
            case .move(let id, let position):
                if let index = nodes.firstIndex(where: { $0.id == id }) {
                    let node = nodes[index]
                    nodes[index].position = position
                    onNodeMoved?(node, position)
                }
            case .resize(let id, let size):
                if let index = nodes.firstIndex(where: { $0.id == id }) {
                    let node = nodes[index]
                    nodes[index].width = size.width
                    nodes[index].height = size.height
                    onNodeResized?(node, size)
                }
            case .delete(let id):
                portPositionRegistry.unregisterNode(nodeId: id)
                nodes.removeAll { $0.id == id }
            case .setParent(let id, let parentId):
                if let index = nodes.firstIndex(where: { $0.id == id }) {
                    nodes[index].parentId = parentId
                }
            case .setZIndex(let id, let zIndex):
                if let index = nodes.firstIndex(where: { $0.id == id }) {
                    nodes[index].zIndex = zIndex
                }
            case .add, .updateData:
                break
            }
        }
    }
    
    private func applyEdgeEdits(_ edits: [EdgeEdit]) {
        for edit in edits {
            switch edit {
            case .delete(let id):
                edges.removeAll { $0.id == id }
            case .create, .updateStyle:
                break
            }
        }
    }
    
    // MARK: - MiniMap Updates

    private var nodesHash: String {
        nodes.map { "\($0.id)-\($0.position.x)-\($0.position.y)-\($0.width)-\($0.height)" }.joined()
    }
    
    private func updateMiniMapBounds() {
        guard config.miniMapConfig != nil else { return }

        // Calculate nodes bounds in canvas coordinates
        if let bounds = calculateNodesBounds(nodes) {
            miniMapController.nodesBounds = CanvasRect(bounds)
        }
        
        // Calculate viewport rect in canvas coordinates using new type-safe transform
        let viewportRectCanvas = controller.transform.toCanvasRect(
            CGRect(origin: .zero, size: viewportSize)
        )
        miniMapController.viewportRectCanvas = viewportRectCanvas
        
        // Update is triggered automatically by property setters (throttled internally)
    }
    
    // MARK: - Canvas Background
    
    private var canvasBackground: some View {
        config.canvasBackgroundColor
            .ignoresSafeArea()
    }
    
    // MARK: - Edges Layer
    
    private var edgesLayer: some View {
        let nodeOffsets = calculateNodeOffsets()
        
        return ForEach(Array(edges), id: \.id) { edge in
            if config.edge.animated {
                animatedEdgeView(for: edge, nodeOffsets: nodeOffsets, nodeSizes: [:], positionAdjustments: [:])
            } else {
                EdgeView(
                    edge: edge,
                    nodes: Array(nodes),
                    pathCalculator: pathCalculator,
                    strokeColor: getEdgeStrokeColor(for: edge),
                    selectedColor: getEdgeSelectedColor(for: edge),
                    lineWidth: getEdgeLineWidth(for: edge),
                    isSelected: selectionManager.isEdgeSelected(edge.id),
                    nodeOffsets: nodeOffsets,
                    nodeSizes: [:],
                    nodePositionAdjustments: [:],
                    showLabel: config.edge.showLabels,
                    transform: controller.transform,
                    edgeAccessoryBuilder: edgeAccessoryContent.map { builder in
                        { edge, position, isHovering in
                            builder(edge, position, isHovering, dragManager)
                        }
                    },
                    edgeAccessoryConfig: edgeAccessoryConfig,
                    isDragging: controller.isDragging,
                    onEdgeTap: { [self] edgeId in
                        handleEdgeTap(edgeId: edgeId)
                    },
                    onHoverChange: { [self] edgeId, hovering in
                        if hovering {
                            edgeHoverManager.setHoveredEdge(edgeId)
                        } else if edgeHoverManager.isEdgeHovered(edgeId) {
                            edgeHoverManager.clearHover()
                        }
                    }
                )
                .environmentObject(portPositionRegistry)
                .environmentObject(edgeHoverManager)
            }
        }
    }
    
    // MARK: - Animated Edge Helper
    
    @ViewBuilder
    private func animatedEdgeView(for edge: Edge, nodeOffsets: [UUID: CGSize], nodeSizes: [UUID: CGSize], positionAdjustments: [UUID: CGPoint]) -> some View {
        if let (sourcePoint, sourcePos, targetPoint, targetPos) = calculateEdgeEndpoints(edge: edge, nodeOffsets: nodeOffsets, nodeSizes: nodeSizes, positionAdjustments: positionAdjustments) {
            let result = pathCalculator.calculatePath(
                from: sourcePoint,
                to: targetPoint,
                sourcePosition: sourcePos,
                targetPosition: targetPos
            )
            
            let animConfig = AnimatedEdgeConfig(
                isAnimated: true,
                duration: config.edge.animationDuration,
                dashPattern: [5, 5],
                forward: true
            )
            
            ZStack {
                let isEdgeDisabled = (edge as? any DisableableFlowEdge)?.isDisabled ?? false
                let strokeColor = getEdgeStrokeColor(for: edge)
                let selectedColor = getEdgeSelectedColor(for: edge)
                let effectiveColor = isEdgeDisabled ? Color.gray.opacity(0.3) : (selectionManager.isEdgeSelected(edge.id) ? selectedColor : strokeColor)
                
                AnimatedEdgeView(
                    path: result.path,
                    config: animConfig,
                    color: effectiveColor,
                    lineWidth: getEdgeLineWidth(for: edge)
                )
                .opacity(isEdgeDisabled ? 0.5 : 1.0)
                
                if !isEdgeDisabled {
                    result.path
                        .stroke(
                            Color.clear,
                            style: StrokeStyle(
                                lineWidth: max(20, 2 + 10),
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .contentShape(
                            result.path.strokedPath(
                                StrokeStyle(lineWidth: max(20, 2 + 10), lineCap: .round, lineJoin: .round)
                            )
                        )
                        .onTapGesture {
                            handleEdgeTap(edgeId: edge.id)
                        }
                        .onHover { hovering in
                            if hovering {
                                edgeHoverManager.setHoveredEdge(edge.id)
                            } else if edgeHoverManager.isEdgeHovered(edge.id) {
                                edgeHoverManager.clearHover()
                            }
                        }
                }
                
                if !isEdgeDisabled {
                    if let builder = edgeAccessoryContent {
                        let shouldHide = edgeAccessoryConfig.hideOnDrag && dragManager.isDragging
                        if !shouldHide {
                            let accessoryPosition = result.path.trimmedPath(
                                from: 0,
                                to: edgeAccessoryConfig.position
                            ).currentPoint ?? .zero
                            
                            let offsetPosition = CGPoint(
                                x: accessoryPosition.x + edgeAccessoryConfig.offset.x,
                                y: accessoryPosition.y + edgeAccessoryConfig.offset.y
                            )
                            
                            let isEdgeHovered = edgeHoverManager.isEdgeHovered(edge.id)
                            builder(edge, offsetPosition, isEdgeHovered, dragManager)
                                .transition(edgeAccessoryConfig.animated ? .opacity : .identity)
                                .onHover { hovering in
                                    if hovering {
                                        edgeHoverManager.setHoveredEdge(edge.id)
                                    } else if edgeHoverManager.isEdgeHovered(edge.id) {
                                        edgeHoverManager.clearHover()
                                    }
                                }
                        }
                    } else if config.edge.showLabels, let labeledEdge = edge as? any LabeledFlowEdge, let label = labeledEdge.label {
                        let labelPoint = result.path.trimmedPath(from: 0, to: label.position).currentPoint ?? .zero
                        
                        Text(label.text)
                            .font(.system(size: label.fontSize))
                            .foregroundColor(label.textColor)
                            .padding(label.padding)
                            .background(
                                Group {
                                    if label.showBackground {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(label.backgroundColor)
                                            .shadow(color: Color.black.opacity(0.1), radius: 2)
                                    }
                                }
                            )
                            .position(labelPoint)
                            .onHover { hovering in
                                if hovering {
                                    edgeHoverManager.setHoveredEdge(edge.id)
                                } else if edgeHoverManager.isEdgeHovered(edge.id) {
                                    edgeHoverManager.clearHover()
                                }
                            }
                    }
                }
            }
        }
    }
    
    // MARK: - Calculate Edge Endpoints Helper
    
    private func calculateEdgeEndpoints(edge: Edge, nodeOffsets: [UUID: CGSize], nodeSizes: [UUID: CGSize] = [:], positionAdjustments: [UUID: CGPoint] = [:]) -> (CGPoint, PortPosition, CGPoint, PortPosition)? {
        guard let sourceNode = nodes.first(where: { $0.id == edge.sourceNodeId }),
              let targetNode = nodes.first(where: { $0.id == edge.targetNodeId }) else {
            return nil
        }
        
        let sourceOffset = nodeOffsets[sourceNode.id] ?? .zero
        let targetOffset = nodeOffsets[targetNode.id] ?? .zero
        let sourceSize = nodeSizes[sourceNode.id] ?? CGSize(width: sourceNode.width, height: sourceNode.height)
        let targetSize = nodeSizes[targetNode.id] ?? CGSize(width: targetNode.width, height: targetNode.height)
        let sourceAdjustment = positionAdjustments[sourceNode.id] ?? .zero
        let targetAdjustment = positionAdjustments[targetNode.id] ?? .zero
        
        let currentSourceNodePos = CGPoint(
            x: sourceNode.position.x + sourceOffset.width + sourceAdjustment.x,
            y: sourceNode.position.y + sourceOffset.height + sourceAdjustment.y
        )
        let currentTargetNodePos = CGPoint(
            x: targetNode.position.x + targetOffset.width + targetAdjustment.x,
            y: targetNode.position.y + targetOffset.height + targetAdjustment.y
        )
        
        let sourcePort = sourceNode.outputPorts.first { $0.id == edge.sourcePortId }
        let targetPort = targetNode.inputPorts.first { $0.id == edge.targetPortId }
        let sourcePos = sourcePort?.position ?? .right
        let targetPos = targetPort?.position ?? .left
        
        var sourcePoint: CGPoint
        var targetPoint: CGPoint
        
        if nodeSizes[sourceNode.id] != nil {
            sourcePoint = calculatePortPositionWithSize(
                position: sourcePos,
                nodeTopLeft: currentSourceNodePos,
                nodeSize: sourceSize
            )
        } else if let canvasPos = portPositionRegistry.canvasPosition(for: edge.sourcePortId, nodePosition: currentSourceNodePos) {
            sourcePoint = canvasPos
        } else if let port = sourcePort {
            let basePoint = calculatePortPosition(port: port, on: sourceNode, isInput: false)
            sourcePoint = CGPoint(
                x: basePoint.x + sourceOffset.width + sourceAdjustment.x,
                y: basePoint.y + sourceOffset.height + sourceAdjustment.y
            )
        } else {
            sourcePoint = CGPoint(
                x: currentSourceNodePos.x + sourceSize.width / 2,
                y: currentSourceNodePos.y
            )
        }
        
        if nodeSizes[targetNode.id] != nil {
            targetPoint = calculatePortPositionWithSize(
                position: targetPos,
                nodeTopLeft: currentTargetNodePos,
                nodeSize: targetSize
            )
        } else if let canvasPos = portPositionRegistry.canvasPosition(for: edge.targetPortId, nodePosition: currentTargetNodePos) {
            targetPoint = canvasPos
        } else if let port = targetPort {
            let basePoint = calculatePortPosition(port: port, on: targetNode, isInput: true)
            targetPoint = CGPoint(
                x: basePoint.x + targetOffset.width + targetAdjustment.x,
                y: basePoint.y + targetOffset.height + targetAdjustment.y
            )
        } else {
            targetPoint = CGPoint(
                x: currentTargetNodePos.x - targetSize.width / 2,
                y: currentTargetNodePos.y
            )
        }
        
        return (sourcePoint, sourcePos, targetPoint, targetPos)
    }
    
    private func calculatePortPositionWithSize(
        position: PortPosition,
        nodeTopLeft: CGPoint,
        nodeSize: CGSize
    ) -> CGPoint {
        switch position {
        case .left:
            return CGPoint(x: nodeTopLeft.x, y: nodeTopLeft.y + nodeSize.height / 2)
        case .right:
            return CGPoint(x: nodeTopLeft.x + nodeSize.width, y: nodeTopLeft.y + nodeSize.height / 2)
        case .top:
            return CGPoint(x: nodeTopLeft.x + nodeSize.width / 2, y: nodeTopLeft.y)
        case .bottom:
            return CGPoint(x: nodeTopLeft.x + nodeSize.width / 2, y: nodeTopLeft.y + nodeSize.height)
        }
    }
    
    // MARK: - Helper: Calculate Node Offsets
    
    private func calculateNodeOffsets() -> [UUID: CGSize] {
        var offsets: [UUID: CGSize] = [:]
        
        if let dragState = controller.dragState, dragState.hasMoved {
            for nodeId in dragState.draggedNodes {
                offsets[nodeId] = dragState.currentOffset
            }
        }
        
        return offsets
    }
    
    // MARK: - Connection Preview Layer
    
    @ViewBuilder
    private var connectionPreviewLayer: some View {
        if let connection = controller.connectionPreview {
            ConnectionPreviewView(
                connection: connection,
                pathCalculator: pathCalculator
            )
        }
    }
    
    // MARK: - Helper Lines Layer
    
    @ViewBuilder
    private var helperLinesLayer: some View {
        HelperLinesView(
            horizontalGuides: controller.helperLinesManager.horizontalGuides,
            verticalGuides: controller.helperLinesManager.verticalGuides,
            config: config.helperLines,
            transform: controller.transform,
            viewportSize: viewportSize
        )
    }
    
    // MARK: - Nodes Layer
    
    private var nodesLayer: some View {
        ZStack {
            ForEach(nodes, id: \.id) { node in
                let effectiveSize = effectiveNodeSize(for: node)

                nodeContent(node, selectionManager.isNodeSelected(node.id))
                    .environment(\.flowNodes, nodes.map { AnyFlowNode($0) })
                    .environment(\.portPositionRegistry, portPositionRegistry)
                    .coordinateSpace(name: "node-\(node.id)")
                    .frame(width: effectiveSize.width, height: effectiveSize.height)
                    .position(calculateNodePosition(for: node, size: effectiveSize))
                    .environmentObject(connectionManager)
                    .environmentObject(portPositionRegistry)
                    .environmentObject(controller.resizeManager)
                    .environmentObject(controller)
                    .gesture(nodeDragGesture(for: node))
                    .gesture(nodeTapGesture(for: node))
                    .zIndex(selectionManager.isNodeSelected(node.id) ? 1 : 0)
            }
        }
        .transaction { transaction in
            if resizeManager.isResizing {
                transaction.disablesAnimations = true
            }
        }
        .coordinateSpace(name: "canvas")
    }

    private var resizeHandlesLayer: some View {
        ZStack {
            ForEach(nodes, id: \.id) { node in
                let effectiveSize = effectiveNodeSize(for: node)
                let nodeCenter = calculateNodePosition(for: node, size: effectiveSize)
                let isSelected = selectionManager.isNodeSelected(node.id)
                let isResizable = node.isResizable && config.interaction.canResize && config.enableNodeResizing
                let shouldShow = resizeHandleConfig.isVisible || resizeOverlayContent != nil

                if shouldShow && isSelected && isResizable {
                    if let overlayBuilder = resizeOverlayContent {
                        ResizeHandleGestureOverlay(
                            nodeId: node.id,
                            nodeSize: CGSize(width: node.width, height: node.height),
                            content: overlayBuilder(node, isSelected, resizeManager)
                        )
                            .position(
                                x: nodeCenter.x + effectiveSize.width / 2 + resizeHandleConfig.inset,
                                y: nodeCenter.y + effectiveSize.height / 2 + resizeHandleConfig.inset
                            )
                    } else if resizeHandleConfig.isVisible {
                        ResizeHandleOverlay(
                            nodeId: node.id,
                            nodeSize: CGSize(width: node.width, height: node.height),
                            isSelected: isSelected,
                            isResizable: isResizable
                        )
                        .position(
                            x: nodeCenter.x + effectiveSize.width / 2 + resizeHandleConfig.inset,
                            y: nodeCenter.y + effectiveSize.height / 2 + resizeHandleConfig.inset
                        )
                    }
                }
            }
        }
        .allowsHitTesting(true)
        .environmentObject(controller.resizeManager)
        .environmentObject(controller)
    }
    
    // MARK: - Node Size and Position Calculation

    /// Returns the effective size of a node, considering resize preview
    private func effectiveNodeSize(for node: Node) -> CGSize {
        if let previewSize = resizeManager.currentSize(for: node.id) {
            return previewSize
        }
        return CGSize(width: node.width, height: node.height)
    }

    private func calculateNodePosition(for node: Node, size: CGSize) -> CGPoint {
        var canvasTopLeft: CGPoint

        if let dragState = controller.dragState,
           dragState.draggedNodes.contains(node.id),
           dragState.hasMoved {
            canvasTopLeft = dragState.newPosition(for: node.id) ?? node.position
        } else {
            canvasTopLeft = node.position
        }

        // Convert top-left to center for SwiftUI .position()
        // Use provided size to avoid multiple reads of effectiveNodeSize
        return CGPoint(
            x: canvasTopLeft.x + size.width / 2,
            y: canvasTopLeft.y + size.height / 2
        )
    }
    
    // MARK: - Canvas Action Handling
    
    private func handleCanvasAction(_ action: CanvasAction) {
        let context = CanvasActionContext<Node, Edge>(
            selectedNodeIds: selectionManager.selectedNodes,
            selectedEdgeIds: selectionManager.selectedEdges,
            nodes: nodes,
            edges: edges,
            clipboardNodes: copyPasteManager.clipboardNodes,
            clipboardEdges: copyPasteManager.clipboardEdges
        )
        
        if let customHandler = customActionHandler {
            let result = customHandler(action, context)
            if result == .handled {
                return
            }
        }
        
        switch action {
        case .copy:
            copyPasteManager.copy(
                nodes: nodes,
                edges: edges,
                selectedNodeIds: selectionManager.selectedNodes
            )
            
        case .paste:
            if let pasted = copyPasteManager.paste() {
                onNodesPasted?(pasted.nodes, pasted.edges)
            }
            
        case .cut:
            let toDelete = copyPasteManager.cut(
                nodes: nodes,
                edges: edges,
                selectedNodeIds: selectionManager.selectedNodes
            )
            // Unregister ports for deleted nodes
            for nodeId in toDelete.nodesToDelete {
                portPositionRegistry.unregisterNode(nodeId: nodeId)
            }
            onNodesDeleted?(toDelete.nodesToDelete, toDelete.edgesToDelete)
            
        case .duplicate:
            if let duplicated = copyPasteManager.duplicate(
                nodes: nodes,
                edges: edges,
                selectedNodeIds: selectionManager.selectedNodes
            ) {
                onNodesPasted?(duplicated.nodes, duplicated.edges)
            }
            
        case .delete:
            let selectedNodeIds = selectionManager.selectedNodes
            let connectedEdgeIds = Set(edges.filter { edge in
                selectedNodeIds.contains(edge.sourceNodeId) ||
                selectedNodeIds.contains(edge.targetNodeId)
            }.map(\.id))

            // Unregister ports for deleted nodes
            for nodeId in selectedNodeIds {
                portPositionRegistry.unregisterNode(nodeId: nodeId)
            }

            let allEdgesToDelete = connectedEdgeIds.union(selectionManager.selectedEdges)
            onNodesDeleted?(selectedNodeIds, allEdgesToDelete)
            selectionManager.clearSelection()
            
        case .undo:
            if config.history.enabled {
                controller.undo()
            }

        case .redo:
            if config.history.enabled {
                controller.redo()
            }
            
        case .selectAll:
            selectionManager.selectNodes(Set(nodes.map(\.id)), additive: false)
            
        case .escape:
            selectionManager.clearSelection()
            connectionManager.cancelConnection()
        }
    }
    
    // MARK: - Gestures
    
    private var canvasTapGesture: some Gesture {
        TapGesture()
            .onEnded {
                controller.clearSelection()
            }
    }
    
    // MARK: - Edge Selection
    
    private func handleEdgeTap(edgeId: UUID) {
        #if os(macOS)
        let additive = NSEvent.modifierFlags.contains(.command)
        #else
        let additive = false
        #endif
        
        controller.select(edge: edgeId, additive: additive)
    }
    
    // MARK: - Marquee Selection
    
    private var marqueeSelectionGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                guard config.interaction.permissions.canBoxSelect else { return }
                guard !controller.isDragging else { return }
                
                #if os(macOS)
                let additive = NSEvent.modifierFlags.contains(.command)
                #else
                let additive = false
                #endif
                
                if !isMarqueeActive {
                    marqueeStart = value.startLocation
                    isMarqueeActive = true
                    
                    if additive {
                        preMarqueeSelection = selectionManager.selectedNodes
                    } else {
                        preMarqueeSelection = []
                        selectionManager.clearSelection()
                    }
                }
                
                marqueeEnd = value.location
                updateMarqueeSelection(additive: additive)
            }
            .onEnded { _ in
                resetMarquee()
            }
    }
    
    private func updateMarqueeSelection(additive: Bool) {
        guard let start = marqueeStart,
              let end = marqueeEnd else { return }
        
        let screenRect = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
        
        let canvasRect = controller.transform.screenToCanvas(screenRect)
        
        let nodesInRect = nodes.filter { node in
            canvasRect.intersects(node.bounds)
        }
        let nodesInRectIds = Set(nodesInRect.map(\.id))
        
        let newSelection: Set<UUID>
        if additive {
            newSelection = preMarqueeSelection.union(nodesInRectIds)
        } else {
            newSelection = nodesInRectIds
        }
        
        if newSelection != selectionManager.selectedNodes {
            selectionManager.selectNodes(newSelection, additive: false)
        }
    }
    
    private func resetMarquee() {
        marqueeStart = nil
        marqueeEnd = nil
        isMarqueeActive = false
        preMarqueeSelection = []
    }
    
    @ViewBuilder
    private var marqueeSelectionOverlay: some View {
        if isMarqueeActive,
           let start = marqueeStart,
           let end = marqueeEnd {
            let rect = CGRect(
                x: min(start.x, end.x),
                y: min(start.y, end.y),
                width: abs(end.x - start.x),
                height: abs(end.y - start.y)
            )
            
            Rectangle()
                .fill(Color.accentColor.opacity(0.1))
                .overlay(
                    Rectangle()
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                )
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
                .allowsHitTesting(false)
        }
    }
    
    // MARK: - Node Toolbar Overlay
    
    @ViewBuilder
    private var nodeToolbarOverlay: some View {
        if let toolbarBuilder = nodeToolbarContent,
           selectionManager.hasSingleNodeSelected,
           let selectedNodeId = selectionManager.singleSelectedNodeId,
           let selectedNode = nodes.first(where: { $0.id == selectedNodeId }) {
            
            let shouldHide = nodeToolbarConfig.hideOnDrag && controller.isDragging
            let actions = createToolbarActions(for: selectedNode)
            let toolbarNode = createToolbarNode(for: selectedNode)
            let isResizing = resizeManager.isResizing
            
            Group {
                if !shouldHide {
                    NodeToolbarView(
                        node: toolbarNode,
                        panZoomManager: panZoomManager,
                        config: nodeToolbarConfig
                    ) {
                        toolbarBuilder(selectedNode, panZoomManager, actions)
                    }
                    .transition(isResizing ? .identity : .opacity.combined(with: .scale(scale: 0.9)))
                    .transaction { transaction in
                        if isResizing {
                            transaction.disablesAnimations = true
                        }
                    }
                }
            }
            .animation(
                (isResizing || !nodeToolbarConfig.animated) ? .none : .easeInOut(duration: 0.15),
                value: shouldHide
            )
        }
    }
    
    private func createToolbarNode(for node: Node) -> AnyFlowNode {
        let effectiveSize = effectiveNodeSize(for: node)
        let currentPosition = calculateNodePosition(for: node, size: effectiveSize)
        var wrappedNode = AnyFlowNode(node)
        wrappedNode.position = currentPosition
        wrappedNode.width = effectiveSize.width
        wrappedNode.height = effectiveSize.height
        return wrappedNode
    }
    
    private func createToolbarActions(for node: Node) -> NodeToolbarActions {
        NodeToolbarActions(
            delete: { [self] in
                if let index = nodes.firstIndex(where: { $0.id == node.id }) {
                    let deletedNode = nodes[index]

                    // Unregister ports before removing node
                    portPositionRegistry.unregisterNode(nodeId: node.id)

                    nodes.remove(at: index)

                    let deletedEdgeIds = Set(edges.compactMap { edge -> UUID? in
                        (edge.sourceNodeId == node.id || edge.targetNodeId == node.id) ? edge.id : nil
                    })
                    edges.removeAll(where: { edge in
                        edge.sourceNodeId == node.id || edge.targetNodeId == node.id
                    })

                    selectionManager.clearSelection()
                    onNodesDeleted?([deletedNode.id], deletedEdgeIds)
                }
            },
            duplicate: { [self] in
                guard let duplicated = copyPasteManager.duplicate(
                    nodes: nodes,
                    edges: edges,
                    selectedNodeIds: [node.id]
                ) else { return }
                
                nodes.append(contentsOf: duplicated.nodes)
                edges.append(contentsOf: duplicated.edges)
                
                if let newNode = duplicated.nodes.first {
                    selectionManager.selectNode(newNode.id)
                }
            },
            edit: { [self] in
                onNodeEdit?(node)
            },
            copy: { [self] in
                copyPasteManager.copy(
                    nodes: nodes,
                    edges: edges,
                    selectedNodeIds: [node.id]
                )
            },
            cut: { [self] in
                let result = copyPasteManager.cut(
                    nodes: nodes,
                    edges: edges,
                    selectedNodeIds: [node.id]
                )

                // Unregister ports for deleted nodes
                for nodeId in result.nodesToDelete {
                    portPositionRegistry.unregisterNode(nodeId: nodeId)
                }

                nodes.removeAll { result.nodesToDelete.contains($0.id) }
                edges.removeAll { result.edgesToDelete.contains($0.id) }
                selectionManager.clearSelection()
            },
            deselect: { [self] in
                selectionManager.clearSelection()
            }
        )
    }
    
    private var canvasZoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let center = CGPoint(
                    x: viewportSize.width / 2,
                    y: viewportSize.height / 2
                )
                let targetScale = magnificationStartScale * value
                controller.setZoom(targetScale, at: ScreenPoint(center))
            }
            .onEnded { _ in
                magnificationStartScale = controller.transform.scale
            }
    }
    
    private func nodeTapGesture(for node: Node) -> some Gesture {
        TapGesture()
            .onEnded {
                #if os(macOS)
                let additive = NSEvent.modifierFlags.contains(.command)
                #else
                let additive = false
                #endif
                controller.select(node: node.id, additive: additive)
            }
    }
    
    private func nodeDragGesture(for node: Node) -> some Gesture {
        DragGesture(minimumDistance: config.interaction.dragThreshold, coordinateSpace: .named("canvas"))
            .onChanged { value in
                // Don't start drag if resize is in progress
                guard !resizeManager.isResizing else { return }

                if !controller.isDragging {
                    var nodesToDrag = selectionManager.selectedNodes
                    if !nodesToDrag.contains(node.id) {
                        nodesToDrag = [node.id]
                        controller.select(node: node.id)
                    }
                    
                    let positions = Dictionary(
                        uniqueKeysWithValues: nodes.map { ($0.id, $0.position) }
                    )
                    
                    controller.advanced.startDrag(
                        nodeIds: nodesToDrag,
                        positions: positions,
                        at: value.startLocation
                    )

                    if config.autoPan.enabled {
                        startAutoPan()
                    }
                }
                
                currentDragScreenPosition = value.location
                controller.advanced.updateDrag(to: value.location)
            }
            .onEnded { _ in
                stopAutoPan()
                
                if let finalPositions = controller.advanced.endDrag() {
                    for (nodeId, position) in finalPositions {
                        if let index = nodes.firstIndex(where: { $0.id == nodeId }) {
                            let node = nodes[index]
                            nodes[index].position = position
                            onNodeMoved?(node, position)
                        }
                    }
                }
                
                // Clear helper lines when drag ends
                controller.helperLinesManager.clearGuides()
            }
    }
    
    // MARK: - Auto-Pan
    
    private func startAutoPan() {
        stopAutoPan()
        
        autoPanTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [self] _ in
            Task { @MainActor in
                guard controller.isDragging else {
                    stopAutoPan()
                    return
                }
                
                let autoPanDelta = controller.dragManager.calculateAutoPanDelta(
                    screenPosition: currentDragScreenPosition,
                    viewportSize: viewportSize
                )
                
                guard autoPanDelta != .zero else { return }
                
                controller.pan(by: autoPanDelta)
                controller.dragManager.adjustForAutoPan(
                    delta: autoPanDelta,
                    currentScale: controller.transform.scale
                )
            }
        }
    }
    
    private func stopAutoPan() {
        autoPanTimer?.invalidate()
        autoPanTimer = nil
    }
    
    // MARK: - Setup
    
    private func setupManagerCallbacks() {
        resizeObserver.bind(to: resizeManager)

        selectionManager.onSelectionChanged = { nodes, _ in
            onSelectionChanged?(nodes)
        }
        
        connectionManager.onConnectionCreated = { sourceNode, sourcePort, targetNode, targetPort in
            onConnectionCreated?(sourceNode, sourcePort, targetNode, targetPort)
        }
        
        if let dropHandler = onConnectionDroppedOnCanvas {
            connectionManager.enableCanvasDropDetection = true
            connectionManager.onConnectionDroppedOnCanvas = dropHandler
        }
        
        controller.keyboardManager.onAction = { [self] action in
            handleCanvasAction(action)
        }
        
        // Setup helper lines callback
        dragManager.onCalculateHelperLines = { [self] draggedIds, positions, _ in
            // Build node sizes dictionary from current nodes
            var nodeSizes: [UUID: CGSize] = [:]
            for node in nodes {
                nodeSizes[node.id] = CGSize(width: node.width, height: node.height)
            }
            
            let result = controller.helperLinesManager.calculateAlignments(
                draggedNodeIds: draggedIds,
                currentPositions: positions,
                nodeSizes: nodeSizes,
                allNodes: nodes
            )
            return result.snapOffset
        }
        
        // Setup helper lines callback for resize
        resizeManager.onCalculateHelperLines = { [self] nodeId, _, newSize in
            // Build positions and sizes dictionaries
            var currentPositions: [UUID: CGPoint] = [:]
            var nodeSizes: [UUID: CGSize] = [:]

            for node in nodes {
                if node.id == nodeId {
                    // Use the node's current position and new size for the resizing node
                    currentPositions[node.id] = node.position
                    nodeSizes[node.id] = newSize
                } else {
                    currentPositions[node.id] = node.position
                    nodeSizes[node.id] = CGSize(width: node.width, height: node.height)
                }
            }

            let result = controller.helperLinesManager.calculateAlignments(
                draggedNodeIds: [nodeId],
                currentPositions: currentPositions,
                nodeSizes: nodeSizes,
                allNodes: nodes
            )
            return result.snapOffset
        }

        // Clear helper lines when resize ends
        resizeManager.onClearHelperLines = { [self] in
            controller.helperLinesManager.clearGuides()
        }

        // Setup haptic feedback callback
        controller.helperLinesManager.onSnapOccurred = {
            #if os(macOS)
            NSHapticFeedbackManager.defaultPerformer.perform(
                .alignment,
                performanceTime: .default
            )
            #else
            // iOS haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            #endif
        }
    }
    
    // MARK: - Edge Style Helpers
    
    private func getEdgeStrokeColor(for edge: Edge) -> Color {
        if let styledEdge = edge as? any StyledFlowEdge,
           let style = styledEdge.style {
            return style.strokeColor
        }
        return config.defaultEdgeStrokeColor
    }
    
    private func getEdgeSelectedColor(for edge: Edge) -> Color {
        if let styledEdge = edge as? any StyledFlowEdge,
           let style = styledEdge.style,
           let selectedColor = style.selectedColor {
            return selectedColor
        }
        return config.defaultEdgeSelectedColor
    }
    
    private func getEdgeLineWidth(for edge: Edge) -> CGFloat {
        if let styledEdge = edge as? any StyledFlowEdge,
           let style = styledEdge.style {
            return style.lineWidth
        }
        return config.defaultEdgeLineWidth
    }
}

// MARK: - Resize Handle Configuration

public struct ResizeHandleConfig: Equatable {
    public var isVisible: Bool
    public var inset: CGFloat

    public init(isVisible: Bool = true, inset: CGFloat = 6) {
        self.isVisible = isVisible
        self.inset = inset
    }

    public static let `default` = ResizeHandleConfig()
}

// MARK: - Convenience Modifiers

public extension CanvasView {
    func onNodeMoved(_ handler: @escaping (Node, CGPoint) -> Void) -> Self {
        var modified = self
        modified.onNodeMoved = handler
        return modified
    }
    
    func onSelectionChanged(_ handler: @escaping (Set<UUID>) -> Void) -> Self {
        var modified = self
        modified.onSelectionChanged = handler
        return modified
    }
    
    func onConnectionCreated(_ handler: @escaping (UUID, UUID, UUID, UUID) -> Void) -> Self {
        var modified = self
        modified.onConnectionCreated = handler
        return modified
    }
    
    func onNodeResized(_ handler: @escaping (Node, CGSize) -> Void) -> Self {
        var modified = self
        modified.onNodeResized = handler
        return modified
    }
    
    func onNodesDeleted(_ handler: @escaping (Set<UUID>, Set<UUID>) -> Void) -> Self {
        var modified = self
        modified.onNodesDeleted = handler
        return modified
    }
    
    func onNodesPasted(_ handler: @escaping ([Node], [Edge]) -> Void) -> Self {
        var modified = self
        modified.onNodesPasted = handler
        return modified
    }
    
    func onCanvasAction(_ handler: @escaping CanvasActionHandler<Node, Edge>) -> Self {
        var modified = self
        modified.customActionHandler = handler
        return modified
    }
    
    func keyboardConfig(_ config: KeyboardConfig) -> Self {
        var modified = self
        modified.keyboardConfig = config
        return modified
    }
    
    func controls(_ show: Bool) -> Self {
        var modified = self
        modified.showControls = show
        return modified
    }
    
    // MARK: - Node Toolbar API
    
    func nodeToolbar<ToolbarContent: View>(
        config: NodeToolbarConfig = .default,
        @ViewBuilder content: @escaping (Node, PanZoomManager, NodeToolbarActions) -> ToolbarContent
    ) -> Self {
        var modified = self
        modified.nodeToolbarConfig = config
        modified.nodeToolbarContent = { node, manager, actions in
            AnyView(content(node, manager, actions))
        }
        return modified
    }

    // MARK: - Resize Handle API

    func resizeHandle(config: ResizeHandleConfig = .default) -> Self {
        var modified = self
        modified.resizeHandleConfig = config
        return modified
    }

    func resizeOverlay<OverlayContent: View>(
        @ViewBuilder content: @escaping (Node, Bool, ResizeManager) -> OverlayContent
    ) -> Self {
        var modified = self
        modified.resizeOverlayContent = { node, isSelected, manager in
            AnyView(content(node, isSelected, manager))
        }
        return modified
    }
    
    func onNodeEdit(_ handler: @escaping (Node) -> Void) -> Self {
        var modified = self
        modified.onNodeEdit = handler
        return modified
    }
    
    // MARK: - Edge Accessory API
    
    func edgeAccessory<AccessoryContent: View>(
        config: EdgeAccessoryConfig = .default,
        @ViewBuilder content: @escaping (Edge, CGPoint, Bool, DragManager) -> AccessoryContent
    ) -> Self {
        var modified = self
        modified.edgeAccessoryConfig = config
        modified.edgeAccessoryContent = { edge, position, isHovering, dragManager in
            AnyView(content(edge, position, isHovering, dragManager))
        }
        return modified
    }
    
    // MARK: - Canvas Controls API
    
    func canvasControls<ControlsContent: View>(
        position: PanelPosition? = nil,
        @ViewBuilder content: @escaping (PanZoomManager, [Node], AnyView) -> ControlsContent
    ) -> Self {
        var modified = self
        modified.customControlsPosition = position
        modified.customControlsContent = { manager, nodes, defaultView in
            AnyView(content(manager, nodes, defaultView))
        }
        return modified
    }
    
    // MARK: - Canvas MiniMap API
    
    func canvasMiniMap<MiniMapContent: View>(
        position: PanelPosition? = nil,
        @ViewBuilder content: @escaping (
            [Node],
            Set<UUID>,
            PanZoomManager,
            MiniMapController,
            MiniMapConfig,
            AnyView
        ) -> MiniMapContent
    ) -> Self {
        var modified = self
        modified.customMiniMapPosition = position
        modified.customMiniMapContent = { nodes, selected, manager, controller, config, defaultView in
            AnyView(content(nodes, selected, manager, controller, config, defaultView))
        }
        return modified
    }
}

private struct ResizeHandleOverlay: View {
    let nodeId: UUID
    let nodeSize: CGSize
    let isSelected: Bool
    let isResizable: Bool

    @EnvironmentObject var resizeManager: ResizeManager
    @EnvironmentObject var controller: CanvasController

    @State private var isHoveringHandle = false

    private let handleSize: CGFloat = 12
    private let hitAreaPadding: CGFloat = 6

    var body: some View {
        Group {
            if isResizable && isSelected {
                ResizeHandleView(
                    isVisible: true,
                    isActive: isHoveringHandle || resizeManager.isResizing
                )
                .frame(width: handleSize, height: handleSize)
                .padding(hitAreaPadding)
                .contentShape(Rectangle())
                .onHover { hovering in
                    isHoveringHandle = hovering
                }
                .gesture(resizeGesture)
            }
        }
    }

    private var resizeGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                if !resizeManager.isResizing {
                    resizeManager.startResize(
                        nodeId: nodeId,
                        originalSize: nodeSize,
                        at: value.startLocation,
                        anchor: .topLeft
                    )
                }
                resizeManager.updateResize(to: value.location)
            }
            .onEnded { _ in
                if let finalSize = resizeManager.endResize() {
                    controller.resizeNode(id: nodeId, to: finalSize, anchor: .topLeft)
                }
            }
    }
}

private struct ResizeHandleGestureOverlay<Content: View>: View {
    let nodeId: UUID
    let nodeSize: CGSize
    let content: Content

    @EnvironmentObject var resizeManager: ResizeManager
    @EnvironmentObject var controller: CanvasController

    var body: some View {
        content
            .contentShape(Rectangle())
            .gesture(resizeGesture)
    }

    private var resizeGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                if !resizeManager.isResizing {
                    resizeManager.startResize(
                        nodeId: nodeId,
                        originalSize: nodeSize,
                        at: value.startLocation,
                        anchor: .topLeft
                    )
                }
                resizeManager.updateResize(to: value.location)
            }
            .onEnded { _ in
                if let finalSize = resizeManager.endResize() {
                    controller.resizeNode(id: nodeId, to: finalSize, anchor: .topLeft)
                }
            }
    }
}

// MARK: - Public Access to Managers

public extension CanvasView {
    /// Access to the copy/paste manager for custom clipboard operations
    var clipboardManager: CopyPasteManager<Node, Edge> {
        copyPasteManager
    }
    
    /// Programmatically complete a connection
    @discardableResult
    func completeConnection(targetNodeId: UUID, targetPortId: UUID) -> Bool {
        connectionManager.completeConnection(targetNodeId: targetNodeId, targetPortId: targetPortId)
    }
    
    /// Cancel the current connection
    func cancelConnection() {
        connectionManager.cancelConnection()
    }
}

// MARK: - Connection Drop Detection API

public extension CanvasView {
    func onConnectionDroppedOnCanvas(
        _ handler: @escaping (ConnectionDropContext) -> ConnectionDropAction
    ) -> Self {
        var modified = self
        modified.onConnectionDroppedOnCanvas = handler
        return modified
    }

    /// Set a handler to be called whenever the canvas transform changes (pan/zoom)
    /// - Parameter handler: Callback receiving the new transform
    func onTransformChanged(_ handler: @escaping (FlowTransform) -> Void) -> Self {
        var modified = self
        modified.onTransformChanged = handler
        return modified
    }
}

// MARK: - Preview

#Preview("Canvas with Nodes") {
    struct PreviewContainer: View {
        @State var nodes = [
            PreviewNode(position: CGPoint(x: 100, y: 100)),
            PreviewNode(position: CGPoint(x: 300, y: 200)),
            PreviewNode(position: CGPoint(x: 500, y: 150))
        ]
        @State var edges: [PreviewEdge] = []
        
        var body: some View {
            CanvasView(nodes: $nodes, edges: $edges) { node, isSelected in
                DefaultNodeView(node: node, isSelected: isSelected)
            }
            .frame(width: 800, height: 600)
        }
    }
    
    return PreviewContainer()
}

#Preview("Canvas with Edges") {
    struct PreviewContainer: View {
        @State var nodes = [
            PreviewNode(position: CGPoint(x: 100, y: 200)),
            PreviewNode(position: CGPoint(x: 400, y: 200))
        ]
        @State var edges: [PreviewEdge]
        
        init() {
            let node1 = PreviewNode(position: CGPoint(x: 100, y: 200))
            let node2 = PreviewNode(position: CGPoint(x: 400, y: 200))
            _nodes = State(initialValue: [node1, node2])
            _edges = State(initialValue: [
                PreviewEdge(
                    sourceNodeId: node1.id,
                    targetNodeId: node2.id,
                    sourcePortId: node1.outputPorts.first!.id,
                    targetPortId: node2.inputPorts.first!.id
                )
            ])
        }
        
        var body: some View {
            CanvasView(nodes: $nodes, edges: $edges) { node, isSelected in
                DefaultNodeView(node: node, isSelected: isSelected)
            }
            .frame(width: 800, height: 600)
        }
    }
    
    return PreviewContainer()
}
