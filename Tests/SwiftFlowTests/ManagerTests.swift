//
//  ManagerTests.swift
//  SwiftFlowTests
//
//  Unit tests for managers.
//

import XCTest
@testable import SwiftFlow

@MainActor
final class ManagerTests: XCTestCase {
    
    // MARK: - SelectionManager Tests
    
    func testSelectNode() {
        let manager = SelectionManager()
        let nodeId = UUID()
        
        manager.selectNode(nodeId)
        
        XCTAssertTrue(manager.isNodeSelected(nodeId))
        XCTAssertEqual(manager.selectedNodes.count, 1)
    }
    
    func testSelectMultipleNodesAdditive() {
        let manager = SelectionManager()
        let node1 = UUID()
        let node2 = UUID()
        
        manager.selectNode(node1)
        manager.selectNode(node2, additive: true)
        
        XCTAssertTrue(manager.isNodeSelected(node1))
        XCTAssertTrue(manager.isNodeSelected(node2))
        XCTAssertEqual(manager.selectedNodes.count, 2)
    }
    
    func testSelectReplaces() {
        let manager = SelectionManager()
        let node1 = UUID()
        let node2 = UUID()
        
        manager.selectNode(node1)
        manager.selectNode(node2, additive: false)
        
        XCTAssertFalse(manager.isNodeSelected(node1))
        XCTAssertTrue(manager.isNodeSelected(node2))
        XCTAssertEqual(manager.selectedNodes.count, 1)
    }
    
    func testClearSelection() {
        let manager = SelectionManager()
        let nodeId = UUID()
        
        manager.selectNode(nodeId)
        manager.clearSelection()
        
        XCTAssertFalse(manager.isNodeSelected(nodeId))
        XCTAssertEqual(manager.selectedNodes.count, 0)
    }
    
    func testToggleSelection() {
        let manager = SelectionManager()
        let nodeId = UUID()
        
        manager.toggleNodeSelection(nodeId)
        XCTAssertTrue(manager.isNodeSelected(nodeId))
        
        manager.toggleNodeSelection(nodeId)
        XCTAssertFalse(manager.isNodeSelected(nodeId))
    }
    
    func testMultiSelectionDisabled() {
        let manager = SelectionManager(enableMultiSelection: false)
        let node1 = UUID()
        let node2 = UUID()
        
        manager.selectNode(node1)
        manager.selectNode(node2, additive: true) // Should still replace
        
        XCTAssertFalse(manager.isNodeSelected(node1))
        XCTAssertTrue(manager.isNodeSelected(node2))
    }
    
    // MARK: - PanZoomManager Tests
    
    func testPan() {
        let manager = PanZoomManager()
        
        manager.pan(by: CGSize(width: 50, height: 30))
        
        XCTAssertEqual(manager.transform.offset.x, 50, accuracy: 0.001)
        XCTAssertEqual(manager.transform.offset.y, 30, accuracy: 0.001)
    }
    
    func testZoom() {
        let manager = PanZoomManager()
        manager.viewportSize = CGSize(width: 800, height: 600)
        
        manager.zoom(by: 2.0, at: CGPoint(x: 400, y: 300))
        
        XCTAssertEqual(manager.transform.scale, 2.0, accuracy: 0.001)
    }
    
    func testZoomClamped() {
        let manager = PanZoomManager(minZoom: 0.5, maxZoom: 2.0)
        manager.viewportSize = CGSize(width: 800, height: 600)
        
        manager.zoom(by: 10.0, at: CGPoint(x: 400, y: 300))
        XCTAssertEqual(manager.transform.scale, 2.0, accuracy: 0.001)
        
        manager.zoom(by: 0.01, at: CGPoint(x: 400, y: 300))
        XCTAssertEqual(manager.transform.scale, 0.5, accuracy: 0.001)
    }
    
    func testReset() {
        let manager = PanZoomManager()
        
        manager.pan(by: CGSize(width: 100, height: 100))
        manager.setZoom(2.0)
        manager.reset()
        
        XCTAssertEqual(manager.transform.offset, .zero)
        XCTAssertEqual(manager.transform.scale, 1.0, accuracy: 0.001)
    }
    
    // MARK: - DragManager Tests
    
    func testStartDrag() {
        let manager = DragManager()
        let nodeId = UUID()
        let position = CGPoint(x: 100, y: 100)
        
        manager.startDrag(
            nodeIds: [nodeId],
            positions: [nodeId: position],
            at: position
        )
        
        XCTAssertTrue(manager.isDragging)
        XCTAssertNotNil(manager.dragState)
    }
    
    func testUpdateDrag() {
        let manager = DragManager(dragThreshold: 0)
        let nodeId = UUID()
        let startPosition = CGPoint(x: 100, y: 100)
        
        manager.startDrag(
            nodeIds: [nodeId],
            positions: [nodeId: startPosition],
            at: startPosition
        )
        
        manager.updateDrag(to: CGPoint(x: 150, y: 120))
        
        XCTAssertTrue(manager.hasMoved)
        
        let offset = manager.currentOffset(for: nodeId)
        XCTAssertEqual(offset.width, 50, accuracy: 0.001)
        XCTAssertEqual(offset.height, 20, accuracy: 0.001)
    }
    
    func testEndDrag() {
        let manager = DragManager(dragThreshold: 0)
        let nodeId = UUID()
        let startPosition = CGPoint(x: 100, y: 100)
        
        manager.startDrag(
            nodeIds: [nodeId],
            positions: [nodeId: startPosition],
            at: startPosition
        )
        
        manager.updateDrag(to: CGPoint(x: 150, y: 120))
        let finalPositions = manager.endDrag()
        
        XCTAssertFalse(manager.isDragging)
        XCTAssertNotNil(finalPositions)
        if let pos = finalPositions?[nodeId] {
            XCTAssertEqual(pos.x, 150, accuracy: 0.001)
            XCTAssertEqual(pos.y, 120, accuracy: 0.001)
        } else {
            XCTFail("Expected position for nodeId")
        }
    }
    
    func testSnapToGrid() {
        let manager = DragManager(snapToGrid: true, gridSize: 20, dragThreshold: 0)
        let nodeId = UUID()
        let startPosition = CGPoint(x: 100, y: 100)
        
        manager.startDrag(
            nodeIds: [nodeId],
            positions: [nodeId: startPosition],
            at: startPosition
        )
        
        // Move by 15, should snap to 20
        manager.updateDrag(to: CGPoint(x: 115, y: 105))
        let finalPositions = manager.endDrag()
        
        // Should snap to grid
        if let pos = finalPositions?[nodeId] {
            XCTAssertEqual(pos.x.truncatingRemainder(dividingBy: 20), 0, accuracy: 0.001)
        } else {
            XCTFail("Expected position for nodeId")
        }
    }
    
    // MARK: - ConnectionManager Tests
    
    func testStartConnection() {
        let manager = ConnectionManager()
        let nodeId = UUID()
        let portId = UUID()
        
        manager.startConnection(
            from: nodeId,
            portId: portId,
            at: CGPoint(x: 100, y: 100),
            portPosition: .right
        )
        
        XCTAssertTrue(manager.isConnecting)
        XCTAssertNotNil(manager.connectionInProgress)
    }
    
    func testUpdateConnection() {
        let manager = ConnectionManager()
        let nodeId = UUID()
        let portId = UUID()
        
        manager.startConnection(
            from: nodeId,
            portId: portId,
            at: CGPoint(x: 100, y: 100),
            portPosition: .right
        )
        
        manager.updateConnection(to: CGPoint(x: 200, y: 150))
        
        if let pos = manager.connectionInProgress?.currentPosition {
            XCTAssertEqual(pos.x, 200, accuracy: 0.001)
            XCTAssertEqual(pos.y, 150, accuracy: 0.001)
        } else {
            XCTFail("Expected connection in progress")
        }
    }
    
    func testCancelConnection() {
        let manager = ConnectionManager()
        let nodeId = UUID()
        let portId = UUID()
        
        manager.startConnection(
            from: nodeId,
            portId: portId,
            at: CGPoint(x: 100, y: 100),
            portPosition: .right
        )
        
        manager.cancelConnection()
        
        XCTAssertFalse(manager.isConnecting)
        XCTAssertNil(manager.connectionInProgress)
    }
}
