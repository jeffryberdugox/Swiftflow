//
//  EdgePathCache.swift
//  SwiftFlow
//
//  Cache for edge path calculations to avoid expensive recalculations during pan/zoom.
//

import Foundation
import SwiftUI

/// Cache for edge path calculations to avoid expensive recalculations
///
/// # Usage
/// ```swift
/// let cache = EdgePathCache()
///
/// let path = cache.getPath(
///     edgeId: edge.id,
///     sourcePoint: sourcePoint,
///     targetPoint: targetPoint,
///     sourcePosition: .right,
///     targetPosition: .left,
///     pathStyle: .bezier(curvature: 0.25),
///     calculator: pathCalculator
/// )
/// ```
public class EdgePathCache: ObservableObject {
    
    private struct CacheKey: Hashable, Equatable {
        let edgeId: UUID
        let sourceX: CGFloat
        let sourceY: CGFloat
        let targetX: CGFloat
        let targetY: CGFloat
        let sourcePosition: PortPosition
        let targetPosition: PortPosition
        let pathStyle: String  // pathStyle.description

        init(edgeId: UUID, sourcePoint: CGPoint, targetPoint: CGPoint, sourcePosition: PortPosition, targetPosition: PortPosition, pathStyle: String) {
            self.edgeId = edgeId
            self.sourceX = sourcePoint.x
            self.sourceY = sourcePoint.y
            self.targetX = targetPoint.x
            self.targetY = targetPoint.y
            self.sourcePosition = sourcePosition
            self.targetPosition = targetPosition
            self.pathStyle = pathStyle
        }

        /// Use rounded values to allow small variations without cache miss
        func rounded() -> CacheKey {
            return CacheKey(
                edgeId: edgeId,
                sourcePoint: CGPoint(
                    x: (sourceX * 10).rounded() / 10,
                    y: (sourceY * 10).rounded() / 10
                ),
                targetPoint: CGPoint(
                    x: (targetX * 10).rounded() / 10,
                    y: (targetY * 10).rounded() / 10
                ),
                sourcePosition: sourcePosition,
                targetPosition: targetPosition,
                pathStyle: pathStyle
            )
        }
    }
    
    private var cache: [CacheKey: Path] = [:]
    private var maxCacheSize: Int
    
    /// Creates an edge path cache.
    /// - Parameter maxCacheSize: Maximum number of paths to cache. Default is 500.
    public init(maxCacheSize: Int = 500) {
        self.maxCacheSize = maxCacheSize
    }
    
    /// Get cached path or calculate and cache it
    /// - Parameters:
    ///   - edgeId: Unique identifier for the edge
    ///   - sourcePoint: Source point in canvas coordinates
    ///   - targetPoint: Target point in canvas coordinates
    ///   - sourcePosition: Source port position
    ///   - targetPosition: Target port position
    ///   - pathStyle: Edge path style
    ///   - calculator: Path calculator to use if cache miss
    /// - Returns: Calculated or cached path
    public func getPath(
        edgeId: UUID,
        sourcePoint: CGPoint,
        targetPoint: CGPoint,
        sourcePosition: PortPosition,
        targetPosition: PortPosition,
        pathStyle: EdgePathStyle,
        calculator: any PathCalculator
    ) -> Path {
        let key = CacheKey(
            edgeId: edgeId,
            sourcePoint: sourcePoint,
            targetPoint: targetPoint,
            sourcePosition: sourcePosition,
            targetPosition: targetPosition,
            pathStyle: String(describing: pathStyle)
        ).rounded()
        
        if let cachedPath = cache[key] {
            return cachedPath
        }
        
        // Calculate new path
        let result = calculator.calculatePath(
            from: sourcePoint,
            to: targetPoint,
            sourcePosition: sourcePosition,
            targetPosition: targetPosition
        )
        
        // Manage cache size
        if cache.count >= maxCacheSize {
            // Remove ~20% oldest entries (simple FIFO)
            let removeCount = maxCacheSize / 5
            let remaining = Array(cache.dropFirst(removeCount))
            cache = Dictionary(uniqueKeysWithValues: remaining)
        }
        
        cache[key] = result.path
        return result.path
    }
    
    /// Clear all cached paths
    public func clearCache() {
        cache.removeAll()
    }
    
    /// Clear cached paths for specific edge
    /// - Parameter edgeId: Edge identifier
    public func clearCache(for edgeId: UUID) {
        cache = cache.filter { $0.key.edgeId != edgeId }
    }
    
    /// Get current cache size
    public var cacheSize: Int {
        cache.count
    }
}
