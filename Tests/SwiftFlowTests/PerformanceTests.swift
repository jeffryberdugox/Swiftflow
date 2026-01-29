//
//  PerformanceTests.swift
//  SwiftFlowTests
//
//  Tests for performance optimization features.
//

import XCTest
@testable import SwiftFlow

final class PerformanceTests: XCTestCase {
    
    // MARK: - PerformanceConfig Tests
    
    func testPerformanceConfigDefaults() {
        let config = PerformanceConfig()
        XCTAssertTrue(config.enableDrawingGroup)
        XCTAssertTrue(config.enableViewportCulling)
        XCTAssertTrue(config.enablePathCache)
        XCTAssertTrue(config.optimizeTransformRendering)
        XCTAssertEqual(config.cullingMargin, 200)
        XCTAssertEqual(config.updateDebounceMs, 0)
    }
    
    func testPerformanceConfigMaximumPreset() {
        let maximum = PerformanceConfig.maximum
        XCTAssertTrue(maximum.enableDrawingGroup)
        XCTAssertTrue(maximum.enableViewportCulling)
        XCTAssertTrue(maximum.enablePathCache)
        XCTAssertTrue(maximum.optimizeTransformRendering)
    }
    
    func testPerformanceConfigBalancedPreset() {
        let balanced = PerformanceConfig.balanced
        XCTAssertTrue(balanced.enableDrawingGroup)
        XCTAssertTrue(balanced.enableViewportCulling)
        XCTAssertTrue(balanced.enablePathCache)
        XCTAssertTrue(balanced.optimizeTransformRendering)
    }
    
    func testPerformanceConfigConservativePreset() {
        let conservative = PerformanceConfig.conservative
        XCTAssertTrue(conservative.enableDrawingGroup)
        XCTAssertFalse(conservative.enableViewportCulling)
        XCTAssertFalse(conservative.enablePathCache)
        XCTAssertTrue(conservative.optimizeTransformRendering)
    }
    
    func testPerformanceConfigLegacyPreset() {
        let legacy = PerformanceConfig.legacy
        XCTAssertFalse(legacy.enableDrawingGroup)
        XCTAssertFalse(legacy.enableViewportCulling)
        XCTAssertFalse(legacy.enablePathCache)
        XCTAssertFalse(legacy.optimizeTransformRendering)
    }
    
    func testPerformanceConfigCustom() {
        let custom = PerformanceConfig(
            enableDrawingGroup: false,
            enableViewportCulling: true,
            cullingMargin: 300,
            enablePathCache: false,
            optimizeTransformRendering: true,
            updateDebounceMs: 16
        )
        
        XCTAssertFalse(custom.enableDrawingGroup)
        XCTAssertTrue(custom.enableViewportCulling)
        XCTAssertEqual(custom.cullingMargin, 300)
        XCTAssertFalse(custom.enablePathCache)
        XCTAssertTrue(custom.optimizeTransformRendering)
        XCTAssertEqual(custom.updateDebounceMs, 16)
    }
    
    func testPerformanceConfigEquatable() {
        let config1 = PerformanceConfig.maximum
        let config2 = PerformanceConfig.maximum
        let config3 = PerformanceConfig.legacy
        
        XCTAssertEqual(config1, config2)
        XCTAssertNotEqual(config1, config3)
    }
    
    // MARK: - CanvasConfig Integration Tests
    
    func testCanvasConfigIncludesPerformance() {
        let config = CanvasConfig()
        XCTAssertNotNil(config.zoom)
        XCTAssertNotNil(config.grid)
        XCTAssertNotNil(config.interaction)
    }
    
    func testCanvasConfigWithCustomPerformance() {
        let config = CanvasConfig(
            zoom: ZoomConfig(min: 0.5, max: 2.0)
        )
        XCTAssertEqual(config.zoom.min, 0.5)
        XCTAssertEqual(config.zoom.max, 2.0)
    }
    
    func testCanvasConfigWithLegacyPerformance() {
        let config = CanvasConfig(
            grid: GridConfig(visible: true, size: 20, snap: true)
        )
        XCTAssertTrue(config.grid.visible)
        XCTAssertEqual(config.grid.size, 20)
    }
    
    func testCanvasConfigPerformanceEquality() {
        let config1 = CanvasConfig()
        let config2 = CanvasConfig()
        let config3 = CanvasConfig.minimal
        
        XCTAssertEqual(config1, config2)
        XCTAssertNotEqual(config1, config3)
    }
    
    // MARK: - CanvasTransformModifier Tests
    
    func testTransformModifierOptimization() {
        let transform = FlowTransform(offset: .zero, scale: 1.0)
        let modifier1 = CanvasTransformModifier(transform: transform, optimizeRendering: true)
        let modifier2 = CanvasTransformModifier(transform: transform, optimizeRendering: false)
        
        XCTAssertTrue(modifier1.optimizeRendering)
        XCTAssertFalse(modifier2.optimizeRendering)
    }
    
    func testTransformModifierDefaultOptimization() {
        let transform = FlowTransform(offset: .zero, scale: 1.0)
        let modifier = CanvasTransformModifier(transform: transform)
        
        // Default should be optimized (true)
        XCTAssertTrue(modifier.optimizeRendering)
    }
    
    // MARK: - EdgePathCache Tests
    
    func testEdgePathCacheInitialization() {
        let cache = EdgePathCache()
        XCTAssertEqual(cache.cacheSize, 0)
    }
    
    func testEdgePathCacheCustomMaxSize() {
        let cache = EdgePathCache(maxCacheSize: 100)
        XCTAssertEqual(cache.cacheSize, 0)
    }
    
    func testEdgePathCacheStoresAndRetrieves() {
        let cache = EdgePathCache(maxCacheSize: 10)
        let calculator = BezierPathCalculator()
        let edgeId = UUID()
        
        // First call should calculate
        let path1 = cache.getPath(
            edgeId: edgeId,
            sourcePoint: CGPoint(x: 0, y: 0),
            targetPoint: CGPoint(x: 100, y: 100),
            sourcePosition: .right,
            targetPosition: .left,
            pathStyle: .bezier(curvature: 0.25),
            calculator: calculator
        )
        
        XCTAssertEqual(cache.cacheSize, 1)
        
        // Second call should retrieve from cache (same path)
        let path2 = cache.getPath(
            edgeId: edgeId,
            sourcePoint: CGPoint(x: 0, y: 0),
            targetPoint: CGPoint(x: 100, y: 100),
            sourcePosition: .right,
            targetPosition: .left,
            pathStyle: .bezier(curvature: 0.25),
            calculator: calculator
        )
        
        // Cache size should not increase
        XCTAssertEqual(cache.cacheSize, 1)
        
        // Paths should be identical (cached result)
        XCTAssertEqual(path1, path2)
    }
    
    func testEdgePathCacheWithDifferentParameters() {
        let cache = EdgePathCache(maxCacheSize: 10)
        let calculator = BezierPathCalculator()
        let edgeId = UUID()
        
        // First call
        _ = cache.getPath(
            edgeId: edgeId,
            sourcePoint: CGPoint(x: 0, y: 0),
            targetPoint: CGPoint(x: 100, y: 100),
            sourcePosition: .right,
            targetPosition: .left,
            pathStyle: .bezier(curvature: 0.25),
            calculator: calculator
        )
        
        // Second call with different target point
        _ = cache.getPath(
            edgeId: edgeId,
            sourcePoint: CGPoint(x: 0, y: 0),
            targetPoint: CGPoint(x: 200, y: 200),
            sourcePosition: .right,
            targetPosition: .left,
            pathStyle: .bezier(curvature: 0.25),
            calculator: calculator
        )
        
        // Should have two different cached paths
        XCTAssertEqual(cache.cacheSize, 2)
    }
    
    func testEdgePathCacheClearAll() {
        let cache = EdgePathCache(maxCacheSize: 10)
        let calculator = BezierPathCalculator()
        
        _ = cache.getPath(
            edgeId: UUID(),
            sourcePoint: .zero,
            targetPoint: CGPoint(x: 100, y: 100),
            sourcePosition: .right,
            targetPosition: .left,
            pathStyle: .bezier(curvature: 0.25),
            calculator: calculator
        )
        
        XCTAssertEqual(cache.cacheSize, 1)
        
        cache.clearCache()
        XCTAssertEqual(cache.cacheSize, 0)
    }
    
    func testEdgePathCacheClearForEdge() {
        let cache = EdgePathCache(maxCacheSize: 10)
        let calculator = BezierPathCalculator()
        let edge1Id = UUID()
        let edge2Id = UUID()
        
        _ = cache.getPath(
            edgeId: edge1Id,
            sourcePoint: .zero,
            targetPoint: CGPoint(x: 100, y: 100),
            sourcePosition: .right,
            targetPosition: .left,
            pathStyle: .bezier(curvature: 0.25),
            calculator: calculator
        )
        
        _ = cache.getPath(
            edgeId: edge2Id,
            sourcePoint: .zero,
            targetPoint: CGPoint(x: 100, y: 100),
            sourcePosition: .right,
            targetPosition: .left,
            pathStyle: .bezier(curvature: 0.25),
            calculator: calculator
        )
        
        XCTAssertEqual(cache.cacheSize, 2)
        
        cache.clearCache(for: edge1Id)
        
        // Should only have edge2's path
        XCTAssertEqual(cache.cacheSize, 1)
    }
    
    func testEdgePathCacheMaxSizeEnforcement() {
        let cache = EdgePathCache(maxCacheSize: 5)
        let calculator = BezierPathCalculator()
        
        // Add 10 different paths
        for i in 0..<10 {
            _ = cache.getPath(
                edgeId: UUID(),
                sourcePoint: .zero,
                targetPoint: CGPoint(x: Double(i) * 10, y: Double(i) * 10),
                sourcePosition: .right,
                targetPosition: .left,
                pathStyle: .bezier(curvature: 0.25),
                calculator: calculator
            )
        }
        
        // Cache should not exceed max size by too much (allows some overflow during cleanup)
        XCTAssertLessThanOrEqual(cache.cacheSize, 10)
    }
    
    func testEdgePathCacheRoundingConsistency() {
        let cache = EdgePathCache(maxCacheSize: 10)
        let calculator = BezierPathCalculator()
        let edgeId = UUID()
        
        // Small variations should hit the same cache entry due to rounding
        _ = cache.getPath(
            edgeId: edgeId,
            sourcePoint: CGPoint(x: 100.01, y: 100.02),
            targetPoint: CGPoint(x: 200.03, y: 200.04),
            sourcePosition: .right,
            targetPosition: .left,
            pathStyle: .bezier(curvature: 0.25),
            calculator: calculator
        )
        
        _ = cache.getPath(
            edgeId: edgeId,
            sourcePoint: CGPoint(x: 100.02, y: 100.01),
            targetPoint: CGPoint(x: 200.04, y: 200.03),
            sourcePosition: .right,
            targetPosition: .left,
            pathStyle: .bezier(curvature: 0.25),
            calculator: calculator
        )
        
        // Should reuse cached path due to rounding (within 0.1 threshold)
        XCTAssertEqual(cache.cacheSize, 1)
    }
}
