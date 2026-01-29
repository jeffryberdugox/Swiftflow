//
//  AdvancedAccess.swift
//  SwiftFlow
//
//  Provides direct access to internal managers for power users.
//  Use with caution - prefer the high-level CanvasController API when possible.
//

import Foundation

// MARK: - AdvancedAccess

/// Provides direct access to internal managers for power users.
/// Use with caution - modifying managers directly may bypass undo/redo.
///
/// # Usage
/// ```swift
/// // Access via controller
/// let panZoom = controller.advanced.panZoom
/// let selection = controller.advanced.selection
///
/// // Direct manager operations (bypasses undo)
/// controller.advanced.panZoom.zoomIn()
///
/// // Invalidate caches after external data changes
/// controller.advanced.invalidateCaches()
/// ```
///
/// # Warning
/// Direct modifications to managers bypass the command/transaction system
/// and won't be recorded for undo/redo. Use the high-level API when possible.
@MainActor
public struct AdvancedAccess {
    
    private let controller: CanvasController
    
    internal init(controller: CanvasController) {
        self.controller = controller
    }
    
    // MARK: - Manager Access
    
    /// Direct access to the pan/zoom manager.
    /// Modifications bypass undo/redo.
    public var panZoom: PanZoomManager {
        controller.panZoomManager
    }
    
    /// Direct access to the drag manager.
    /// Modifications bypass undo/redo.
    public var drag: DragManager {
        controller.dragManager
    }
    
    /// Direct access to the selection manager.
    /// Modifications bypass undo/redo.
    public var selection: SelectionManager {
        controller.selectionManager
    }
    
    /// Direct access to the connection manager.
    /// Modifications bypass undo/redo.
    public var connection: ConnectionManager {
        controller.connectionManager
    }
    
    /// Direct access to the edge hover manager.
    public var edgeHover: EdgeHoverManager {
        controller.edgeHoverManager
    }
    
    /// Direct access to the port position registry.
    public var portRegistry: PortPositionRegistry {
        controller.portPositionRegistry
    }
    
    /// Direct access to the undo stack.
    public var undoStack: UndoStack {
        controller.undoStack
    }

    /// Direct access to the resize manager.
    public var resize: ResizeManager {
        controller.resizeManager
    }

    // MARK: - Cache Management
    
    /// Invalidate all caches.
    /// Call this after external data changes that the controller didn't track.
    public func invalidateCaches() {
        // Port positions are automatically updated via registry
        // Add cache invalidation here when caches are implemented
    }
    
    /// Invalidate caches for specific nodes.
    /// - Parameter nodeIds: IDs of nodes whose caches should be invalidated
    public func invalidateCaches(for nodeIds: Set<UUID>) {
        // Add specific cache invalidation here
    }
    
    // MARK: - State Management
    
    /// Force update the viewport size.
    /// Normally called automatically by CanvasView.
    public func setViewportSize(_ size: CGSize) {
        controller.setViewportSize(size)
    }
    
    /// Set the data environment directly.
    /// Normally called automatically by CanvasView.
    public func setEnvironment(_ environment: AnyCanvasEnvironment) {
        controller.setEnvironment(environment)
    }
    
    // MARK: - Drag Operations
    
    /// Start a drag operation programmatically.
    /// - Parameters:
    ///   - nodeIds: IDs of nodes to drag
    ///   - positions: Current positions of nodes
    ///   - startPoint: Starting point in canvas coordinates
    public func startDrag(
        nodeIds: Set<UUID>,
        positions: [UUID: CGPoint],
        at startPoint: CGPoint
    ) {
        controller.dragManager.startDrag(nodeIds: nodeIds, positions: positions, at: startPoint)
        controller.isDragging = true
    }
    
    /// Update an ongoing drag operation.
    /// - Parameter point: Current point in canvas coordinates
    public func updateDrag(to point: CGPoint) {
        controller.dragManager.updateDrag(to: point)
    }
    
    /// End the current drag operation.
    /// - Returns: Final positions of dragged nodes, or nil if cancelled
    @discardableResult
    public func endDrag() -> [UUID: CGPoint]? {
        let result = controller.dragManager.endDrag()
        controller.isDragging = false
        return result
    }
    
    /// Cancel the current drag operation.
    public func cancelDrag() {
        controller.dragManager.cancelDrag()
        controller.isDragging = false
    }
    
    // MARK: - Connection Operations
    
    /// Start a connection operation programmatically.
    public func startConnection(
        from nodeId: UUID,
        portId: UUID,
        at position: CGPoint,
        portPosition: PortPosition,
        isFromInput: Bool = false
    ) {
        controller.connectionManager.startConnection(
            from: nodeId,
            portId: portId,
            at: position,
            portPosition: portPosition,
            isFromInput: isFromInput
        )
    }
    
    /// Update an ongoing connection.
    public func updateConnection(
        to position: CGPoint,
        nearbyPort: (nodeId: UUID, portId: UUID, position: CGPoint, portPosition: PortPosition)? = nil
    ) {
        controller.connectionManager.updateConnection(to: position, nearbyPort: nearbyPort)
    }
    
    /// End the connection attempt.
    /// - Returns: True if a valid connection was created
    @discardableResult
    public func endConnection() -> Bool {
        controller.connectionManager.endConnection()
    }
    
    /// Cancel the current connection.
    public func cancelConnection() {
        controller.connectionManager.cancelConnection()
    }
    
    // MARK: - Coordinate Conversion
    
    /// Convert a screen point to canvas coordinates.
    public func screenToCanvas(_ point: CGPoint) -> CGPoint {
        controller.transform.screenToCanvas(point)
    }
    
    /// Convert a canvas point to screen coordinates.
    public func canvasToScreen(_ point: CGPoint) -> CGPoint {
        controller.transform.canvasToScreen(point)
    }
    
    /// Convert a screen point to canvas point (type-safe).
    public func toCanvas(_ point: ScreenPoint) -> CanvasPoint {
        controller.transform.toCanvas(point)
    }
    
    /// Convert a canvas point to screen point (type-safe).
    public func toScreen(_ point: CanvasPoint) -> ScreenPoint {
        controller.transform.toScreen(point)
    }
}
