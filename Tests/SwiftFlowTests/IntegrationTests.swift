//
//  IntegrationTests.swift
//  SwiftFlowTests
//
//  Integration tests for verifying complex interactions work correctly.
//

import XCTest
@testable import SwiftFlow

// MARK: - DriftTests

/// Tests to verify there's no coordinate drift when combining zoom, pan, and drag operations.
final class DriftTests: XCTestCase {
    
    /// Test: Coordinate conversion roundtrip maintains accuracy
    func testCoordinateConversionRoundtrip() {
        let transform = FlowTransform(
            offset: CGPoint(x: 100, y: 50),
            scale: 1.5
        )
        
        let originalScreen = CGPoint(x: 200, y: 300)
        let canvas = transform.screenToCanvas(originalScreen)
        let backToScreen = transform.canvasToScreen(canvas)
        
        XCTAssertEqual(originalScreen.x, backToScreen.x, accuracy: 0.001)
        XCTAssertEqual(originalScreen.y, backToScreen.y, accuracy: 0.001)
    }
    
    /// Test: Type-safe coordinate conversion
    func testTypeSafeCoordinateConversion() {
        let transform = FlowTransform(
            offset: CGPoint(x: -50, y: 100),
            scale: 2.0
        )
        
        let screenPoint = ScreenPoint(x: 400, y: 300)
        let canvasPoint = transform.toCanvas(screenPoint)
        let backToScreen = transform.toScreen(canvasPoint)
        
        XCTAssertEqual(screenPoint.x, backToScreen.x, accuracy: 0.001)
        XCTAssertEqual(screenPoint.y, backToScreen.y, accuracy: 0.001)
    }
    
    /// Test: Drag with zoom != 1 maintains correct delta
    func testDragWithZoom() {
        let transform = FlowTransform(
            offset: CGPoint(x: 0, y: 0),
            scale: 1.5
        )
        
        // Simulate drag from screen (200, 200) to (350, 350)
        let startScreen = ScreenPoint(x: 200, y: 200)
        let endScreen = ScreenPoint(x: 350, y: 350)
        
        let startCanvas = transform.toCanvas(startScreen)
        let endCanvas = transform.toCanvas(endScreen)
        
        // Expected delta in canvas coords (screen delta / scale)
        let screenDeltaX = endScreen.x - startScreen.x  // 150
        let screenDeltaY = endScreen.y - startScreen.y  // 150
        
        let expectedCanvasDeltaX = screenDeltaX / 1.5  // 100
        let expectedCanvasDeltaY = screenDeltaY / 1.5  // 100
        
        let actualCanvasDeltaX = endCanvas.x - startCanvas.x
        let actualCanvasDeltaY = endCanvas.y - startCanvas.y
        
        XCTAssertEqual(actualCanvasDeltaX, expectedCanvasDeltaX, accuracy: 0.001)
        XCTAssertEqual(actualCanvasDeltaY, expectedCanvasDeltaY, accuracy: 0.001)
    }
    
    /// Test: Drag with zoom and pan maintains correct position
    func testDragWithZoomAndPan() {
        let transform = FlowTransform(
            offset: CGPoint(x: 100, y: 100),
            scale: 2.0
        )
        
        // Screen point (300, 400) should map to canvas point (100, 150)
        // canvas = (screen - offset) / scale
        // canvas.x = (300 - 100) / 2 = 100
        // canvas.y = (400 - 100) / 2 = 150
        
        let screenPoint = ScreenPoint(x: 300, y: 400)
        let canvasPoint = transform.toCanvas(screenPoint)
        
        XCTAssertEqual(canvasPoint.x, 100, accuracy: 0.001)
        XCTAssertEqual(canvasPoint.y, 150, accuracy: 0.001)
        
        // And back
        let backToScreen = transform.toScreen(canvasPoint)
        XCTAssertEqual(backToScreen.x, 300, accuracy: 0.001)
        XCTAssertEqual(backToScreen.y, 400, accuracy: 0.001)
    }
    
    /// Test: Zoom at point maintains that point's canvas position
    func testZoomAtPointMaintainsPosition() {
        var transform = FlowTransform(
            offset: CGPoint(x: 0, y: 0),
            scale: 1.0
        )
        
        let zoomCenter = CGPoint(x: 400, y: 300)
        
        // Get canvas position at zoom center before zoom
        let canvasBefore = transform.screenToCanvas(zoomCenter)
        
        // Zoom in 2x
        transform = transform.zoomed(by: 2.0, at: zoomCenter)
        
        // The screen point should still map to the same canvas point
        let canvasAfter = transform.screenToCanvas(zoomCenter)
        
        XCTAssertEqual(canvasBefore.x, canvasAfter.x, accuracy: 0.001)
        XCTAssertEqual(canvasBefore.y, canvasAfter.y, accuracy: 0.001)
    }
    
    /// Test: Multiple zoom operations don't drift
    func testMultipleZoomsDontDrift() {
        var transform = FlowTransform(
            offset: CGPoint(x: 100, y: 100),
            scale: 1.0
        )
        
        let fixedPoint = CGPoint(x: 500, y: 400)
        let originalCanvas = transform.screenToCanvas(fixedPoint)
        
        // Zoom in and out multiple times at the same point
        for _ in 0..<10 {
            transform = transform.zoomed(by: 1.2, at: fixedPoint)
        }
        for _ in 0..<10 {
            transform = transform.zoomed(by: 0.833333, at: fixedPoint)  // 1/1.2
        }
        
        let finalCanvas = transform.screenToCanvas(fixedPoint)
        
        // Should be back to approximately the same position
        XCTAssertEqual(originalCanvas.x, finalCanvas.x, accuracy: 0.01)
        XCTAssertEqual(originalCanvas.y, finalCanvas.y, accuracy: 0.01)
    }
}

// MARK: - MiniMapTests

/// Tests for minimap calculations and viewport indicator accuracy.
final class MiniMapIntegrationTests: XCTestCase {
    
    /// Test: MiniMap indicator roundtrip (click -> pan -> verify indicator moved)
    @MainActor
    func testMiniMapIndicatorRoundtrip() {
        let miniMapController = MiniMapController()
        
        // Setup
        miniMapController.miniMapSize = CGSize(width: 200, height: 150)
        miniMapController.contentPadding = 20
        
        // Set nodes bounds
        miniMapController.nodesBounds = CanvasRect(
            origin: CanvasPoint(x: 0, y: 0),
            size: CGSize(width: 1000, height: 800)
        )
        
        // Set initial viewport
        miniMapController.viewportRectCanvas = CanvasRect(
            origin: CanvasPoint(x: 0, y: 0),
            size: CGSize(width: 800, height: 600)
        )
        
        // Force update
        miniMapController.forceUpdate()
        
        // Get initial indicator position
        let initialIndicatorCenter = CGPoint(
            x: miniMapController.viewportIndicatorFrame.midX,
            y: miniMapController.viewportIndicatorFrame.midY
        )
        
        // Simulate click at a different position in minimap
        let clickOffset = CGPoint(x: 30, y: 20)
        let clickPoint = CGPoint(
            x: initialIndicatorCenter.x + clickOffset.x,
            y: initialIndicatorCenter.y + clickOffset.y
        )
        
        // Calculate new viewport center from click
        let newCanvasCenter = miniMapController.miniMapToCanvas(clickPoint)
        
        // Calculate new viewport origin (center - half viewport size)
        let viewportSize = CGSize(width: 800, height: 600)
        let newViewportOrigin = CanvasPoint(
            x: newCanvasCenter.x - viewportSize.width / 2,
            y: newCanvasCenter.y - viewportSize.height / 2
        )
        
        // Update minimap with new viewport
        miniMapController.viewportRectCanvas = CanvasRect(
            origin: newViewportOrigin,
            size: viewportSize
        )
        miniMapController.forceUpdate()
        
        // The indicator center should now be at the click point
        let newIndicatorCenter = CGPoint(
            x: miniMapController.viewportIndicatorFrame.midX,
            y: miniMapController.viewportIndicatorFrame.midY
        )
        
        XCTAssertEqual(newIndicatorCenter.x, clickPoint.x, accuracy: 1.0)
        XCTAssertEqual(newIndicatorCenter.y, clickPoint.y, accuracy: 1.0)
    }
    
    /// Test: MiniMap bounds always include viewport
    @MainActor
    func testMiniMapBoundsIncludeViewport() {
        let miniMapController = MiniMapController()
        
        // Setup with nodes in one area
        miniMapController.nodesBounds = CanvasRect(
            origin: CanvasPoint(x: 0, y: 0),
            size: CGSize(width: 500, height: 400)
        )
        
        // But viewport is panned far away
        miniMapController.viewportRectCanvas = CanvasRect(
            origin: CanvasPoint(x: 2000, y: 1500),
            size: CGSize(width: 800, height: 600)
        )
        
        miniMapController.forceUpdate()
        
        // Content bounds should include both nodes and viewport
        let contentBounds = miniMapController.contentBounds.cgRect
        
        // Should contain nodes area
        XCTAssertLessThanOrEqual(contentBounds.minX, 0)
        XCTAssertLessThanOrEqual(contentBounds.minY, 0)
        
        // Should contain viewport area
        XCTAssertGreaterThanOrEqual(contentBounds.maxX, 2800)  // 2000 + 800
        XCTAssertGreaterThanOrEqual(contentBounds.maxY, 2100)  // 1500 + 600
    }
    
    /// Test: MiniMap coordinate conversion accuracy
    @MainActor
    func testMiniMapCoordinateConversion() {
        let miniMapController = MiniMapController()
        
        miniMapController.miniMapSize = CGSize(width: 200, height: 150)
        miniMapController.contentPadding = 0  // No padding for easier math
        
        miniMapController.nodesBounds = CanvasRect(
            origin: CanvasPoint(x: 0, y: 0),
            size: CGSize(width: 1000, height: 750)  // Same aspect ratio as minimap
        )
        
        miniMapController.viewportRectCanvas = CanvasRect(
            origin: CanvasPoint(x: 0, y: 0),
            size: CGSize(width: 200, height: 150)
        )
        
        miniMapController.forceUpdate()
        
        // Scale should be minimap size / content size = 200/1000 = 0.2
        XCTAssertEqual(miniMapController.scale, 0.2, accuracy: 0.01)
        
        // Canvas point (500, 375) should map to minimap center
        let canvasCenter = CanvasPoint(x: 500, y: 375)
        let miniMapPoint = miniMapController.canvasToMiniMap(canvasCenter)
        
        XCTAssertEqual(miniMapPoint.x, 100, accuracy: 1.0)  // minimap center
        XCTAssertEqual(miniMapPoint.y, 75, accuracy: 1.0)
        
        // And back
        let backToCanvas = miniMapController.miniMapToCanvas(miniMapPoint)
        XCTAssertEqual(backToCanvas.x, canvasCenter.x, accuracy: 1.0)
        XCTAssertEqual(backToCanvas.y, canvasCenter.y, accuracy: 1.0)
    }
}

// MARK: - CommandTests

/// Tests for command execution and undo/redo.
final class CommandIntegrationTests: XCTestCase {
    
    /// Test: UndoStack push and pop
    @MainActor
    func testUndoStackBasics() {
        let undoStack = UndoStack(maxHistorySize: 10)
        
        XCTAssertFalse(undoStack.canUndo)
        XCTAssertFalse(undoStack.canRedo)
        
        // Push a transaction
        let transaction = CanvasTransaction(
            name: "Move",
            commands: [.moveNodes(ids: [UUID()], delta: CGSize(width: 10, height: 10))]
        )
        undoStack.push(transaction)
        
        XCTAssertTrue(undoStack.canUndo)
        XCTAssertFalse(undoStack.canRedo)
        XCTAssertEqual(undoStack.undoName, "Move")
        
        // Pop for undo
        let popped = undoStack.popUndo()
        XCTAssertNotNil(popped)
        XCTAssertEqual(popped?.name, "Move")
        
        XCTAssertFalse(undoStack.canUndo)
        XCTAssertTrue(undoStack.canRedo)
        XCTAssertEqual(undoStack.redoName, "Move")
        
        // Redo
        let redone = undoStack.popRedo()
        XCTAssertNotNil(redone)
        
        XCTAssertTrue(undoStack.canUndo)
        XCTAssertFalse(undoStack.canRedo)
    }
    
    /// Test: UndoStack history limit
    @MainActor
    func testUndoStackHistoryLimit() {
        let undoStack = UndoStack(maxHistorySize: 5)
        
        // Push 10 transactions
        for i in 0..<10 {
            let transaction = CanvasTransaction(
                name: "Action \(i)",
                commands: [.moveNodes(ids: [UUID()], delta: CGSize(width: CGFloat(i), height: 0))]
            )
            undoStack.push(transaction)
        }
        
        // Should only have 5 in history
        XCTAssertEqual(undoStack.undoCount, 5)
        
        // First action should be #5 (0-4 were trimmed)
        _ = undoStack.popUndo()
        _ = undoStack.popUndo()
        _ = undoStack.popUndo()
        _ = undoStack.popUndo()
        let oldest = undoStack.popUndo()
        XCTAssertEqual(oldest?.name, "Action 5")
    }
    
    /// Test: New push clears redo stack
    @MainActor
    func testNewPushClearsRedo() {
        let undoStack = UndoStack()
        
        let nodeId = UUID()
        let moveCommand = CanvasCommand.moveNodes(
            ids: [nodeId],
            delta: CGSize(width: 10, height: 10)
        )
        
        // Push two transactions with undoable commands
        undoStack.push(CanvasTransaction(name: "A", commands: [moveCommand]))
        undoStack.push(CanvasTransaction(name: "B", commands: [moveCommand]))
        
        // Undo one
        _ = undoStack.popUndo()
        XCTAssertTrue(undoStack.canRedo)
        
        // Push new transaction
        undoStack.push(CanvasTransaction(name: "C", commands: [moveCommand]))
        
        // Redo should be cleared
        XCTAssertFalse(undoStack.canRedo)
    }
}

// MARK: - CacheTests

/// Tests for cache functionality.
final class CacheIntegrationTests: XCTestCase {
    
    /// Test: NodesBoundsCache returns cached value
    func testNodesBoundsCacheHit() {
        let cache = NodesBoundsCache()
        
        struct TestNode: FlowNode, Codable {
            let id: UUID
            var position: CGPoint
            var width: CGFloat = 100
            var height: CGFloat = 50
            var inputPorts: [any FlowPort] { [] }
            var outputPorts: [any FlowPort] { [] }
        }
        
        let nodes = [
            TestNode(id: UUID(), position: CGPoint(x: 0, y: 0)),
            TestNode(id: UUID(), position: CGPoint(x: 200, y: 100))
        ]
        
        // First call calculates
        let bounds1 = cache.getBounds(for: nodes)
        XCTAssertNotNil(bounds1)
        
        // Second call should return cached
        let bounds2 = cache.getBounds(for: nodes)
        XCTAssertEqual(bounds1?.cgRect, bounds2?.cgRect)
        
        // Verify it's a cache hit by checking the bounds are identical
        XCTAssertTrue(cache.isValid(for: nodes))
    }
    
    /// Test: NodesBoundsCache invalidates on change
    func testNodesBoundsCacheInvalidation() {
        let cache = NodesBoundsCache()
        
        struct TestNode: FlowNode, Codable {
            let id: UUID
            var position: CGPoint
            var width: CGFloat = 100
            var height: CGFloat = 50
            var inputPorts: [any FlowPort] { [] }
            var outputPorts: [any FlowPort] { [] }
        }
        
        var nodes = [
            TestNode(id: UUID(), position: CGPoint(x: 0, y: 0))
        ]
        
        _ = cache.getBounds(for: nodes)
        XCTAssertTrue(cache.isValid(for: nodes))
        
        // Modify a node
        nodes[0].position = CGPoint(x: 100, y: 100)
        
        // Cache should be invalid
        XCTAssertFalse(cache.isValid(for: nodes))
    }
}
