//
//  CoordinateSystemTests.swift
//  SwiftFlowTests
//
//  Comprehensive tests for the coordinate system architecture.
//

import XCTest
@testable import SwiftFlow

final class CoordinateSystemTests: XCTestCase {
    
    // MARK: - Test Node Implementation
    
    struct TestNode: FlowNode, Codable {
        let id: UUID
        var position: CGPoint
        var width: CGFloat
        var height: CGFloat
        var inputPorts: [any FlowPort] = []
        var outputPorts: [any FlowPort] = []
        
        init(id: UUID = UUID(), position: CGPoint, width: CGFloat, height: CGFloat) {
            self.id = id
            self.position = position
            self.width = width
            self.height = height
        }
    }
    
    // MARK: - FlowNode Protocol Tests
    
    func testNodePositionIsTopLeft() {
        // node.position should be the top-left corner
        let node = TestNode(position: CGPoint(x: 100, y: 200), width: 150, height: 80)
        
        XCTAssertEqual(node.position.x, 100)
        XCTAssertEqual(node.position.y, 200)
    }
    
    func testNodeBoundsCalculatedFromTopLeft() {
        // bounds should start at position (top-left) and extend by width/height
        let node = TestNode(position: CGPoint(x: 100, y: 200), width: 150, height: 80)
        
        XCTAssertEqual(node.bounds.origin.x, 100)
        XCTAssertEqual(node.bounds.origin.y, 200)
        XCTAssertEqual(node.bounds.width, 150)
        XCTAssertEqual(node.bounds.height, 80)
        XCTAssertEqual(node.bounds.maxX, 250)
        XCTAssertEqual(node.bounds.maxY, 280)
    }
    
    func testNodeCenterCalculatedFromTopLeft() {
        // center should be position + (width/2, height/2)
        let node = TestNode(position: CGPoint(x: 100, y: 200), width: 150, height: 80)
        
        XCTAssertEqual(node.center.x, 175, accuracy: 0.001)  // 100 + 75
        XCTAssertEqual(node.center.y, 240, accuracy: 0.001)  // 200 + 40
    }
    
    func testNodeTopLeftProperty() {
        // topLeft should be same as position
        let node = TestNode(position: CGPoint(x: 100, y: 200), width: 150, height: 80)
        
        XCTAssertEqual(node.topLeft, node.position)
        XCTAssertEqual(node.topLeft.x, 100)
        XCTAssertEqual(node.topLeft.y, 200)
    }
    
    // MARK: - FlowTransform Tests
    
    func testTransformScreenToCanvas() {
        let transform = FlowTransform(offset: CGPoint(x: 50, y: 30), scale: 2.0)
        let screenPoint = CGPoint(x: 250, y: 230)
        
        // Formula: canvas = (screen - offset) / scale
        let canvasPoint = transform.screenToCanvas(screenPoint)
        
        XCTAssertEqual(canvasPoint.x, 100, accuracy: 0.001)  // (250 - 50) / 2
        XCTAssertEqual(canvasPoint.y, 100, accuracy: 0.001)  // (230 - 30) / 2
    }
    
    func testTransformCanvasToScreen() {
        let transform = FlowTransform(offset: CGPoint(x: 50, y: 30), scale: 2.0)
        let canvasPoint = CGPoint(x: 100, y: 100)
        
        // Formula: screen = canvas * scale + offset
        let screenPoint = transform.canvasToScreen(canvasPoint)
        
        XCTAssertEqual(screenPoint.x, 250, accuracy: 0.001)  // 100 * 2 + 50
        XCTAssertEqual(screenPoint.y, 230, accuracy: 0.001)  // 100 * 2 + 30
    }
    
    func testTransformRoundTrip() {
        let transform = FlowTransform(offset: CGPoint(x: 75, y: 45), scale: 1.5)
        let original = CGPoint(x: 123.456, y: 789.012)
        
        let screen = transform.canvasToScreen(original)
        let backToCanvas = transform.screenToCanvas(screen)
        
        XCTAssertEqual(backToCanvas.x, original.x, accuracy: 0.001)
        XCTAssertEqual(backToCanvas.y, original.y, accuracy: 0.001)
    }
    
    func testTransformSizeConversion() {
        let transform = FlowTransform(offset: CGPoint(x: 50, y: 30), scale: 2.0)
        
        // Sizes are only affected by scale, not offset
        let canvasSize = CGSize(width: 100, height: 50)
        let screenSize = transform.canvasToScreen(canvasSize)
        
        XCTAssertEqual(screenSize.width, 200, accuracy: 0.001)  // 100 * 2
        XCTAssertEqual(screenSize.height, 100, accuracy: 0.001) // 50 * 2
        
        let backToCanvas = transform.screenToCanvas(screenSize)
        XCTAssertEqual(backToCanvas.width, canvasSize.width, accuracy: 0.001)
        XCTAssertEqual(backToCanvas.height, canvasSize.height, accuracy: 0.001)
    }
    
    func testTransformRectConversion() {
        let transform = FlowTransform(offset: CGPoint(x: 50, y: 30), scale: 2.0)
        let canvasRect = CGRect(x: 100, y: 100, width: 50, height: 30)
        
        let screenRect = transform.canvasToScreen(canvasRect)
        
        // Origin should be transformed
        XCTAssertEqual(screenRect.origin.x, 250, accuracy: 0.001)  // 100 * 2 + 50
        XCTAssertEqual(screenRect.origin.y, 230, accuracy: 0.001)  // 100 * 2 + 30
        
        // Size should be scaled
        XCTAssertEqual(screenRect.width, 100, accuracy: 0.001)     // 50 * 2
        XCTAssertEqual(screenRect.height, 60, accuracy: 0.001)     // 30 * 2
    }
    
    func testTransformZoomWithPivot() {
        let initialTransform = FlowTransform(offset: CGPoint(x: 100, y: 80), scale: 1.0)
        let pivotScreen = CGPoint(x: 300, y: 250)
        
        // Convert pivot to canvas before zoom
        let pivotCanvas = initialTransform.screenToCanvas(pivotScreen)
        
        // Apply zoom
        let newScale: CGFloat = 2.0
        let newOffset = CGPoint(
            x: pivotScreen.x - pivotCanvas.x * newScale,
            y: pivotScreen.y - pivotCanvas.y * newScale
        )
        
        let newTransform = FlowTransform(offset: newOffset, scale: newScale)
        
        // Verify pivot stayed in same screen position
        let pivotScreenAfter = newTransform.canvasToScreen(pivotCanvas)
        
        XCTAssertEqual(pivotScreenAfter.x, pivotScreen.x, accuracy: 0.001)
        XCTAssertEqual(pivotScreenAfter.y, pivotScreen.y, accuracy: 0.001)
    }
    
    // MARK: - Node-Local Coordinate Tests
    
    func testNodeLocalToCanvas() {
        let transform = FlowTransform.identity
        let nodeTopLeft = CGPoint(x: 100, y: 200)
        let nodeLocalPoint = CGPoint(x: 50, y: 25)
        
        let canvasPoint = transform.nodeLocalToCanvas(nodeLocalPoint, nodeTopLeft: nodeTopLeft)
        
        XCTAssertEqual(canvasPoint.x, 150, accuracy: 0.001)  // 100 + 50
        XCTAssertEqual(canvasPoint.y, 225, accuracy: 0.001)  // 200 + 25
    }
    
    func testCanvasToNodeLocal() {
        let transform = FlowTransform.identity
        let nodeTopLeft = CGPoint(x: 100, y: 200)
        let canvasPoint = CGPoint(x: 150, y: 225)
        
        let nodeLocalPoint = transform.canvasToNodeLocal(canvasPoint, nodeTopLeft: nodeTopLeft)
        
        XCTAssertEqual(nodeLocalPoint.x, 50, accuracy: 0.001)  // 150 - 100
        XCTAssertEqual(nodeLocalPoint.y, 25, accuracy: 0.001)  // 225 - 200
    }
    
    // MARK: - Port Preset Tests
    
    func testPortPresetTopLeft() {
        let nodeSize = CGSize(width: 200, height: 100)
        let position = PortPreset.topLeft.calculatePosition(nodeSize: nodeSize)
        
        XCTAssertEqual(position.x, 0, accuracy: 0.001)
        XCTAssertEqual(position.y, 0, accuracy: 0.001)
    }
    
    func testPortPresetTopCenter() {
        let nodeSize = CGSize(width: 200, height: 100)
        let position = PortPreset.topCenter.calculatePosition(nodeSize: nodeSize)
        
        XCTAssertEqual(position.x, 100, accuracy: 0.001)  // width / 2
        XCTAssertEqual(position.y, 0, accuracy: 0.001)
    }
    
    func testPortPresetRightCenter() {
        let nodeSize = CGSize(width: 200, height: 100)
        let position = PortPreset.rightCenter.calculatePosition(nodeSize: nodeSize)
        
        XCTAssertEqual(position.x, 200, accuracy: 0.001)  // width
        XCTAssertEqual(position.y, 50, accuracy: 0.001)   // height / 2
    }
    
    func testPortPresetBottomRight() {
        let nodeSize = CGSize(width: 200, height: 100)
        let position = PortPreset.bottomRight.calculatePosition(nodeSize: nodeSize)
        
        XCTAssertEqual(position.x, 200, accuracy: 0.001)  // width
        XCTAssertEqual(position.y, 100, accuracy: 0.001)  // height
    }
    
    func testPortPresetCenter() {
        let nodeSize = CGSize(width: 200, height: 100)
        let position = PortPreset.center.calculatePosition(nodeSize: nodeSize)
        
        XCTAssertEqual(position.x, 100, accuracy: 0.001)  // width / 2
        XCTAssertEqual(position.y, 50, accuracy: 0.001)   // height / 2
    }
    
    func testPortPresetCustom() {
        let nodeSize = CGSize(width: 200, height: 100)
        let customPoint = CGPoint(x: 75, y: 30)
        let position = PortPreset.custom(customPoint).calculatePosition(nodeSize: nodeSize)
        
        XCTAssertEqual(position.x, 75, accuracy: 0.001)
        XCTAssertEqual(position.y, 30, accuracy: 0.001)
    }
    
    // MARK: - Port Layout Tests
    
    func testPortLayoutWithoutOffset() {
        let layout = PortLayout(preset: .rightCenter)
        let nodeSize = CGSize(width: 200, height: 100)
        
        let position = layout.position(nodeSize: nodeSize)
        
        XCTAssertEqual(position.x, 200, accuracy: 0.001)
        XCTAssertEqual(position.y, 50, accuracy: 0.001)
    }
    
    func testPortLayoutWithOffset() {
        let layout = PortLayout(preset: .rightCenter, offset: CGPoint(x: 10, y: -5))
        let nodeSize = CGSize(width: 200, height: 100)
        
        let position = layout.position(nodeSize: nodeSize)
        
        // rightCenter (200, 50) + offset (10, -5) = (210, 45)
        XCTAssertEqual(position.x, 210, accuracy: 0.001)
        XCTAssertEqual(position.y, 45, accuracy: 0.001)
    }
    
    func testPortLayoutAdaptsToResize() {
        let layout = PortLayout(preset: .bottomRight)
        
        // Original size
        let originalSize = CGSize(width: 200, height: 100)
        let originalPos = layout.position(nodeSize: originalSize)
        XCTAssertEqual(originalPos.x, 200, accuracy: 0.001)
        XCTAssertEqual(originalPos.y, 100, accuracy: 0.001)
        
        // After resize
        let newSize = CGSize(width: 300, height: 150)
        let newPos = layout.position(nodeSize: newSize)
        XCTAssertEqual(newPos.x, 300, accuracy: 0.001)
        XCTAssertEqual(newPos.y, 150, accuracy: 0.001)
    }
    
    func testPortLayoutCustomStaysFixed() {
        let layout = PortLayout(preset: .custom(CGPoint(x: 50, y: 30)))
        
        // Original size
        let originalSize = CGSize(width: 200, height: 100)
        let originalPos = layout.position(nodeSize: originalSize)
        XCTAssertEqual(originalPos.x, 50, accuracy: 0.001)
        XCTAssertEqual(originalPos.y, 30, accuracy: 0.001)
        
        // After resize (custom position doesn't change)
        let newSize = CGSize(width: 300, height: 150)
        let newPos = layout.position(nodeSize: newSize)
        XCTAssertEqual(newPos.x, 50, accuracy: 0.001)
        XCTAssertEqual(newPos.y, 30, accuracy: 0.001)
    }
    
    // MARK: - Drag Offset Calculation Tests
    
    func testDragOffsetCalculation() {
        // Node at canvas (100, 200)
        let nodeTopLeft = CGPoint(x: 100, y: 200)
        // Cursor at canvas (120, 220) - clicking 20px right and down from top-left
        let cursorCanvas = CGPoint(x: 120, y: 220)
        
        // Calculate offset from cursor to node's top-left
        let offset = CGSize(
            width: nodeTopLeft.x - cursorCanvas.x,   // 100 - 120 = -20
            height: nodeTopLeft.y - cursorCanvas.y   // 200 - 220 = -20
        )
        
        XCTAssertEqual(offset.width, -20, accuracy: 0.001)
        XCTAssertEqual(offset.height, -20, accuracy: 0.001)
        
        // When cursor moves to (140, 240), node should move to:
        let newCursor = CGPoint(x: 140, y: 240)
        let newNodePos = CGPoint(
            x: newCursor.x + offset.width,    // 140 + (-20) = 120
            y: newCursor.y + offset.height    // 240 + (-20) = 220
        )
        
        XCTAssertEqual(newNodePos.x, 120, accuracy: 0.001)
        XCTAssertEqual(newNodePos.y, 220, accuracy: 0.001)
    }
    
    func testDragMaintainsGrabPoint() {
        let transform = FlowTransform(offset: CGPoint(x: 0, y: 0), scale: 1.0)
        
        // Node at canvas (100, 200), size 80x60
        let nodeTopLeft = CGPoint(x: 100, y: 200)
        let nodeSize = CGSize(width: 80, height: 60)
        
        // User clicks near bottom-right: canvas (170, 250)
        let initialCursorCanvas = CGPoint(x: 170, y: 250)
        
        // Calculate offset
        let offset = CGSize(
            width: nodeTopLeft.x - initialCursorCanvas.x,   // 100 - 170 = -70
            height: nodeTopLeft.y - initialCursorCanvas.y   // 200 - 250 = -50
        )
        
        // Cursor moves to (200, 280)
        let newCursorCanvas = CGPoint(x: 200, y: 280)
        let newNodePos = CGPoint(
            x: newCursorCanvas.x + offset.width,   // 200 + (-70) = 130
            y: newCursorCanvas.y + offset.height   // 280 + (-50) = 230
        )
        
        // Verify the point under cursor moved proportionally
        // Initially cursor was at node-local (70, 50)
        // After drag, cursor should still be at node-local (70, 50)
        let nodeLocalAfter = CGPoint(
            x: newCursorCanvas.x - newNodePos.x,  // Should be 70
            y: newCursorCanvas.y - newNodePos.y   // Should be 50
        )
        
        XCTAssertEqual(nodeLocalAfter.x, 70, accuracy: 0.001)
        XCTAssertEqual(nodeLocalAfter.y, 50, accuracy: 0.001)
    }
    
    // MARK: - Box Selection Tests
    
    func testBoxSelectionScreenToCanvas() {
        let transform = FlowTransform(offset: CGPoint(x: 50, y: 30), scale: 2.0)
        
        // Selection rectangle in screen space
        let screenRect = CGRect(x: 100, y: 80, width: 200, height: 150)
        
        // Convert to canvas space
        let canvasRect = transform.screenToCanvas(screenRect)
        
        // Origin: (100 - 50) / 2 = 25, (80 - 30) / 2 = 25
        XCTAssertEqual(canvasRect.origin.x, 25, accuracy: 0.001)
        XCTAssertEqual(canvasRect.origin.y, 25, accuracy: 0.001)
        
        // Size: 200 / 2 = 100, 150 / 2 = 75
        XCTAssertEqual(canvasRect.width, 100, accuracy: 0.001)
        XCTAssertEqual(canvasRect.height, 75, accuracy: 0.001)
    }
    
    func testBoxSelectionIntersection() {
        // Selection box in canvas space
        let selectionRect = CGRect(x: 50, y: 50, width: 100, height: 100)
        
        // Node fully inside
        let nodeInside = TestNode(position: CGPoint(x: 60, y: 60), width: 30, height: 30)
        XCTAssertTrue(selectionRect.intersects(nodeInside.bounds))
        
        // Node partially overlapping
        let nodePartial = TestNode(position: CGPoint(x: 100, y: 100), width: 100, height: 100)
        XCTAssertTrue(selectionRect.intersects(nodePartial.bounds))
        
        // Node completely outside
        let nodeOutside = TestNode(position: CGPoint(x: 200, y: 200), width: 50, height: 50)
        XCTAssertFalse(selectionRect.intersects(nodeOutside.bounds))
    }
}
