//
//  ControllerDataAccessTests.swift
//  SwiftFlowTests
//
//  Tests for CanvasController data access and coordinate conversion methods.
//

import XCTest
@testable import SwiftFlow

// MARK: - Test Node/Edge Types

struct TestNode: FlowNode, Codable {
    let id: UUID
    var position: CGPoint
    var width: CGFloat
    var height: CGFloat
    var parentId: UUID?
    var zIndex: Double
    
    var inputPorts: [any FlowPort] { [] }
    var outputPorts: [any FlowPort] { [] }
}

struct TestEdge: FlowEdge, Codable {
    let id: UUID
    var sourceNodeId: UUID
    var sourcePortId: UUID
    var targetNodeId: UUID
    var targetPortId: UUID
}

// MARK: - Data Access Tests

@MainActor
final class ControllerDataAccessTests: XCTestCase {
    
    var controller: CanvasController!
    var nodes: [TestNode] = []
    var edges: [TestEdge] = []
    
    override func setUp() async throws {
        controller = CanvasController()
        
        // Create test data
        let node1 = TestNode(
            id: UUID(),
            position: CGPoint(x: 100, y: 100),
            width: 120,
            height: 80,
            parentId: nil,
            zIndex: 0
        )
        
        let node2 = TestNode(
            id: UUID(),
            position: CGPoint(x: 300, y: 200),
            width: 120,
            height: 80,
            parentId: nil,
            zIndex: 0
        )
        
        nodes = [node1, node2]
        
        let edge1 = TestEdge(
            id: UUID(),
            sourceNodeId: node1.id,
            sourcePortId: UUID(),
            targetNodeId: node2.id,
            targetPortId: UUID()
        )
        
        edges = [edge1]
        
        // Set up environment
        let environment = CanvasEnvironment<TestNode, TestEdge>(
            getNodes: { self.nodes },
            getEdges: { self.edges },
            applyNodeEdits: { _ in },
            applyEdgeEdits: { _ in }
        )
        
        controller.setEnvironment(AnyCanvasEnvironment(environment))
    }
    
    // MARK: - getNodes Tests
    
    func testGetNodes() {
        let retrievedNodes = controller.getNodes()
        
        XCTAssertEqual(retrievedNodes.count, 2)
        XCTAssertEqual(retrievedNodes[0].id, nodes[0].id)
        XCTAssertEqual(retrievedNodes[1].id, nodes[1].id)
    }
    
    func testGetNodesEmptyWhenNoEnvironment() {
        let newController = CanvasController()
        let retrievedNodes = newController.getNodes()
        
        XCTAssertTrue(retrievedNodes.isEmpty)
    }
    
    // MARK: - getEdges Tests
    
    func testGetEdges() {
        let retrievedEdges = controller.getEdges()
        
        XCTAssertEqual(retrievedEdges.count, 1)
        XCTAssertEqual(retrievedEdges[0].id, edges[0].id)
    }
    
    func testGetEdgesEmptyWhenNoEnvironment() {
        let newController = CanvasController()
        let retrievedEdges = newController.getEdges()
        
        XCTAssertTrue(retrievedEdges.isEmpty)
    }
    
    // MARK: - getElements Tests
    
    func testGetElements() {
        let (retrievedNodes, retrievedEdges) = controller.getElements()
        
        XCTAssertEqual(retrievedNodes.count, 2)
        XCTAssertEqual(retrievedEdges.count, 1)
        XCTAssertEqual(retrievedNodes[0].id, nodes[0].id)
        XCTAssertEqual(retrievedEdges[0].id, edges[0].id)
    }
    
    // MARK: - getNode Tests
    
    func testGetNodeById() {
        let nodeId = nodes[0].id
        let retrievedNode = controller.getNode(id: nodeId)
        
        XCTAssertNotNil(retrievedNode)
        XCTAssertEqual(retrievedNode?.id, nodeId)
    }
    
    func testGetNodeByIdReturnsNilForNonexistent() {
        let nonexistentId = UUID()
        let retrievedNode = controller.getNode(id: nonexistentId)
        
        XCTAssertNil(retrievedNode)
    }
    
    // MARK: - getEdge Tests
    
    func testGetEdgeById() {
        let edgeId = edges[0].id
        let retrievedEdge = controller.getEdge(id: edgeId)
        
        XCTAssertNotNil(retrievedEdge)
        XCTAssertEqual(retrievedEdge?.id, edgeId)
    }
    
    func testGetEdgeByIdReturnsNilForNonexistent() {
        let nonexistentId = UUID()
        let retrievedEdge = controller.getEdge(id: nonexistentId)
        
        XCTAssertNil(retrievedEdge)
    }
    
    // MARK: - toObject Tests
    
    func testToObject() {
        // Set some transform state
        controller.perform(.setTransform(FlowTransform(
            offset: CGPoint(x: 100, y: 200),
            scale: 1.5
        )))
        
        // Select a node
        controller.perform(.select(nodeIds: [nodes[0].id], edgeIds: [], additive: false))
        
        let state = controller.toObject()
        
        // Verify viewport
        XCTAssertNotNil(state["viewport"])
        let viewport = state["viewport"] as! [String: Any]
        XCTAssertEqual(viewport["x"] as? CGFloat, 100)
        XCTAssertEqual(viewport["y"] as? CGFloat, 200)
        XCTAssertEqual(viewport["zoom"] as? CGFloat, 1.5)
        
        // Verify selection
        XCTAssertNotNil(state["selection"])
        let selection = state["selection"] as! [String: Any]
        let selectedNodes = selection["nodes"] as! [UUID]
        XCTAssertEqual(selectedNodes.count, 1)
        XCTAssertEqual(selectedNodes[0], nodes[0].id)
        
        // Verify counts
        XCTAssertEqual(state["nodeCount"] as? Int, 2)
        XCTAssertEqual(state["edgeCount"] as? Int, 1)
    }
    
    // MARK: - project/unproject Tests
    
    func testProjectCGPoint() {
        controller.perform(.setTransform(FlowTransform(
            offset: CGPoint(x: 50, y: 100),
            scale: 2.0
        )))
        
        let screenPoint = CGPoint(x: 250, y: 300)
        let canvasPoint = controller.project(screenPoint)
        
        // Expected: (250 - 50) / 2.0 = 100, (300 - 100) / 2.0 = 100
        XCTAssertEqual(canvasPoint.x, 100, accuracy: 0.001)
        XCTAssertEqual(canvasPoint.y, 100, accuracy: 0.001)
    }
    
    func testProjectScreenPoint() {
        controller.perform(.setTransform(FlowTransform(
            offset: CGPoint(x: 50, y: 100),
            scale: 2.0
        )))
        
        let screenPoint = ScreenPoint(x: 250, y: 300)
        let canvasPoint = controller.project(screenPoint)
        
        XCTAssertEqual(canvasPoint.x, 100, accuracy: 0.001)
        XCTAssertEqual(canvasPoint.y, 100, accuracy: 0.001)
    }
    
    func testUnprojectCGPoint() {
        controller.perform(.setTransform(FlowTransform(
            offset: CGPoint(x: 50, y: 100),
            scale: 2.0
        )))
        
        let canvasPoint = CGPoint(x: 100, y: 100)
        let screenPoint = controller.unproject(canvasPoint)
        
        // Expected: 100 * 2.0 + 50 = 250, 100 * 2.0 + 100 = 300
        XCTAssertEqual(screenPoint.x, 250, accuracy: 0.001)
        XCTAssertEqual(screenPoint.y, 300, accuracy: 0.001)
    }
    
    func testUnprojectCanvasPoint() {
        controller.perform(.setTransform(FlowTransform(
            offset: CGPoint(x: 50, y: 100),
            scale: 2.0
        )))
        
        let canvasPoint = CanvasPoint(x: 100, y: 100)
        let screenPoint = controller.unproject(canvasPoint)
        
        XCTAssertEqual(screenPoint.x, 250, accuracy: 0.001)
        XCTAssertEqual(screenPoint.y, 300, accuracy: 0.001)
    }
    
    func testProjectUnprojectRoundtrip() {
        controller.perform(.setTransform(FlowTransform(
            offset: CGPoint(x: 75, y: 125),
            scale: 1.5
        )))
        
        let originalScreen = CGPoint(x: 400, y: 500)
        let canvas = controller.project(originalScreen)
        let backToScreen = controller.unproject(canvas)
        
        XCTAssertEqual(originalScreen.x, backToScreen.x, accuracy: 0.001)
        XCTAssertEqual(originalScreen.y, backToScreen.y, accuracy: 0.001)
    }
    
    func testProjectWithIdentityTransform() {
        // With identity transform, project should return same coordinates
        let screenPoint = CGPoint(x: 123, y: 456)
        let canvasPoint = controller.project(screenPoint)
        
        XCTAssertEqual(canvasPoint.x, screenPoint.x, accuracy: 0.001)
        XCTAssertEqual(canvasPoint.y, screenPoint.y, accuracy: 0.001)
    }
}
