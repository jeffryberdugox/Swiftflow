//
//  PathCalculatorTests.swift
//  SwiftFlowTests
//
//  Unit tests for path calculators.
//

import XCTest
@testable import SwiftFlow

final class PathCalculatorTests: XCTestCase {
    
    // MARK: - Bezier Path Tests
    
    func testBezierPathCreatesPath() {
        let calculator = BezierPathCalculator()
        
        let result = calculator.calculatePath(
            from: CGPoint(x: 0, y: 0),
            to: CGPoint(x: 100, y: 100),
            sourcePosition: .right,
            targetPosition: .left
        )
        
        XCTAssertFalse(result.path.isEmpty)
    }
    
    func testBezierPathLabelPosition() {
        let calculator = BezierPathCalculator()
        
        let result = calculator.calculatePath(
            from: CGPoint(x: 0, y: 0),
            to: CGPoint(x: 100, y: 0),
            sourcePosition: .right,
            targetPosition: .left
        )
        
        // Label should be roughly in the middle
        XCTAssertGreaterThan(result.labelX, 0)
        XCTAssertLessThan(result.labelX, 100)
    }
    
    func testBezierPathDifferentCurvatures() {
        let lowCurvature = BezierPathCalculator(curvature: 0.1)
        let highCurvature = BezierPathCalculator(curvature: 0.5)
        
        let source = CGPoint(x: 0, y: 0)
        let target = CGPoint(x: 100, y: 100)
        
        let lowResult = lowCurvature.calculatePath(
            from: source,
            to: target,
            sourcePosition: .right,
            targetPosition: .left
        )
        
        let highResult = highCurvature.calculatePath(
            from: source,
            to: target,
            sourcePosition: .right,
            targetPosition: .left
        )
        
        // Both should produce valid paths
        XCTAssertFalse(lowResult.path.isEmpty)
        XCTAssertFalse(highResult.path.isEmpty)
    }
    
    // MARK: - Straight Path Tests
    
    func testStraightPathCreatesPath() {
        let calculator = StraightPathCalculator()
        
        let result = calculator.calculatePath(
            from: CGPoint(x: 0, y: 0),
            to: CGPoint(x: 100, y: 100),
            sourcePosition: .right,
            targetPosition: .left
        )
        
        XCTAssertFalse(result.path.isEmpty)
    }
    
    func testStraightPathLabelAtCenter() {
        let calculator = StraightPathCalculator()
        
        let result = calculator.calculatePath(
            from: CGPoint(x: 0, y: 0),
            to: CGPoint(x: 100, y: 0),
            sourcePosition: .right,
            targetPosition: .left
        )
        
        // Label should be at the midpoint
        XCTAssertEqual(result.labelX, 50, accuracy: 0.001)
        XCTAssertEqual(result.labelY, 0, accuracy: 0.001)
    }
    
    // MARK: - Smooth Step Path Tests
    
    func testSmoothStepPathCreatesPath() {
        let calculator = SmoothStepPathCalculator()
        
        let result = calculator.calculatePath(
            from: CGPoint(x: 0, y: 0),
            to: CGPoint(x: 100, y: 100),
            sourcePosition: .right,
            targetPosition: .left
        )
        
        XCTAssertFalse(result.path.isEmpty)
    }
    
    func testSmoothStepPathWithDifferentSettings() {
        let calculator = SmoothStepPathCalculator(
            borderRadius: 10,
            offset: 30,
            stepPosition: 0.3
        )
        
        let result = calculator.calculatePath(
            from: CGPoint(x: 0, y: 0),
            to: CGPoint(x: 100, y: 100),
            sourcePosition: .bottom,
            targetPosition: .top
        )
        
        XCTAssertFalse(result.path.isEmpty)
    }
    
    // MARK: - Port Position Tests
    
    func testAllPortPositions() {
        let calculator = BezierPathCalculator()
        let positions: [PortPosition] = [.top, .bottom, .left, .right]
        
        for sourcePos in positions {
            for targetPos in positions {
                let result = calculator.calculatePath(
                    from: CGPoint(x: 0, y: 0),
                    to: CGPoint(x: 100, y: 100),
                    sourcePosition: sourcePos,
                    targetPosition: targetPos
                )
                
                XCTAssertFalse(result.path.isEmpty, "Path should not be empty for \(sourcePos) -> \(targetPos)")
            }
        }
    }
}
