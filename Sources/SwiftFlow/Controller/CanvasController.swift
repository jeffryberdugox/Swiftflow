//
//  CanvasController.swift
//  SwiftFlow
//
//  Unified controller that orchestrates all canvas interactions.
//  Provides a clean, high-level API for canvas operations.
//

import Foundation
import SwiftUI
import Combine

// MARK: - CanvasController

/// Unified controller that orchestrates all canvas interactions.
/// Provides a high-level command-based API for canvas operations.
///
/// # Usage
/// ```swift
/// // Simple API (90% of users)
/// @StateObject var controller = CanvasController()
///
/// // Perform operations
/// controller.zoomIn()
/// controller.select(node: nodeId)
/// controller.fitView()
///
/// // Command API (for batching/undo)
/// controller.perform(.moveNodes(ids: selectedIds, delta: offset))
///
/// // Transaction API (multiple commands as one undo)
/// controller.transaction("Layout") {
///     .moveNodes(ids: [node1], delta: delta1)
///     .moveNodes(ids: [node2], delta: delta2)
/// }
/// ```
@MainActor
public class CanvasController: ObservableObject {
    
    // MARK: - Published State (UI reads these)
    
    /// Current transform state (offset and scale)
    @Published public private(set) var transform: FlowTransform = .identity
    
    /// Current selection state
    @Published public private(set) var selection: SelectionState = .empty
    
    /// Whether a drag operation is in progress
    @Published public internal(set) var isDragging: Bool = false
    
    /// Whether a connection is being created
    @Published public private(set) var isConnecting: Bool = false
    
    /// Current connection preview state (while creating connection)
    @Published public private(set) var connectionPreview: ConnectionState?
    
    /// Current viewport size
    @Published public private(set) var viewportSize: CGSize = .zero
    
    // MARK: - Configuration
    
    /// Canvas configuration
    public let config: CanvasConfig
    
    // MARK: - Public Managers (for CanvasView integration)
    
    /// Pan and zoom manager
    public lazy var panZoomManager: PanZoomManager = {
        let manager = PanZoomManager(
            minZoom: config.zoom.min,
            maxZoom: config.zoom.max
        )
        setupPanZoomBindings(manager)
        return manager
    }()
    
    /// Drag manager
    public lazy var dragManager: DragManager = {
        DragManager(
            snapToGrid: config.grid.snap,
            gridSize: config.grid.size,
            dragThreshold: config.interaction.dragThreshold,
            autoPanEnabled: config.autoPan.enabled,
            autoPanSpeed: config.autoPan.speed,
            autoPanThreshold: config.autoPan.threshold
        )
    }()
    
    /// Selection manager
    public lazy var selectionManager: SelectionManager = {
        let manager = SelectionManager(enableMultiSelection: config.interaction.permissions.canSelect)
        setupSelectionBindings(manager)
        return manager
    }()
    
    /// Connection manager
    public lazy var connectionManager: ConnectionManager = {
        let manager = ConnectionManager()
        setupConnectionBindings(manager)
        return manager
    }()
    
    /// Edge hover manager
    public let edgeHoverManager = EdgeHoverManager()
    
    /// Port position registry
    public let portPositionRegistry = PortPositionRegistry()
    
    /// Keyboard shortcuts manager
    public lazy var keyboardManager: KeyboardShortcutsManager = {
        KeyboardShortcutsManager(
            selectionManager: selectionManager,
            config: KeyboardConfig()
        )
    }()
    
    /// Helper lines manager
    public lazy var helperLinesManager: HelperLinesManager = {
        HelperLinesManager(config: config.helperLines)
    }()

    /// Resize manager
    public lazy var resizeManager: ResizeManager = {
        ResizeManager(
            resizeThreshold: config.interaction.dragThreshold,
            preserveAspectRatio: config.preserveAspectRatio,
            minNodeSize: CGSize(width: config.minNodeWidth, height: config.minNodeHeight)
        )
    }()

    // Note: Copy/paste is handled by CanvasView's type-specific CopyPasteManager
    
    /// Current drag state (from DragManager)
    public var dragState: DragState? {
        dragManager.dragState
    }
    
    // MARK: - Undo/Redo
    
    /// Undo stack for command history
    public let undoStack: UndoStack
    
    // MARK: - Environment
    
    /// Data environment (set by CanvasView)
    internal var environment: AnyCanvasEnvironment?
    
    // MARK: - Cancellables
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Creates a canvas controller with the specified configuration.
    /// - Parameter config: Canvas configuration. Defaults to `.default`.
    public init(config: CanvasConfig = .default) {
        self.config = config
        self.undoStack = UndoStack(maxHistorySize: config.history.maxUndoCount)
    }
    
    // MARK: - Environment Setup
    
    /// Set the data environment (called by CanvasView).
    internal func setEnvironment(_ environment: AnyCanvasEnvironment) {
        self.environment = environment
    }
    
    /// Update viewport size (called by CanvasView).
    internal func setViewportSize(_ size: CGSize) {
        viewportSize = size
        panZoomManager.viewportSize = size
    }
    
    // MARK: - Command API (Primary Interface)
    
    /// Execute a single command.
    /// - Parameter command: The command to execute
    /// - Returns: Whether the command was executed successfully
    @discardableResult
    public func perform(_ command: CanvasCommand) -> Bool {
        let result = executeCommand(command)
        
        if result.success && command.isUndoable, let name = command.undoName {
            let transaction = CanvasTransaction(
                name: name,
                commands: [command],
                inverseCommands: result.inverseCommand.map { [$0] } ?? []
            )
            undoStack.push(transaction)
        }
        
        return result.success
    }
    
    /// Execute multiple commands as a single transaction.
    /// All commands are undone/redone together.
    /// - Parameters:
    ///   - name: Name for the undo menu
    ///   - commands: Builder that produces the commands
    public func transaction(_ name: String, @TransactionBuilder commands: () -> [CanvasCommand]) {
        let cmds = commands()
        guard !cmds.isEmpty else { return }
        
        var inverseCommands: [CanvasCommand] = []
        
        for cmd in cmds {
            let result = executeCommand(cmd)
            if let inverse = result.inverseCommand {
                inverseCommands.append(inverse)
            }
        }
        
        if cmds.contains(where: { $0.isUndoable }) {
            let transaction = CanvasTransaction(
                name: name,
                commands: cmds,
                inverseCommands: inverseCommands.reversed()
            )
            undoStack.push(transaction)
        }
    }
    
    // MARK: - Convenience Methods (Fluent API)
    
    // MARK: Zoom
    
    /// Zoom in by a standard factor (20%).
    /// - Parameter anchor: Anchor point for zoom. Defaults to viewport center.
    public func zoomIn(at anchor: ScreenPoint = .viewportCenter) {
        perform(.zoomBy(factor: 1.2, anchor: resolveAnchor(anchor)))
    }
    
    /// Zoom out by a standard factor (20%).
    /// - Parameter anchor: Anchor point for zoom. Defaults to viewport center.
    public func zoomOut(at anchor: ScreenPoint = .viewportCenter) {
        perform(.zoomBy(factor: 0.8, anchor: resolveAnchor(anchor)))
    }
    
    /// Zoom to a specific scale.
    /// - Parameters:
    ///   - scale: Target scale (1.0 = 100%)
    ///   - anchor: Anchor point for zoom. Defaults to viewport center.
    public func zoom(to scale: CGFloat, at anchor: ScreenPoint = .viewportCenter) {
        perform(.zoom(to: scale, anchor: resolveAnchor(anchor)))
    }
    
    /// Set zoom to a specific scale at a point (direct, no command).
    /// - Parameters:
    ///   - scale: Target scale
    ///   - point: Anchor point in screen coordinates
    public func setZoom(_ scale: CGFloat, at point: ScreenPoint) {
        panZoomManager.setZoom(scale, at: point.cgPoint)
    }
    
    /// Zoom by a factor at a point (direct, no command).
    /// - Parameters:
    ///   - factor: Zoom factor
    ///   - point: Anchor point in screen coordinates
    public func zoom(by factor: CGFloat, at point: ScreenPoint) {
        panZoomManager.zoom(by: factor, at: point.cgPoint)
    }
    
    // MARK: Pan
    
    /// Pan by a delta.
    /// - Parameter delta: Pan delta in screen coordinates
    public func pan(by delta: CGSize) {
        perform(.pan(by: delta))
    }
    
    /// Pan to center a canvas point in the viewport.
    /// - Parameter point: Canvas point to center
    public func panToCenter(_ point: CanvasPoint) {
        perform(.panToCenter(point))
    }
    
    // MARK: Fit
    
    /// Fit all nodes in the viewport.
    /// - Parameter padding: Padding around nodes. Defaults to 50.
    public func fitView(padding: CGFloat = 50) {
        perform(.fitView(padding: padding))
    }
    
    /// Fit specific nodes in the viewport.
    /// - Parameters:
    ///   - ids: IDs of nodes to fit
    ///   - padding: Padding around nodes. Defaults to 50.
    public func fitNodes(_ ids: Set<UUID>, padding: CGFloat = 50) {
        perform(.fitNodes(ids: ids, padding: padding))
    }
    
    /// Reset to identity transform.
    public func resetView() {
        perform(.resetView)
    }
    
    // MARK: - Data Access
    
    /// Get all current nodes from the canvas.
    /// - Returns: Array of current nodes (read-only snapshot)
    public func getNodes() -> [AnyFlowNode] {
        return environment?.getNodes() ?? []
    }
    
    /// Get all current edges from the canvas.
    /// - Returns: Array of current edges (read-only snapshot)
    public func getEdges() -> [any FlowEdge] {
        return environment?.getEdges() ?? []
    }
    
    /// Get all elements (nodes + edges) from the canvas.
    /// - Returns: Tuple containing nodes and edges arrays
    public func getElements() -> (nodes: [AnyFlowNode], edges: [any FlowEdge]) {
        return (getNodes(), getEdges())
    }
    
    /// Get a specific node by ID.
    /// - Parameter id: The node ID to find
    /// - Returns: The node if found, nil otherwise
    public func getNode(id: UUID) -> AnyFlowNode? {
        return getNodes().first { $0.id == id }
    }
    
    /// Get a specific edge by ID.
    /// - Parameter id: The edge ID to find
    /// - Returns: The edge if found, nil otherwise
    public func getEdge(id: UUID) -> (any FlowEdge)? {
        return getEdges().first { $0.id == id }
    }
    
    /// Export the complete canvas state to a dictionary.
    /// Includes nodes, edges, viewport transform, and selection.
    /// - Returns: Dictionary containing serializable canvas state
    public func toObject() -> [String: Any] {
        return [
            "viewport": [
                "x": transform.offset.x,
                "y": transform.offset.y,
                "zoom": transform.scale
            ],
            "selection": [
                "nodes": Array(selection.selectedNodes),
                "edges": Array(selection.selectedEdges)
            ],
            "nodeCount": getNodes().count,
            "edgeCount": getEdges().count
        ]
    }
    
    // MARK: - Coordinate Conversion
    
    /// Convert screen coordinates to canvas coordinates.
    /// Useful when dragging nodes from outside the canvas.
    /// - Parameter point: Point in screen/viewport coordinates
    /// - Returns: Point in canvas coordinates
    public func project(_ point: CGPoint) -> CGPoint {
        return transform.screenToCanvas(point)
    }
    
    /// Convert screen point to canvas point (type-safe version).
    /// - Parameter point: Screen point
    /// - Returns: Canvas point
    public func project(_ point: ScreenPoint) -> CanvasPoint {
        return transform.toCanvas(point)
    }
    
    /// Convert canvas coordinates to screen coordinates.
    /// - Parameter point: Point in canvas coordinates
    /// - Returns: Point in screen/viewport coordinates
    public func unproject(_ point: CGPoint) -> CGPoint {
        return transform.canvasToScreen(point)
    }
    
    /// Convert canvas point to screen point (type-safe version).
    /// - Parameter point: Canvas point
    /// - Returns: Screen point
    public func unproject(_ point: CanvasPoint) -> ScreenPoint {
        return transform.toScreen(point)
    }
    
    // MARK: Selection
    
    /// Select a single node.
    /// - Parameters:
    ///   - id: Node ID to select
    ///   - additive: Add to current selection if true
    public func select(node id: UUID, additive: Bool = false) {
        perform(.select(nodeIds: [id], edgeIds: [], additive: additive))
    }
    
    /// Select multiple nodes.
    /// - Parameters:
    ///   - ids: Node IDs to select
    ///   - additive: Add to current selection if true
    public func select(nodes ids: Set<UUID>, additive: Bool = false) {
        perform(.select(nodeIds: ids, edgeIds: [], additive: additive))
    }
    
    /// Select a single edge.
    /// - Parameters:
    ///   - id: Edge ID to select
    ///   - additive: Add to current selection if true
    public func select(edge id: UUID, additive: Bool = false) {
        perform(.select(nodeIds: [], edgeIds: [id], additive: additive))
    }
    
    /// Select all nodes.
    public func selectAll() {
        perform(.selectAll)
    }
    
    /// Clear all selection.
    public func clearSelection() {
        perform(.clearSelection)
    }
    
    // MARK: Delete
    
    /// Delete the current selection.
    public func deleteSelection() {
        perform(.deleteSelection)
    }
    
    /// Delete specific nodes.
    /// - Parameter ids: Node IDs to delete
    public func deleteNodes(_ ids: Set<UUID>) {
        perform(.deleteNodes(ids: ids))
    }
    
    /// Delete specific edges.
    /// - Parameter ids: Edge IDs to delete
    public func deleteEdges(_ ids: Set<UUID>) {
        perform(.deleteEdges(ids: ids))
    }

    // MARK: Resize

    /// Resize a node to a specific width while preserving aspect ratio.
    /// - Parameters:
    ///   - nodeId: ID of the node to resize
    ///   - newWidth: New width for the node
    ///   - anchor: Anchor point that stays fixed (default: .topLeft for bottom-right resize)
    /// - Returns: True if the command succeeded
    @discardableResult
    public func resizeNode(id nodeId: UUID, toWidth newWidth: CGFloat, anchor: ResizeAnchor = .topLeft) -> Bool {
        perform(.resizeNodeToWidth(id: nodeId, newWidth: newWidth, anchor: anchor))
    }

    /// Resize a node by a scale factor (uniform scaling).
    /// - Parameters:
    ///   - nodeId: ID of the node to resize
    ///   - scaleFactor: Scale factor to apply (1.0 = no change, 2.0 = double size)
    ///   - anchor: Anchor point that stays fixed (default: .topLeft for bottom-right resize)
    /// - Returns: True if the command succeeded
    @discardableResult
    public func resizeNode(id nodeId: UUID, byScale scaleFactor: CGFloat, anchor: ResizeAnchor = .topLeft) -> Bool {
        perform(.resizeNodeByScale(id: nodeId, scaleFactor: scaleFactor, anchor: anchor))
    }

    /// Resize a node to a specific size.
    /// - Parameters:
    ///   - nodeId: ID of the node to resize
    ///   - newSize: New size for the node
    ///   - anchor: Anchor point that stays fixed (default: .topLeft for bottom-right resize)
    /// - Returns: True if the command succeeded
    @discardableResult
    public func resizeNode(id nodeId: UUID, to newSize: CGSize, anchor: ResizeAnchor = .topLeft) -> Bool {
        perform(.resizeNode(id: nodeId, newSize: newSize, anchor: anchor))
    }

    /// Resize all selected nodes by a scale factor.
    /// - Parameter scaleFactor: Scale factor to apply to all selected nodes
    /// - Returns: Array of results for each resize operation
    @discardableResult
    public func resizeSelection(byScale scaleFactor: CGFloat) -> [Bool] {
        let selectedNodeIds = Array(selection.selectedNodes)
        return selectedNodeIds.map { nodeId in
            resizeNode(id: nodeId, byScale: scaleFactor, anchor: .topLeft)
        }
    }

    // MARK: Undo/Redo
    
    /// Whether there are actions to undo.
    public var canUndo: Bool {
        undoStack.canUndo
    }
    
    /// Whether there are actions to redo.
    public var canRedo: Bool {
        undoStack.canRedo
    }
    
    /// Name of the action that would be undone.
    public var undoName: String? {
        undoStack.undoName
    }
    
    /// Name of the action that would be redone.
    public var redoName: String? {
        undoStack.redoName
    }
    
    /// Undo the last action.
    public func undo() {
        guard let transaction = undoStack.popUndo() else { return }
        
        // Execute inverse commands
        for command in transaction.inverseCommands {
            _ = executeCommand(command)
        }
    }
    
    /// Redo the last undone action.
    public func redo() {
        guard let transaction = undoStack.popRedo() else { return }
        
        // Re-execute original commands
        for command in transaction.commands {
            _ = executeCommand(command)
        }
    }
    
    // MARK: - Advanced Access
    
    /// Provides direct access to internal managers for power users.
    public var advanced: AdvancedAccess {
        AdvancedAccess(controller: self)
    }
    
    // MARK: - Private Helpers
    
    private func resolveAnchor(_ anchor: ScreenPoint) -> ScreenPoint {
        guard !anchor.isViewportCenter else {
            return ScreenPoint(
                x: viewportSize.width / 2,
                y: viewportSize.height / 2
            )
        }
        return anchor
    }
    
    private func setupPanZoomBindings(_ manager: PanZoomManager) {
        manager.$transform
            .sink { [weak self] newTransform in
                self?.transform = newTransform
            }
            .store(in: &cancellables)
    }
    
    private func setupSelectionBindings(_ manager: SelectionManager) {
        manager.$selectedNodes
            .combineLatest(manager.$selectedEdges)
            .sink { [weak self] nodes, edges in
                self?.selection = SelectionState(selectedNodes: nodes, selectedEdges: edges)
            }
            .store(in: &cancellables)
    }
    
    private func setupConnectionBindings(_ manager: ConnectionManager) {
        manager.$connectionInProgress
            .sink { [weak self] connection in
                self?.connectionPreview = connection
                self?.isConnecting = connection != nil
            }
            .store(in: &cancellables)
    }

    // MARK: - Resize Helpers

    /// Calculate new position when resizing with an anchor point.
    /// The anchor determines which point of the node remains fixed during resize.
    /// - Parameters:
    ///   - currentPosition: Current top-left position of the node
    ///   - oldSize: Original size before resize
    ///   - newSize: New size after resize
    ///   - anchor: Anchor point that stays fixed
    /// - Returns: New top-left position
    private func calculatePositionForResize(
        currentPosition: CGPoint,
        oldSize: CGSize,
        newSize: CGSize,
        anchor: ResizeAnchor
    ) -> CGPoint {
        let deltaWidth = newSize.width - oldSize.width
        let deltaHeight = newSize.height - oldSize.height

        switch anchor {
        case .topLeft:
            // Top-left stays fixed (bottom-right resize)
            return currentPosition

        case .topRight:
            // Top-right stays fixed (bottom-left resize)
            return CGPoint(
                x: currentPosition.x - deltaWidth,
                y: currentPosition.y
            )

        case .bottomLeft:
            // Bottom-left stays fixed (top-right resize)
            return CGPoint(
                x: currentPosition.x,
                y: currentPosition.y - deltaHeight
            )

        case .bottomRight:
            // Bottom-right stays fixed (top-left resize)
            return CGPoint(
                x: currentPosition.x - deltaWidth,
                y: currentPosition.y - deltaHeight
            )

        case .top:
            // Top edge center stays fixed
            return CGPoint(
                x: currentPosition.x - deltaWidth / 2,
                y: currentPosition.y
            )

        case .bottom:
            // Bottom edge center stays fixed
            return CGPoint(
                x: currentPosition.x - deltaWidth / 2,
                y: currentPosition.y - deltaHeight
            )

        case .left:
            // Left edge center stays fixed
            return CGPoint(
                x: currentPosition.x,
                y: currentPosition.y - deltaHeight / 2
            )

        case .right:
            // Right edge center stays fixed
            return CGPoint(
                x: currentPosition.x - deltaWidth,
                y: currentPosition.y - deltaHeight / 2
            )

        case .center:
            // Center stays fixed (resize equally in all directions)
            return CGPoint(
                x: currentPosition.x - deltaWidth / 2,
                y: currentPosition.y - deltaHeight / 2
            )
        }
    }

    // MARK: - Command Execution

    private func executeCommand(_ command: CanvasCommand) -> CommandResult {
        switch command {
        // Viewport commands
        case .setTransform(let newTransform):
            panZoomManager.transform = newTransform
            return .succeeded()
            
        case .zoom(let scale, let anchor):
            panZoomManager.setZoom(scale, at: anchor.cgPoint)
            return .succeeded()
            
        case .zoomBy(let factor, let anchor):
            panZoomManager.zoom(by: factor, at: anchor.cgPoint)
            return .succeeded()
            
        case .pan(let delta):
            panZoomManager.pan(by: delta)
            return .succeeded()
            
        case .panToCenter(let point):
            // Calculate offset to center the point
            let screenPoint = transform.canvasToScreen(point.cgPoint)
            let center = CGPoint(x: viewportSize.width / 2, y: viewportSize.height / 2)
            let delta = CGSize(
                width: center.x - screenPoint.x,
                height: center.y - screenPoint.y
            )
            panZoomManager.pan(by: delta)
            return .succeeded()
            
        case .fitView(let padding):
            guard let nodes = environment?.getNodes() else {
                return .failed("No environment set")
            }
            panZoomManager.fitNodes(nodes, padding: padding)
            return .succeeded()
            
        case .fitNodes(let ids, let padding):
            guard let allNodes = environment?.getNodes() else {
                return .failed("No environment set")
            }
            let nodesToFit = allNodes.filter { ids.contains($0.id) }
            panZoomManager.fitNodes(nodesToFit, padding: padding)
            return .succeeded()
            
        case .resetView:
            panZoomManager.reset()
            return .succeeded()
            
        // Selection commands
        case .select(let nodeIds, let edgeIds, let additive):
            if !additive {
                selectionManager.clearSelection()
            }
            selectionManager.selectNodes(nodeIds, additive: additive)
            for edgeId in edgeIds {
                selectionManager.selectEdge(edgeId, additive: true)
            }
            return .succeeded()
            
        case .selectAll:
            guard let nodes = environment?.getNodes() else {
                return .failed("No environment set")
            }
            let allIds = Set(nodes.map { $0.id })
            selectionManager.selectNodes(allIds, additive: false)
            return .succeeded()
            
        case .clearSelection:
            selectionManager.clearSelection()
            return .succeeded()
            
        case .toggleNodeSelection(let id):
            selectionManager.toggleNodeSelection(id)
            return .succeeded()
            
        case .toggleEdgeSelection(let id):
            if selectionManager.isEdgeSelected(id) {
                selectionManager.clearEdgeSelection()
            } else {
                selectionManager.selectEdge(id, additive: false)
            }
            return .succeeded()
            
        // Node commands
        case .moveNodes(let ids, let delta):
            var edits: [NodeEdit] = []
            guard let nodes = environment?.getNodes() else {
                return .failed("No environment set")
            }
            
            for id in ids {
                if let node = nodes.first(where: { $0.id == id }) {
                    let newPosition = CGPoint(
                        x: node.position.x + delta.width,
                        y: node.position.y + delta.height
                    )
                    edits.append(.move(id: id, to: newPosition))
                }
            }
            
            environment?.applyNodeEdits(edits)
            
            // Create inverse command
            let inverseDelta = CGSize(width: -delta.width, height: -delta.height)
            return .succeeded(
                affectedNodeIds: ids,
                inverseCommand: .moveNodes(ids: ids, delta: inverseDelta)
            )
            
        case .moveNodeTo(let id, let position):
            guard let nodes = environment?.getNodes(),
                  let node = nodes.first(where: { $0.id == id }) else {
                return .failed("Node not found")
            }
            
            let oldPosition = CanvasPoint(node.position)
            environment?.applyNodeEdits([.move(id: id, to: position.cgPoint)])
            
            return .succeeded(
                affectedNodeIds: [id],
                inverseCommand: .moveNodeTo(id: id, position: oldPosition)
            )
            
        case .resizeNode(let id, let newSize, let anchor):
            guard let nodes = environment?.getNodes(),
                  let node = nodes.first(where: { $0.id == id }) else {
                return .failed("Node not found")
            }

            // Apply minimum size constraints
            let constrainedSize = CGSize(
                width: max(newSize.width, config.minNodeWidth),
                height: max(newSize.height, config.minNodeHeight)
            )

            let oldSize = CGSize(width: node.width, height: node.height)
            let oldPosition = node.position

            // Calculate new position based on anchor
            let newPosition = calculatePositionForResize(
                currentPosition: oldPosition,
                oldSize: oldSize,
                newSize: constrainedSize,
                anchor: anchor
            )

            // Apply edits: resize and optional position move
            var edits: [NodeEdit] = [.resize(id: id, size: constrainedSize)]
            if newPosition != oldPosition {
                edits.append(.move(id: id, to: newPosition))
            }
            environment?.applyNodeEdits(edits)

            // CRITICAL: Update port positions after resize
            portPositionRegistry.updatePortsForResize(nodeId: id, newSize: constrainedSize)

            // Create inverse commands
            var inverseCommands: [CanvasCommand] = [.resizeNode(id: id, newSize: oldSize, anchor: anchor)]
            if newPosition != oldPosition {
                inverseCommands.append(.moveNodeTo(id: id, position: CanvasPoint(oldPosition)))
            }

            // For now, return single inverse (position will be recalculated on undo)
            return .succeeded(
                affectedNodeIds: [id],
                inverseCommand: inverseCommands.first
            )

        case .resizeNodeByScale(let id, let scaleFactor, let anchor):
            guard let nodes = environment?.getNodes(),
                  let node = nodes.first(where: { $0.id == id }) else {
                return .failed("Node not found")
            }

            let oldSize = CGSize(width: node.width, height: node.height)
            let newSize = CGSize(
                width: oldSize.width * scaleFactor,
                height: oldSize.height * scaleFactor
            )

            // Delegate to resizeNode command
            return executeCommand(.resizeNode(id: id, newSize: newSize, anchor: anchor))

        case .resizeNodeToWidth(let id, let newWidth, let anchor):
            guard let nodes = environment?.getNodes(),
                  let node = nodes.first(where: { $0.id == id }) else {
                return .failed("Node not found")
            }

            let oldSize = CGSize(width: node.width, height: node.height)
            let scaleFactor = newWidth / oldSize.width
            let newSize = CGSize(
                width: newWidth,
                height: oldSize.height * scaleFactor
            )

            // Delegate to resizeNode command
            return executeCommand(.resizeNode(id: id, newSize: newSize, anchor: anchor))

        case .deleteNodes(let ids):
            // Also delete connected edges
            guard let edges = environment?.getEdges() else {
                return .failed("No environment set")
            }
            
            let connectedEdgeIds = Set(edges.filter { edge in
                ids.contains(edge.sourceNodeId) || ids.contains(edge.targetNodeId)
            }.map { $0.id })
            
            var nodeEdits: [NodeEdit] = []
            var edgeEdits: [EdgeEdit] = []
            
            for id in ids {
                nodeEdits.append(.delete(id: id))
            }
            for edgeId in connectedEdgeIds {
                edgeEdits.append(.delete(id: edgeId))
            }
            
            environment?.applyNodeEdits(nodeEdits)
            environment?.applyEdgeEdits(edgeEdits)
            
            selectionManager.clearSelection()
            
            // Note: For full undo support, we'd need to store the deleted nodes/edges
            return .succeeded(
                affectedNodeIds: ids,
                affectedEdgeIds: connectedEdgeIds
            )
            
        case .setNodeParent(let id, let parentId):
            environment?.applyNodeEdits([.setParent(id: id, parentId: parentId)])
            return .succeeded(affectedNodeIds: [id])
            
        case .setNodeZIndex(let id, let zIndex):
            environment?.applyNodeEdits([.setZIndex(id: id, zIndex: zIndex)])
            return .succeeded(affectedNodeIds: [id])
            
        case .bringToFront(let ids):
            guard let nodes = environment?.getNodes() else {
                return .failed("No environment set")
            }
            let maxZ = nodes.map { $0.zIndex }.max() ?? 0
            var edits: [NodeEdit] = []
            for (index, id) in ids.enumerated() {
                edits.append(.setZIndex(id: id, zIndex: maxZ + Double(index) + 1))
            }
            environment?.applyNodeEdits(edits)
            return .succeeded(affectedNodeIds: ids)
            
        case .sendToBack(let ids):
            guard let nodes = environment?.getNodes() else {
                return .failed("No environment set")
            }
            let minZ = nodes.map { $0.zIndex }.min() ?? 0
            var edits: [NodeEdit] = []
            for (index, id) in ids.enumerated() {
                edits.append(.setZIndex(id: id, zIndex: minZ - Double(ids.count - index)))
            }
            environment?.applyNodeEdits(edits)
            return .succeeded(affectedNodeIds: ids)
            
        // Edge commands
        case .createEdge(let sourceNode, let sourcePort, let targetNode, let targetPort):
            let edgeId = UUID()
            environment?.applyEdgeEdits([
                .create(id: edgeId, sourceNode: sourceNode, sourcePort: sourcePort,
                       targetNode: targetNode, targetPort: targetPort)
            ])
            return .succeeded(
                affectedEdgeIds: [edgeId],
                inverseCommand: .deleteEdges(ids: [edgeId])
            )
            
        case .deleteEdges(let ids):
            var edits: [EdgeEdit] = []
            for id in ids {
                edits.append(.delete(id: id))
            }
            environment?.applyEdgeEdits(edits)
            return .succeeded(affectedEdgeIds: ids)
            
        // Compound commands
        case .deleteSelection:
            let nodeIds = selectionManager.selectedNodes
            let edgeIds = selectionManager.selectedEdges
            
            if !nodeIds.isEmpty {
                _ = executeCommand(.deleteNodes(ids: nodeIds))
            }
            if !edgeIds.isEmpty {
                _ = executeCommand(.deleteEdges(ids: edgeIds))
            }
            return .succeeded(affectedNodeIds: nodeIds, affectedEdgeIds: edgeIds)
            
        case .duplicate, .copy, .cut, .paste:
            // These require more complex implementation with clipboard
            return .noOp
        }
    }
}

// MARK: - SelectionState Extension (convenience for controller)

public extension SelectionState {
    /// Empty selection state
    static var empty: SelectionState {
        SelectionState(selectedNodes: [], selectedEdges: [])
    }
    
    /// Whether exactly one node is selected (and no edges)
    var hasSingleNodeSelected: Bool {
        selectedNodes.count == 1 && selectedEdges.isEmpty
    }
    
    /// The single selected node ID, if applicable
    var singleSelectedNodeId: UUID? {
        hasSingleNodeSelected ? selectedNodes.first : nil
    }
    
    /// Total count of selected items (alias for selectionCount)
    var count: Int {
        selectionCount
    }
}
