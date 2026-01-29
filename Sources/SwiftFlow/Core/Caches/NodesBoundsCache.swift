//
//  NodesBoundsCache.swift
//  SwiftFlow
//
//  Cache for calculated node bounds to avoid recalculation.
//

import Foundation
import CoreGraphics

// MARK: - NodesBoundsCache

/// Cache for calculated node bounds.
/// Avoids recalculating bounds on every frame when nodes haven't changed.
///
/// # Usage
/// ```swift
/// let cache = NodesBoundsCache()
///
/// // Get bounds (calculates if needed, returns cached if unchanged)
/// let bounds = cache.getBounds(for: nodes)
///
/// // Invalidate when nodes change
/// cache.invalidate()
///
/// // Or invalidate specific nodes
/// cache.invalidate(nodeId: changedNodeId)
/// ```
public class NodesBoundsCache {
    
    // MARK: - Cache State
    
    /// Cached combined bounds of all nodes
    private var cachedBounds: CanvasRect?
    
    /// Hash of nodes at time of cache
    private var nodesHash: Int = 0
    
    /// Individual node bounds cache
    private var nodeBoundsCache: [UUID: CanvasRect] = [:]
    
    /// Timestamp of last calculation
    private var lastCalculationTime: Date?
    
    // MARK: - Configuration
    
    /// Minimum time between recalculations (throttling)
    public var minRecalculationInterval: TimeInterval = 0.016  // ~60fps
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public API
    
    /// Get the combined bounds of all nodes.
    /// Returns cached value if nodes haven't changed.
    /// - Parameter nodes: Array of nodes
    /// - Returns: Combined bounds, or nil if no nodes
    public func getBounds<Node: FlowNode>(for nodes: [Node]) -> CanvasRect? {
        let currentHash = calculateHash(nodes)
        
        // Check if cache is valid
        if currentHash == nodesHash, let cached = cachedBounds {
            return cached
        }
        
        // Throttle recalculations
        if let lastTime = lastCalculationTime,
           Date().timeIntervalSince(lastTime) < minRecalculationInterval,
           cachedBounds != nil {
            return cachedBounds
        }
        
        // Calculate new bounds
        guard let bounds = calculateNodesBounds(nodes) else {
            cachedBounds = nil
            nodesHash = currentHash
            return nil
        }
        
        cachedBounds = CanvasRect(bounds)
        nodesHash = currentHash
        lastCalculationTime = Date()
        
        // Update individual node caches
        for node in nodes {
            nodeBoundsCache[node.id] = CanvasRect(node.bounds)
        }
        
        return cachedBounds
    }
    
    /// Get bounds for a specific node.
    /// - Parameter nodeId: ID of the node
    /// - Returns: Cached bounds, or nil if not cached
    public func getBounds(for nodeId: UUID) -> CanvasRect? {
        nodeBoundsCache[nodeId]
    }
    
    /// Invalidate all caches.
    public func invalidate() {
        cachedBounds = nil
        nodesHash = 0
        nodeBoundsCache.removeAll()
        lastCalculationTime = nil
    }
    
    /// Invalidate cache for a specific node.
    /// Also invalidates the combined bounds cache.
    /// - Parameter nodeId: ID of the node to invalidate
    public func invalidate(nodeId: UUID) {
        nodeBoundsCache.removeValue(forKey: nodeId)
        cachedBounds = nil
        nodesHash = 0
    }
    
    /// Invalidate caches for multiple nodes.
    /// - Parameter nodeIds: IDs of nodes to invalidate
    public func invalidate(nodeIds: Set<UUID>) {
        for nodeId in nodeIds {
            nodeBoundsCache.removeValue(forKey: nodeId)
        }
        cachedBounds = nil
        nodesHash = 0
    }
    
    /// Check if the cache is valid for the given nodes.
    /// - Parameter nodes: Nodes to check against
    /// - Returns: True if cache is valid
    public func isValid<Node: FlowNode>(for nodes: [Node]) -> Bool {
        calculateHash(nodes) == nodesHash && cachedBounds != nil
    }
    
    // MARK: - Private
    
    private func calculateHash<Node: FlowNode>(_ nodes: [Node]) -> Int {
        var hasher = Hasher()
        for node in nodes {
            hasher.combine(node.id)
            hasher.combine(node.position.x)
            hasher.combine(node.position.y)
            hasher.combine(node.width)
            hasher.combine(node.height)
        }
        return hasher.finalize()
    }
}

// MARK: - Thread Safety Note

/*
 Note: This cache is NOT thread-safe. It should only be accessed from the main thread.
 For multi-threaded access, use a lock or actor.
 
 In SwiftUI, view updates happen on the main thread, so this should be fine
 for most use cases. The @MainActor annotation on the controller ensures
 main-thread access.
 */
