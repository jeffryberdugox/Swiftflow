//
//  MiniMapTests.swift
//  SwiftFlowTests
//
//  Tests for MiniMap coordinate conversions and calculations.
//

import XCTest
@testable import SwiftFlow

@MainActor
final class MiniMapTests: XCTestCase {
    
    // MARK: - Test Helpers
    
    private struct TestNode: FlowNode {
        let id: UUID
        var position: CGPoint
        var width: CGFloat
        var height: CGFloat
        var isDraggable: Bool = true
        var isSelectable: Bool = true
        var inputPorts: [any FlowPort] = []
        var outputPorts: [any FlowPort] = []
    }
    
    private var controller: MiniMapController!
    private var panZoomManager: PanZoomManager!
    
    override func setUp() async throws {
        controller = MiniMapController()
        panZoomManager = PanZoomManager(minZoom: 0.1, maxZoom: 4.0)
        panZoomManager.viewportSize = CGSize(width: 800, height: 600)
    }
    
    // MARK: - Helper Methods
    
    private func updateController(
        nodes: [TestNode],
        miniMapSize: CGSize = CGSize(width: 200, height: 150),
        contentPadding: CGFloat = 50
    ) {
        // Calculate nodes bounds
        let nodesBounds = calculateNodesBounds(nodes) ?? .zero
        
        // Get viewport from panZoomManager
        let viewportRect = panZoomManager.viewportRectCanvas
        
        // Update controller
        controller.miniMapSize = miniMapSize
        controller.contentPadding = contentPadding
        controller.nodesBounds = nodesBounds
        controller.viewportRectCanvas = viewportRect
        controller.forceUpdate()
    }
    
    private func calculateNodesBounds(_ nodes: [TestNode]) -> CanvasRect? {
        guard !nodes.isEmpty else { return nil }
        
        var minX = CGFloat.infinity
        var minY = CGFloat.infinity
        var maxX = -CGFloat.infinity
        var maxY = -CGFloat.infinity
        
        for node in nodes {
            minX = min(minX, node.position.x)
            minY = min(minY, node.position.y)
            maxX = max(maxX, node.position.x + node.width)
            maxY = max(maxY, node.position.y + node.height)
        }
        
        return CanvasRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }
    
    // MARK: - Bounds Calculation Tests
    
    func testBoundsCalculationWithMultipleNodes() {
        let nodes = [
            TestNode(id: UUID(), position: CGPoint(x: 0, y: 0), width: 100, height: 80),
            TestNode(id: UUID(), position: CGPoint(x: 200, y: 100), width: 150, height: 100),
            TestNode(id: UUID(), position: CGPoint(x: 400, y: 200), width: 120, height: 90)
        ]
        
        updateController(nodes: nodes, miniMapSize: CGSize(width: 200, height: 150), contentPadding: 50)
        
        // Content bounds should include nodes bounds + viewport + padding
        XCTAssertGreaterThan(controller.contentBounds.width, 0)
        XCTAssertGreaterThan(controller.contentBounds.height, 0)
    }
    
    func testBoundsCalculationWithSingleNode() {
        let nodes = [
            TestNode(id: UUID(), position: CGPoint(x: 100, y: 100), width: 150, height: 100)
        ]
        
        updateController(nodes: nodes, miniMapSize: CGSize(width: 200, height: 150), contentPadding: 50)
        
        // Should have valid bounds
        XCTAssertGreaterThan(controller.contentBounds.width, 0)
        XCTAssertGreaterThan(controller.contentBounds.height, 0)
    }
    
    func testBoundsCalculationWithNoNodes() {
        let nodes: [TestNode] = []
        
        updateController(nodes: nodes, miniMapSize: CGSize(width: 200, height: 150), contentPadding: 50)
        
        // Should have default bounds
        XCTAssertGreaterThan(controller.contentBounds.width, 0)
        XCTAssertGreaterThan(controller.contentBounds.height, 0)
    }
    
    // MARK: - Scale Calculation Tests
    
    func testScaleCalculationFitsContent() {
        let nodes = [
            TestNode(id: UUID(), position: CGPoint(x: 0, y: 0), width: 400, height: 300)
        ]
        
        updateController(nodes: nodes, miniMapSize: CGSize(width: 200, height: 150), contentPadding: 50)
        
        // Scale should be positive and reasonable
        XCTAssertGreaterThan(controller.scale, 0)
        XCTAssertLessThanOrEqual(controller.scale, 1.0)
    }
    
    // MARK: - Coordinate Conversion Tests
    
    func testCanvasToMiniMapConversion() {
        let nodes = [
            TestNode(id: UUID(), position: CGPoint(x: 0, y: 0), width: 400, height: 300)
        ]
        
        updateController(nodes: nodes, miniMapSize: CGSize(width: 200, height: 150), contentPadding: 50)
        
        // Test conversion of node top-left corner
        let canvasPoint = CanvasPoint(x: 0, y: 0)
        let miniMapPoint = controller.canvasToMiniMap(canvasPoint)
        
        // Should be offset and scaled
        XCTAssertGreaterThanOrEqual(miniMapPoint.x, 0)
        XCTAssertGreaterThanOrEqual(miniMapPoint.y, 0)
    }
    
    func testMiniMapToCanvasConversion() {
        let nodes = [
            TestNode(id: UUID(), position: CGPoint(x: 0, y: 0), width: 400, height: 300)
        ]
        
        updateController(nodes: nodes, miniMapSize: CGSize(width: 200, height: 150), contentPadding: 50)
        
        // Test round-trip conversion
        let originalCanvasPoint = CanvasPoint(x: 100, y: 150)
        let miniMapPoint = controller.canvasToMiniMap(originalCanvasPoint)
        let backToCanvasPoint = controller.miniMapToCanvas(miniMapPoint)
        
        XCTAssertEqual(backToCanvasPoint.x, originalCanvasPoint.x, accuracy: 0.1)
        XCTAssertEqual(backToCanvasPoint.y, originalCanvasPoint.y, accuracy: 0.1)
    }
    
    func testCanvasRectToMiniMapRectConversion() {
        let nodes = [
            TestNode(id: UUID(), position: CGPoint(x: 0, y: 0), width: 400, height: 300)
        ]
        
        updateController(nodes: nodes, miniMapSize: CGSize(width: 200, height: 150), contentPadding: 50)
        
        // Test rectangle conversion
        let canvasRect = CanvasRect(x: 0, y: 0, width: 100, height: 80)
        let miniMapRect = controller.canvasToMiniMap(canvasRect)
        
        // Size should be scaled
        XCTAssertEqual(miniMapRect.width, 100 * controller.scale, accuracy: 0.1)
        XCTAssertEqual(miniMapRect.height, 80 * controller.scale, accuracy: 0.1)
    }
    
    // MARK: - Viewport Indicator Tests
    
    func testViewportIndicatorAtIdentityTransform() {
        let nodes = [
            TestNode(id: UUID(), position: CGPoint(x: 0, y: 0), width: 400, height: 300),
            TestNode(id: UUID(), position: CGPoint(x: 500, y: 400), width: 200, height: 150)
        ]
        
        updateController(nodes: nodes, miniMapSize: CGSize(width: 200, height: 150), contentPadding: 50)
        
        // At identity transform (scale: 1.0, offset: 0,0)
        // Viewport should show area from (0,0) to (800, 600) in canvas space
        XCTAssertGreaterThan(controller.viewportIndicatorFrame.width, 0)
        XCTAssertGreaterThan(controller.viewportIndicatorFrame.height, 0)
    }
    
    func testViewportIndicatorAfterPan() {
        let nodes = [
            TestNode(id: UUID(), position: CGPoint(x: 0, y: 0), width: 400, height: 300)
        ]
        
        updateController(nodes: nodes, miniMapSize: CGSize(width: 200, height: 150), contentPadding: 50)
        
        let initialFrame = controller.viewportIndicatorFrame
        
        // Pan the viewport
        panZoomManager.pan(by: CGSize(width: 100, height: 50))
        controller.viewportRectCanvas = panZoomManager.viewportRectCanvas
        controller.forceUpdate()
        
        let afterPanFrame = controller.viewportIndicatorFrame
        
        // Viewport indicator should move
        XCTAssertNotEqual(initialFrame.origin.x, afterPanFrame.origin.x, accuracy: 0.1)
        XCTAssertNotEqual(initialFrame.origin.y, afterPanFrame.origin.y, accuracy: 0.1)
    }
    
    func testViewportIndicatorAfterZoom() {
        let nodes = [
            TestNode(id: UUID(), position: CGPoint(x: 0, y: 0), width: 400, height: 300)
        ]
        
        updateController(nodes: nodes, miniMapSize: CGSize(width: 200, height: 150), contentPadding: 50)
        
        let initialFrame = controller.viewportIndicatorFrame
        
        // Zoom in
        let center = CGPoint(x: 400, y: 300)
        panZoomManager.zoom(by: 2.0, at: center)
        controller.viewportRectCanvas = panZoomManager.viewportRectCanvas
        controller.forceUpdate()
        
        let afterZoomFrame = controller.viewportIndicatorFrame
        
        // Viewport indicator should become smaller (seeing less canvas area)
        XCTAssertLessThan(afterZoomFrame.width, initialFrame.width)
        XCTAssertLessThan(afterZoomFrame.height, initialFrame.height)
    }
    
    // MARK: - Node Bounds in MiniMap Tests
    
    func testNodeBoundsInMiniMap() {
        let node = TestNode(id: UUID(), position: CGPoint(x: 100, y: 100), width: 150, height: 100)
        let nodes = [node]
        
        updateController(nodes: nodes, miniMapSize: CGSize(width: 200, height: 150), contentPadding: 50)
        
        let canvasRect = CanvasRect(
            x: node.position.x,
            y: node.position.y,
            width: node.width,
            height: node.height
        )
        let miniMapBounds = controller.canvasToMiniMap(canvasRect)
        
        // Bounds should be scaled and translated correctly
        XCTAssertGreaterThan(miniMapBounds.width, 0)
        XCTAssertGreaterThan(miniMapBounds.height, 0)
        XCTAssertEqual(miniMapBounds.width, 150 * controller.scale, accuracy: 0.1)
        XCTAssertEqual(miniMapBounds.height, 100 * controller.scale, accuracy: 0.1)
    }
    
    // MARK: - State Management Tests
    
    func testBoundsNotRecalculatedForSameNodes() {
        let nodes = [
            TestNode(id: UUID(), position: CGPoint(x: 0, y: 0), width: 100, height: 80)
        ]
        
        updateController(nodes: nodes, miniMapSize: CGSize(width: 200, height: 150), contentPadding: 50)
        
        let initialBounds = controller.contentBounds
        let initialScale = controller.scale
        
        // Update with same nodes bounds
        let nodesBounds = calculateNodesBounds(nodes) ?? .zero
        controller.nodesBounds = nodesBounds
        
        // Bounds should remain the same (or very close)
        XCTAssertEqual(controller.contentBounds.origin.x, initialBounds.origin.x, accuracy: 0.1)
        XCTAssertEqual(controller.contentBounds.origin.y, initialBounds.origin.y, accuracy: 0.1)
        XCTAssertEqual(controller.scale, initialScale, accuracy: 0.01)
    }
    
    func testBoundsRecalculatedWhenNodesChange() {
        let initialNodes = [
            TestNode(id: UUID(), position: CGPoint(x: 1000, y: 1000), width: 100, height: 80)
        ]
        
        updateController(nodes: initialNodes, miniMapSize: CGSize(width: 200, height: 150), contentPadding: 50)
        
        let initialBounds = controller.contentBounds
        
        // Update with different nodes far away from viewport
        let newNodes = [
            TestNode(id: UUID(), position: CGPoint(x: 2000, y: 2000), width: 100, height: 80),
            TestNode(id: UUID(), position: CGPoint(x: 2200, y: 2150), width: 150, height: 100)
        ]
        
        let newNodesBounds = calculateNodesBounds(newNodes) ?? .zero
        controller.nodesBounds = newNodesBounds
        controller.forceUpdate()
        
        // Bounds should be recalculated and different
        XCTAssertNotEqual(controller.contentBounds.width, initialBounds.width, accuracy: 0.1)
    }
    
    // MARK: - Edge Cases Tests
    
    func testNegativeCoordinates() {
        let nodes = [
            TestNode(id: UUID(), position: CGPoint(x: -100, y: -50), width: 150, height: 100),
            TestNode(id: UUID(), position: CGPoint(x: 200, y: 100), width: 100, height: 80)
        ]
        
        updateController(nodes: nodes, miniMapSize: CGSize(width: 200, height: 150), contentPadding: 50)
        
        // Should handle negative coordinates correctly
        XCTAssertLessThan(controller.contentBounds.minX, 0)
        XCTAssertLessThan(controller.contentBounds.minY, 0)
    }
    
    func testExtremeZoomLevels() {
        let nodes = [
            TestNode(id: UUID(), position: CGPoint(x: 0, y: 0), width: 100, height: 80)
        ]
        
        updateController(nodes: nodes, miniMapSize: CGSize(width: 200, height: 150), contentPadding: 50)
        
        // Test extreme zoom in
        let center = CGPoint(x: 400, y: 300)
        panZoomManager.setZoom(4.0, at: center)
        controller.viewportRectCanvas = panZoomManager.viewportRectCanvas
        controller.forceUpdate()
        
        XCTAssertGreaterThan(controller.viewportIndicatorFrame.width, 0)
        XCTAssertGreaterThan(controller.viewportIndicatorFrame.height, 0)
        
        // Test extreme zoom out
        panZoomManager.setZoom(0.1, at: center)
        controller.viewportRectCanvas = panZoomManager.viewportRectCanvas
        controller.forceUpdate()
        
        XCTAssertGreaterThan(controller.viewportIndicatorFrame.width, 0)
        XCTAssertGreaterThan(controller.viewportIndicatorFrame.height, 0)
    }
    
    // MARK: - Interaction Tests
    
    func testCalculateNewViewportCenter() {
        let nodes = [
            TestNode(id: UUID(), position: CGPoint(x: 0, y: 0), width: 400, height: 300)
        ]
        
        updateController(nodes: nodes, miniMapSize: CGSize(width: 200, height: 150), contentPadding: 50)
        
        // Click at center of minimap
        let miniMapPoint = CGPoint(x: 100, y: 75)
        let canvasCenter = controller.calculateNewViewportCenter(from: miniMapPoint)
        
        // Should return valid canvas coordinates
        XCTAssertFalse(canvasCenter.x.isNaN)
        XCTAssertFalse(canvasCenter.y.isNaN)
    }
    
    func testCalculatePanDelta() {
        let nodes = [
            TestNode(id: UUID(), position: CGPoint(x: 0, y: 0), width: 400, height: 300)
        ]
        
        updateController(nodes: nodes, miniMapSize: CGSize(width: 200, height: 150), contentPadding: 50)
        
        // Drag from one point to another in minimap
        let startPoint = CGPoint(x: 50, y: 50)
        let endPoint = CGPoint(x: 100, y: 100)
        let mainScale = panZoomManager.transform.scale
        
        let panDelta = controller.calculatePanDelta(
            from: startPoint,
            to: endPoint,
            mainScale: mainScale
        )
        
        // Should return valid delta
        XCTAssertFalse(panDelta.width.isNaN)
        XCTAssertFalse(panDelta.height.isNaN)
    }
    
    // MARK: - Force Update Tests
    
    func testForceUpdateRecalculatesImmediately() {
        let nodes = [
            TestNode(id: UUID(), position: CGPoint(x: 1000, y: 1000), width: 100, height: 80)
        ]
        
        updateController(nodes: nodes, miniMapSize: CGSize(width: 200, height: 150), contentPadding: 50)
        
        let initialBounds = controller.contentBounds
        
        // Change nodes bounds significantly
        let newNodes = [
            TestNode(id: UUID(), position: CGPoint(x: 3000, y: 3000), width: 400, height: 300)
        ]
        let newNodesBounds = calculateNodesBounds(newNodes) ?? .zero
        controller.nodesBounds = newNodesBounds
        
        // Force update
        controller.forceUpdate()
        
        // Bounds should be immediately updated
        XCTAssertNotEqual(controller.contentBounds.width, initialBounds.width, accuracy: 0.1)
    }
}
