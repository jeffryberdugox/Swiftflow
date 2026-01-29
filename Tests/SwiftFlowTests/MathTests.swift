//
//  MathTests.swift
//  SwiftFlowTests
//
//  Unit tests for math utilities.
//

import XCTest
@testable import SwiftFlow

final class MathTests: XCTestCase {
    
    // MARK: - FlowTransform Tests
    
    func testScreenToCanvas() {
        let transform = FlowTransform(offset: CGPoint(x: 100, y: 50), scale: 2.0)
        let screenPoint = CGPoint(x: 200, y: 150)
        
        let canvasPoint = transform.screenToCanvas(screenPoint)
        
        // (200 - 100) / 2.0 = 50
        // (150 - 50) / 2.0 = 50
        XCTAssertEqual(canvasPoint.x, 50, accuracy: 0.001)
        XCTAssertEqual(canvasPoint.y, 50, accuracy: 0.001)
    }
    
    func testCanvasToScreen() {
        let transform = FlowTransform(offset: CGPoint(x: 100, y: 50), scale: 2.0)
        let canvasPoint = CGPoint(x: 50, y: 50)
        
        let screenPoint = transform.canvasToScreen(canvasPoint)
        
        // 50 * 2.0 + 100 = 200
        // 50 * 2.0 + 50 = 150
        XCTAssertEqual(screenPoint.x, 200, accuracy: 0.001)
        XCTAssertEqual(screenPoint.y, 150, accuracy: 0.001)
    }
    
    func testTransformRoundTrip() {
        let transform = FlowTransform(offset: CGPoint(x: 100, y: 50), scale: 2.0)
        let originalPoint = CGPoint(x: 123, y: 456)
        
        let canvasPoint = transform.screenToCanvas(originalPoint)
        let backToScreen = transform.canvasToScreen(canvasPoint)
        
        XCTAssertEqual(backToScreen.x, originalPoint.x, accuracy: 0.001)
        XCTAssertEqual(backToScreen.y, originalPoint.y, accuracy: 0.001)
    }
    
    func testPanned() {
        let transform = FlowTransform(offset: CGPoint(x: 100, y: 50), scale: 1.0)
        let newTransform = transform.panned(by: CGSize(width: 20, height: 30))
        
        XCTAssertEqual(newTransform.offset.x, 120, accuracy: 0.001)
        XCTAssertEqual(newTransform.offset.y, 80, accuracy: 0.001)
        XCTAssertEqual(newTransform.scale, 1.0, accuracy: 0.001)
    }
    
    func testZoomed() {
        let transform = FlowTransform(offset: .zero, scale: 1.0)
        let center = CGPoint(x: 100, y: 100)
        
        let zoomedIn = transform.zoomed(by: 2.0, at: center)
        
        XCTAssertEqual(zoomedIn.scale, 2.0, accuracy: 0.001)
    }
    
    func testZoomClamping() {
        let transform = FlowTransform(offset: .zero, scale: 1.0)
        let center = CGPoint(x: 100, y: 100)
        
        let zoomedWayIn = transform.zoomed(by: 100.0, at: center, minScale: 0.1, maxScale: 4.0)
        let zoomedWayOut = transform.zoomed(by: 0.001, at: center, minScale: 0.1, maxScale: 4.0)
        
        XCTAssertEqual(zoomedWayIn.scale, 4.0, accuracy: 0.001)
        XCTAssertEqual(zoomedWayOut.scale, 0.1, accuracy: 0.001)
    }
    
    // MARK: - SnapGrid Tests
    
    func testSnapToGrid() {
        let grid = SnapGrid(size: 20)
        
        let point1 = grid.snap(CGPoint(x: 15, y: 25))
        XCTAssertEqual(point1.x, 20, accuracy: 0.001)
        XCTAssertEqual(point1.y, 20, accuracy: 0.001)
        
        let point2 = grid.snap(CGPoint(x: 5, y: 5))
        XCTAssertEqual(point2.x, 0, accuracy: 0.001)
        XCTAssertEqual(point2.y, 0, accuracy: 0.001)
        
        let point3 = grid.snap(CGPoint(x: 30, y: 30))
        XCTAssertEqual(point3.x, 40, accuracy: 0.001)
        XCTAssertEqual(point3.y, 40, accuracy: 0.001)
    }
    
    func testSnapOffset() {
        let grid = SnapGrid(size: 20)
        let point = CGPoint(x: 15, y: 25)
        
        let offset = grid.snapOffset(for: point)
        
        // Snapped would be (20, 20), so offset is (5, -5)
        XCTAssertEqual(offset.width, 5, accuracy: 0.001)
        XCTAssertEqual(offset.height, -5, accuracy: 0.001)
    }
    
    // MARK: - Bounds Calculation Tests
    
    func testClamp() {
        XCTAssertEqual(clamp(5, min: 0, max: 10), 5)
        XCTAssertEqual(clamp(-5, min: 0, max: 10), 0)
        XCTAssertEqual(clamp(15, min: 0, max: 10), 10)
    }
    
    func testGetOverlappingArea() {
        let rect1 = CGRect(x: 0, y: 0, width: 100, height: 100)
        let rect2 = CGRect(x: 50, y: 50, width: 100, height: 100)
        
        let area = getOverlappingArea(rect1, rect2)
        
        // Overlap is 50x50 = 2500
        XCTAssertEqual(area, 2500, accuracy: 0.001)
    }
    
    func testNoOverlap() {
        let rect1 = CGRect(x: 0, y: 0, width: 50, height: 50)
        let rect2 = CGRect(x: 100, y: 100, width: 50, height: 50)
        
        let area = getOverlappingArea(rect1, rect2)
        
        XCTAssertEqual(area, 0, accuracy: 0.001)
    }
    
    // MARK: - Box Tests
    
    func testBoxFromRect() {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 50)
        let box = Box(rect: rect)
        
        XCTAssertEqual(box.x, 10)
        XCTAssertEqual(box.y, 20)
        XCTAssertEqual(box.x2, 110)
        XCTAssertEqual(box.y2, 70)
    }
    
    func testBoxToRect() {
        let box = Box(x: 10, y: 20, x2: 110, y2: 70)
        let rect = box.rect
        
        XCTAssertEqual(rect.origin.x, 10)
        XCTAssertEqual(rect.origin.y, 20)
        XCTAssertEqual(rect.width, 100)
        XCTAssertEqual(rect.height, 50)
    }
}
