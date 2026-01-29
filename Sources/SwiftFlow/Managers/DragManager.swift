//
//  DragManager.swift
//  SwiftFlow
//
//  Manages node dragging operations with multi-selection and snap-to-grid support.
//

import Foundation
import SwiftUI
import Combine

/// Manages node dragging operations
@MainActor
public class DragManager: ObservableObject {
    // MARK: - Published Properties
    
    /// Current drag state (nil if not dragging)
    @Published public private(set) var dragState: DragState?
    
    // MARK: - Configuration
    
    /// Whether to snap positions to grid
    public var snapToGrid: Bool
    
    /// Grid size for snapping
    public var gridSize: CGFloat
    
    /// Minimum distance before drag starts
    public var dragThreshold: CGFloat
    
    /// Whether auto-pan is enabled when dragging near edges
    public var autoPanEnabled: Bool
    
    /// Speed of auto-pan
    public var autoPanSpeed: CGFloat
    
    /// Distance from edge to trigger auto-pan
    public var autoPanThreshold: CGFloat
    
    // MARK: - Internal State
    
    private var snapGrid: SnapGrid
    
    // MARK: - Callbacks
    
    /// Called when drag starts
    public var onDragStarted: ((Set<UUID>) -> Void)?
    
    /// Called during drag with new positions
    public var onDragChanged: (([UUID: CGPoint]) -> Void)?
    
    /// Called when drag ends with final positions
    public var onDragEnded: (([UUID: CGPoint]) -> Void)?
    
    /// Called to calculate helper lines during drag
    /// Returns snap offset from helper lines (if any)
    public var onCalculateHelperLines: ((Set<UUID>, [UUID: CGPoint], [UUID: CGSize]) -> CGSize)?
    
    // MARK: - Initialization
    
    public init(
        snapToGrid: Bool = false,
        gridSize: CGFloat = 20,
        dragThreshold: CGFloat = 3.0,
        autoPanEnabled: Bool = true,
        autoPanSpeed: CGFloat = 15,
        autoPanThreshold: CGFloat = 40
    ) {
        self.snapToGrid = snapToGrid
        self.gridSize = gridSize
        self.dragThreshold = dragThreshold
        self.autoPanEnabled = autoPanEnabled
        self.autoPanSpeed = autoPanSpeed
        self.autoPanThreshold = autoPanThreshold
        self.snapGrid = SnapGrid(size: gridSize)
    }
    
    // MARK: - Drag Operations
    
    /// Start a drag operation
    /// - Parameters:
    ///   - nodeIds: IDs of nodes to drag
    ///   - positions: Current positions (top-left) of the nodes in canvas coordinates
    ///   - point: Starting point in canvas coordinates (from drag gesture with .named("canvas") coordinate space)
    public func startDrag(
        nodeIds: Set<UUID>,
        positions: [UUID: CGPoint],
        at point: CGPoint
    ) {
        // Store starting positions for all nodes
        var startPositions: [UUID: CGPoint] = [:]
        var distances: [UUID: CGSize] = [:]
        
        for nodeId in nodeIds {
            if let nodeTopLeft = positions[nodeId] {
                startPositions[nodeId] = nodeTopLeft
                
                // COORDINATE FIX: Calculate offset from cursor to node's top-left
                // This maintains the grab point relative to the node's top-left corner
                // nodeTopLeft - cursor gives us the vector from cursor to top-left
                distances[nodeId] = CGSize(
                    width: nodeTopLeft.x - point.x,
                    height: nodeTopLeft.y - point.y
                )
            }
        }
        
        dragState = DragState(
            draggedNodes: nodeIds,
            startPositions: startPositions,
            distances: distances,
            currentOffset: .zero,
            hasMoved: false,
            startPoint: point
        )
        
        onDragStarted?(nodeIds)
    }
    
    /// Start a drag operation with type-safe canvas point
    /// - Parameters:
    ///   - nodeIds: IDs of nodes to drag
    ///   - positions: Current positions (top-left) of the nodes in canvas coordinates
    ///   - point: Starting point in canvas coordinates (type-safe)
    public func startDrag(
        nodeIds: Set<UUID>,
        positions: [UUID: CanvasPoint],
        at point: CanvasPoint
    ) {
        let cgPositions = positions.mapValues { $0.cgPoint }
        startDrag(nodeIds: nodeIds, positions: cgPositions, at: point.cgPoint)
    }
    
    /// Update the drag with a new position
    /// - Parameter point: Current drag point in canvas coordinates (from drag gesture with .named("canvas") coordinate space)
    public func updateDrag(to point: CGPoint) {
        guard var state = dragState else { return }
        
        // Calculate offset from start
        let rawOffset = CGSize(
            width: point.x - state.startPoint.x,
            height: point.y - state.startPoint.y
        )
        
        // Check if we've moved beyond threshold
        if !state.hasMoved {
            let distance = sqrt(rawOffset.width * rawOffset.width + rawOffset.height * rawOffset.height)
            if distance < dragThreshold {
                return
            }
            state.hasMoved = true
        }
        
        // Apply snap to grid if enabled
        let finalOffset: CGSize
        if snapToGrid {
            // Use distances for accurate snap calculation
            let currentMousePos = CGPoint(
                x: state.startPoint.x + rawOffset.width,
                y: state.startPoint.y + rawOffset.height
            )
            
            finalOffset = snapGrid.calculateMultiNodeSnapOffset(
                startPositions: state.startPositions,
                distances: state.distances,
                currentMousePos: currentMousePos
            )
        } else if let helperLinesCallback = onCalculateHelperLines {
            // Apply helper lines snap if callback is set and grid snap is not active
            // First calculate tentative positions with raw offset
            state.currentOffset = rawOffset
            let tentativePositions = state.allNewPositions()
            
            // Get node sizes from start positions (assuming sizes don't change during drag)
            var nodeSizes: [UUID: CGSize] = [:]
            for nodeId in state.draggedNodes {
                if state.startPositions[nodeId] != nil,
                   state.distances[nodeId] != nil {
                    // Infer size from bounds (this is approximate, actual sizes should be passed from CanvasView)
                    nodeSizes[nodeId] = CGSize(width: 100, height: 100) // Default placeholder
                }
            }
            
            // Calculate helper lines snap offset
            let helperLinesOffset = helperLinesCallback(state.draggedNodes, tentativePositions, nodeSizes)
            
            // Apply helper lines offset on top of raw offset
            finalOffset = CGSize(
                width: rawOffset.width + helperLinesOffset.width,
                height: rawOffset.height + helperLinesOffset.height
            )
        } else {
            finalOffset = rawOffset
        }
        
        state.currentOffset = finalOffset
        dragState = state
        
        // Notify about position changes
        let newPositions = state.allNewPositions()
        onDragChanged?(newPositions)
    }
    
    /// Update the drag with a new position (type-safe)
    /// - Parameter point: Current drag point in canvas coordinates (type-safe)
    public func updateDrag(to point: CanvasPoint) {
        updateDrag(to: point.cgPoint)
    }
    
    /// Adjust drag for auto-pan compensation
    /// Called when viewport pans during drag to maintain cursor position
    /// - Parameters:
    ///   - delta: Auto-pan delta in screen coordinates
    ///   - currentScale: Current zoom scale
    public func adjustForAutoPan(delta: CGSize, currentScale: CGFloat) {
        guard var state = dragState else { return }
        
        // Adjust offset to compensate for viewport pan
        // Divide by scale to convert screen coords to canvas coords
        state.currentOffset.width -= delta.width / currentScale
        state.currentOffset.height -= delta.height / currentScale
        
        dragState = state
    }
    
    /// End the current drag operation
    /// - Returns: Final positions of dragged nodes, or nil if drag was cancelled
    @discardableResult
    public func endDrag() -> [UUID: CGPoint]? {
        guard let state = dragState else { return nil }
        
        let finalPositions = state.hasMoved ? state.allNewPositions() : nil
        
        if let positions = finalPositions {
            onDragEnded?(positions)
        }
        
        dragState = nil
        return finalPositions
    }
    
    /// Cancel the current drag operation without applying changes
    public func cancelDrag() {
        dragState = nil
    }
    
    // MARK: - Auto-Pan
    
    /// Calculate auto-pan delta based on cursor position
    /// - Parameters:
    ///   - screenPosition: Cursor position in screen coordinates
    ///   - viewportSize: Size of the viewport
    /// - Returns: Pan delta to apply, or zero if not in auto-pan zone
    public func calculateAutoPanDelta(
        screenPosition: CGPoint,
        viewportSize: CGSize
    ) -> CGSize {
        guard autoPanEnabled, dragState != nil else { return .zero }
        
        let (x, y) = calculateAutoPan(
            position: screenPosition,
            bounds: viewportSize,
            speed: autoPanSpeed,
            threshold: autoPanThreshold
        )
        
        return CGSize(width: -x, height: -y)
    }
    
    // MARK: - Helpers
    
    /// Whether a drag is currently in progress
    public var isDragging: Bool {
        dragState != nil
    }
    
    /// Whether the current drag has moved beyond threshold
    public var hasMoved: Bool {
        dragState?.hasMoved ?? false
    }
    
    /// Update grid size (also updates snap grid)
    public func setGridSize(_ size: CGFloat) {
        gridSize = size
        snapGrid = SnapGrid(size: size)
    }
    
    /// Get the current offset for a specific node
    /// - Parameter nodeId: ID of the node
    /// - Returns: Current visual offset to apply, or zero if not dragging
    public func currentOffset(for nodeId: UUID) -> CGSize {
        guard let state = dragState,
              state.draggedNodes.contains(nodeId),
              state.hasMoved else {
            return .zero
        }
        return state.currentOffset
    }
}
