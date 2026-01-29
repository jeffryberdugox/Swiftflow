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
    
    private var viewModel: MiniMapViewModel!
    private var panZoomManager: PanZoomManager!
    
    override func setUp() async throws {
        viewModel = MiniMapViewModel()
        panZoomManager = PanZoomManager(minZoom: 0.1, maxZoom: 4.0)
        panZoomManager.viewportSize = CGSize(width: 800, height: 600)
    }
    
    // MARK: - Bounds Calculation Tests
    
    func testBoundsCalculationWithMultipleNodes() {
        let nodes = [
            TestNode(id: UUID(), position: CGPoint(x: 0, y: 0), width: 100, height: 80),
            TestNode(id: UUID(), position: CGPoint(x: 200, y: 100), width: 150, height: 100),
            TestNode(id: UUID(), position: CGPoint(x: 400, y: 200), width: 120, height: 90)
        ]
        
        let miniMapSize = CGSize(width: 200, height: 150)
        let contentPadding: CGFloat = 50
        
        viewModel.updateAll(
            nodes: nodes,
            panZoomManager: panZoomManager,
            miniMapSize: miniMapSize,
            contentPadding: contentPadding
        )
        
        // Expected bounds: x: -50, y: -50, width: 670, height: 390
        // (0 to 520 with 50 padding on each side)
        XCTAssertEqual(viewModel.contentBounds.minX, -50, accuracy: 0.1)
        XCTAssertEqual(viewModel.contentBounds.minY, -50, accuracy: 0.1)
        XCTAssertEqual(viewModel.contentBounds.width, 620, accuracy: 0.1)
        XCTAssertEqual(viewModel.contentBounds.height, 390, accuracy: 0.1)
    }
    
    func testBoundsCalculationWithSingleNode() {
        let nodes = [
            TestNode(id: UUID(), position: CGPoint(x: 100, y: 100), width: 150, height: 100)
        ]
        
        let miniMapSize = CGSize(width: 200, height: 150)
        let contentPadding: CGFloat = 50
        
        viewModel.updateAll(
            nodes: nodes,
            panZoomManager: panZoomManager,
            miniMapSize: miniMapSize,
            contentPadding: contentPadding
        )
        
        // Expected bounds: x: 50, y: 50, width: 250, height: 200
        XCTAssertEqual(viewModel.contentBounds.minX, 50, accuracy: 0.1)
        XCTAssertEqual(viewModel.contentBounds.minY, 50, accuracy: 0.1)
        XCTAssertEqual(viewModel.contentBounds.width, 250, accuracy: 0.1)
        XCTAssertEqual(viewModel.contentBounds.height, 200, accuracy: 0.1)
    }
    
    func testBoundsCalculationWithNoNodes() {
        let nodes: [TestNode] = []
        
        let miniMapSize = CGSize(width: 200, height: 150)
        let contentPadding: CGFloat = 50
        
        viewModel.updateAll(
            nodes: nodes,
            panZoomManager: panZoomManager,
            miniMapSize: miniMapSize,
            contentPadding: contentPadding
        )
        
        // Should have default bounds
        XCTAssertEqual(viewModel.contentBounds.width, 100, accuracy: 0.1)
        XCTAssertEqual(viewModel.contentBounds.height, 100, accuracy: 0.1)
    }
    
    // MARK: - Scale Calculation Tests
    
    func testScaleCalculationFitsContent() {
        let nodes = [
            TestNode(id: UUID(), position: CGPoint(x: 0, y: 0), width: 400, height: 300)
        ]
        
        let miniMapSize = CGSize(width: 200, height: 150)
        let contentPadding: CGFloat = 50
        
        viewModel.updateAll(
            nodes: nodes,
            panZoomManager: panZoomManager,
            miniMapSize: miniMapSize,
            contentPadding: contentPadding
        )
        
        // Content bounds: -50 to 450 (width: 500), -50 to 350 (height: 400)
        // Scale should be min(200/500, 150/400) = min(0.4, 0.375) = 0.375
        XCTAssertEqual(viewModel.miniMapScale, 0.375, accuracy: 0.01)
    }
    
    // MARK: - Coordinate Conversion Tests
    
    func testCanvasToMiniMapConversion() {
        let nodes = [
            TestNode(id: UUID(), position: CGPoint(x: 0, y: 0), width: 400, height: 300)
        ]
        
        let miniMapSize = CGSize(width: 200, height: 150)
        let contentPadding: CGFloat = 50
        
        viewModel.updateAll(
            nodes: nodes,
            panZoomManager: panZoomManager,
            miniMapSize: miniMapSize,
            contentPadding: contentPadding
        )
        
        // Test conversion of node top-left corner
        let canvasPoint = CGPoint(x: 0, y: 0)
        let miniMapPoint = viewModel.canvasToMiniMap(canvasPoint)
        
        // Should be offset by contentBounds.minX/minY and scaled
        XCTAssertGreaterThan(miniMapPoint.x, 0)
        XCTAssertGreaterThan(miniMapPoint.y, 0)
    }
    
    func testMiniMapToCanvasConversion() {
        let nodes = [
            TestNode(id: UUID(), position: CGPoint(x: 0, y: 0), width: 400, height: 300)
        ]
        
        let miniMapSize = CGSize(width: 200, height: 150)
        let contentPadding: CGFloat = 50
        
        viewModel.updateAll(
            nodes: nodes,
            panZoomManager: panZoomManager,
            miniMapSize: miniMapSize,
            contentPadding: contentPadding
        )
        
        // Test round-trip conversion
        let originalCanvasPoint = CGPoint(x: 100, y: 150)
        let miniMapPoint = viewModel.canvasToMiniMap(originalCanvasPoint)
        let backToCanvasPoint = viewModel.miniMapToCanvas(miniMapPoint)
        
        XCTAssertEqual(backToCanvasPoint.x, originalCanvasPoint.x, accuracy: 0.1)
        XCTAssertEqual(backToCanvasPoint.y, originalCanvasPoint.y, accuracy: 0.1)
    }
    
    func testCanvasRectToMiniMapRectConversion() {
        let nodes = [
            TestNode(id: UUID(), position: CGPoint(x: 0, y: 0), width: 400, height: 300)
        ]
        
        let miniMapSize = CGSize(width: 200, height: 150)
        let contentPadding: CGFloat = 50
        
        viewModel.updateAll(
            nodes: nodes,
            panZoomManager: panZoomManager,
            miniMapSize: miniMapSize,
            contentPadding: contentPadding
        )
        
        // Test rectangle conversion
        let canvasRect = CGRect(x: 0, y: 0, width: 100, height: 80)
        let miniMapRect = viewModel.canvasRectToMiniMapRect(canvasRect)
        
        // Size should be scaled by miniMapScale
        XCTAssertEqual(miniMapRect.width, 100 * viewModel.miniMapScale, accuracy: 0.1)
        XCTAssertEqual(miniMapRect.height, 80 * viewModel.miniMapScale, accuracy: 0.1)
    }
    
    // MARK: - Viewport Indicator Tests
    
    func testViewportIndicatorAtIdentityTransform() {
        let nodes = [
            TestNode(id: UUID(), position: CGPoint(x: 0, y: 0), width: 400, height: 300),
            TestNode(id: UUID(), position: CGPoint(x: 500, y: 400), width: 200, height: 150)
        ]
        
        let miniMapSize = CGSize(width: 200, height: 150)
        let contentPadding: CGFloat = 50
        
        viewModel.updateAll(
            nodes: nodes,
            panZoomManager: panZoomManager,
            miniMapSize: miniMapSize,
            contentPadding: contentPadding
        )
        
        // At identity transform (scale: 1.0, offset: 0,0)
        // Viewport should show area from (0,0) to (800, 600) in canvas space
        XCTAssertGreaterThan(viewModel.viewportIndicatorRect.width, 0)
        XCTAssertGreaterThan(viewModel.viewportIndicatorRect.height, 0)
    }
    
    func testViewportIndicatorAfterPan() {
        let nodes = [
            TestNode(id: UUID(), position: CGPoint(x: 0, y: 0), width: 400, height: 300)
        ]
        
        let miniMapSize = CGSize(width: 200, height: 150)
        let contentPadding: CGFloat = 50
        
        viewModel.updateAll(
            nodes: nodes,
            panZoomManager: panZoomManager,
            miniMapSize: miniMapSize,
            contentPadding: contentPadding
        )
        
        let initialRect = viewModel.viewportIndicatorRect
        
        // Pan the viewport
        panZoomManager.pan(by: CGSize(width: 100, height: 50))
        viewModel.updateViewportIndicator(panZoomManager: panZoomManager)
        
        let afterPanRect = viewModel.viewportIndicatorRect
        
        // Viewport indicator should move
        XCTAssertNotEqual(initialRect.origin.x, afterPanRect.origin.x, accuracy: 0.1)
        XCTAssertNotEqual(initialRect.origin.y, afterPanRect.origin.y, accuracy: 0.1)
    }
    
    func testViewportIndicatorAfterZoom() {
        let nodes = [
            TestNode(id: UUID(), position: CGPoint(x: 0, y: 0), width: 400, height: 300)
        ]
        
        let miniMapSize = CGSize(width: 200, height: 150)
        let contentPadding: CGFloat = 50
        
        viewModel.updateAll(
            nodes: nodes,
            panZoomManager: panZoomManager,
            miniMapSize: miniMapSize,
            contentPadding: contentPadding
        )
        
        let initialRect = viewModel.viewportIndicatorRect
        
        // Zoom in
        let center = CGPoint(x: 400, y: 300)
        panZoomManager.zoom(by: 2.0, at: center)
        viewModel.updateViewportIndicator(panZoomManager: panZoomManager)
        
        let afterZoomRect = viewModel.viewportIndicatorRect
        
        // Viewport indicator should become smaller (seeing less canvas area)
        XCTAssertLessThan(afterZoomRect.width, initialRect.width)
        XCTAssertLessThan(afterZoomRect.height, initialRect.height)
    }
    
    // MARK: - Node Bounds in MiniMap Tests
    
    func testNodeBoundsInMiniMap() {
        let node = TestNode(id: UUID(), position: CGPoint(x: 100, y: 100), width: 150, height: 100)
        let nodes = [node]
        
        let miniMapSize = CGSize(width: 200, height: 150)
        let contentPadding: CGFloat = 50
        
        viewModel.updateAll(
            nodes: nodes,
            panZoomManager: panZoomManager,
            miniMapSize: miniMapSize,
            contentPadding: contentPadding
        )
        
        let miniMapBounds = viewModel.nodeBoundsInMiniMap(node)
        
        // Bounds should be scaled and translated correctly
        XCTAssertGreaterThan(miniMapBounds.width, 0)
        XCTAssertGreaterThan(miniMapBounds.height, 0)
        XCTAssertEqual(miniMapBounds.width, 150 * viewModel.miniMapScale, accuracy: 0.1)
        XCTAssertEqual(miniMapBounds.height, 100 * viewModel.miniMapScale, accuracy: 0.1)
    }
    
    // MARK: - Caching Tests
    
    func testBoundsNotRecalculatedForSameNodes() {
        let nodes = [
            TestNode(id: UUID(), position: CGPoint(x: 0, y: 0), width: 100, height: 80)
        ]
        
        let miniMapSize = CGSize(width: 200, height: 150)
        let contentPadding: CGFloat = 50
        
        viewModel.updateAll(
            nodes: nodes,
            panZoomManager: panZoomManager,
            miniMapSize: miniMapSize,
            contentPadding: contentPadding
        )
        
        let initialBounds = viewModel.contentBounds
        let initialScale = viewModel.miniMapScale
        
        // Update with same nodes
        viewModel.updateBounds(nodes: nodes)
        
        // Should be cached, not recalculated
        XCTAssertEqual(viewModel.contentBounds, initialBounds)
        XCTAssertEqual(viewModel.miniMapScale, initialScale)
    }
    
    func testBoundsRecalculatedWhenNodesChange() {
        let initialNodes = [
            TestNode(id: UUID(), position: CGPoint(x: 0, y: 0), width: 100, height: 80)
        ]
        
        let miniMapSize = CGSize(width: 200, height: 150)
        let contentPadding: CGFloat = 50
        
        viewModel.updateAll(
            nodes: initialNodes,
            panZoomManager: panZoomManager,
            miniMapSize: miniMapSize,
            contentPadding: contentPadding
        )
        
        let initialBounds = viewModel.contentBounds
        
        // Update with different nodes
        let newNodes = [
            TestNode(id: UUID(), position: CGPoint(x: 0, y: 0), width: 100, height: 80),
            TestNode(id: UUID(), position: CGPoint(x: 200, y: 150), width: 150, height: 100)
        ]
        viewModel.updateBounds(nodes: newNodes)
        
        // Bounds should be recalculated
        XCTAssertNotEqual(viewModel.contentBounds, initialBounds)
    }
    
    // MARK: - Edge Cases Tests
    
    func testNegativeCoordinates() {
        let nodes = [
            TestNode(id: UUID(), position: CGPoint(x: -100, y: -50), width: 150, height: 100),
            TestNode(id: UUID(), position: CGPoint(x: 200, y: 100), width: 100, height: 80)
        ]
        
        let miniMapSize = CGSize(width: 200, height: 150)
        let contentPadding: CGFloat = 50
        
        viewModel.updateAll(
            nodes: nodes,
            panZoomManager: panZoomManager,
            miniMapSize: miniMapSize,
            contentPadding: contentPadding
        )
        
        // Should handle negative coordinates correctly
        XCTAssertLessThan(viewModel.contentBounds.minX, 0)
        XCTAssertLessThan(viewModel.contentBounds.minY, 0)
    }
    
    func testExtremeZoomLevels() {
        let nodes = [
            TestNode(id: UUID(), position: CGPoint(x: 0, y: 0), width: 100, height: 80)
        ]
        
        let miniMapSize = CGSize(width: 200, height: 150)
        let contentPadding: CGFloat = 50
        
        viewModel.updateAll(
            nodes: nodes,
            panZoomManager: panZoomManager,
            miniMapSize: miniMapSize,
            contentPadding: contentPadding
        )
        
        // Test extreme zoom in
        let center = CGPoint(x: 400, y: 300)
        panZoomManager.setZoom(4.0, at: center)
        viewModel.updateViewportIndicator(panZoomManager: panZoomManager)
        
        XCTAssertGreaterThan(viewModel.viewportIndicatorRect.width, 0)
        XCTAssertGreaterThan(viewModel.viewportIndicatorRect.height, 0)
        
        // Test extreme zoom out
        panZoomManager.setZoom(0.1, at: center)
        viewModel.updateViewportIndicator(panZoomManager: panZoomManager)
        
        XCTAssertGreaterThan(viewModel.viewportIndicatorRect.width, 0)
        XCTAssertGreaterThan(viewModel.viewportIndicatorRect.height, 0)
    }
}
