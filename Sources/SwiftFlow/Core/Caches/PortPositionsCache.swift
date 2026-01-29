//
//  PortPositionsCache.swift
//  SwiftFlow
//
//  Cache for calculated port positions.
//

import Foundation
import CoreGraphics

// MARK: - PortPositionsCache

/// Cache for calculated port absolute positions.
/// Avoids recalculating port positions when nodes haven't changed.
///
/// # Usage
/// ```swift
/// let cache = PortPositionsCache()
///
/// // Get port position (uses cache if available)
/// let position = cache.getPosition(
///     portId: port.id,
///     nodeId: node.id,
///     nodePosition: node.position,
///     nodeSize: CGSize(width: node.width, height: node.height),
///     portPosition: port.position,
///     nodeVersion: nodeVersionCounter[node.id]
/// )
///
/// // Invalidate when node changes
/// cache.invalidate(nodeId: changedNodeId)
/// ```
public class PortPositionsCache {
    
    // MARK: - Cache State
    
    /// Cached port positions (portId -> position)
    private var positionCache: [UUID: CGPoint] = [:]
    
    /// Version tracking for nodes (nodeId -> version)
    private var nodeVersions: [UUID: Int] = [:]
    
    /// Mapping of ports to their owning nodes (portId -> nodeId)
    private var portToNode: [UUID: UUID] = [:]
    
    // MARK: - Statistics
    
    /// Number of cache hits
    public private(set) var cacheHits: Int = 0
    
    /// Number of cache misses
    public private(set) var cacheMisses: Int = 0
    
    /// Cache hit ratio
    public var hitRatio: Double {
        let total = cacheHits + cacheMisses
        guard total > 0 else { return 0 }
        return Double(cacheHits) / Double(total)
    }
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public API
    
    /// Get the position of a port, using cache if available.
    /// - Parameters:
    ///   - portId: ID of the port
    ///   - nodeId: ID of the node the port belongs to
    ///   - nodePosition: Current position of the node (top-left)
    ///   - nodeSize: Current size of the node
    ///   - portPosition: Position of the port on the node (top, bottom, left, right)
    ///   - nodeVersion: Version number for cache invalidation
    /// - Returns: Absolute position of the port in canvas coordinates
    public func getPosition(
        portId: UUID,
        nodeId: UUID,
        nodePosition: CGPoint,
        nodeSize: CGSize,
        portPosition: PortPosition,
        nodeVersion: Int
    ) -> CGPoint {
        // Check if cache is valid
        if let cachedPosition = positionCache[portId],
           nodeVersions[nodeId] == nodeVersion {
            cacheHits += 1
            return cachedPosition
        }
        
        cacheMisses += 1
        
        // Calculate position
        let position = calculatePortPositionWithSize(
            position: portPosition,
            nodeTopLeft: nodePosition,
            nodeSize: nodeSize
        )
        
        // Update cache
        positionCache[portId] = position
        nodeVersions[nodeId] = nodeVersion
        portToNode[portId] = nodeId
        
        return position
    }
    
    /// Get cached position for a port without recalculating.
    /// - Parameter portId: ID of the port
    /// - Returns: Cached position, or nil if not cached
    public func getCachedPosition(portId: UUID) -> CGPoint? {
        positionCache[portId]
    }
    
    /// Invalidate cache for all ports on a node.
    /// - Parameter nodeId: ID of the node
    public func invalidate(nodeId: UUID) {
        nodeVersions.removeValue(forKey: nodeId)
        
        // Remove all ports for this node
        let portsToRemove = portToNode.filter { $0.value == nodeId }.map { $0.key }
        for portId in portsToRemove {
            positionCache.removeValue(forKey: portId)
            portToNode.removeValue(forKey: portId)
        }
    }
    
    /// Invalidate cache for multiple nodes.
    /// - Parameter nodeIds: IDs of nodes to invalidate
    public func invalidate(nodeIds: Set<UUID>) {
        for nodeId in nodeIds {
            invalidate(nodeId: nodeId)
        }
    }
    
    /// Invalidate all caches.
    public func invalidate() {
        positionCache.removeAll()
        nodeVersions.removeAll()
        portToNode.removeAll()
    }
    
    /// Reset statistics.
    public func resetStatistics() {
        cacheHits = 0
        cacheMisses = 0
    }
    
    // MARK: - Bulk Operations
    
    /// Pre-cache positions for all ports on a node.
    /// - Parameters:
    ///   - node: The node
    ///   - nodeVersion: Version number for the node
    public func preCachePositions<Node: FlowNode>(
        for node: Node,
        nodeVersion: Int
    ) {
        let nodeSize = CGSize(width: node.width, height: node.height)
        
        // Cache input ports
        for port in node.inputPorts {
            _ = getPosition(
                portId: port.id,
                nodeId: node.id,
                nodePosition: node.position,
                nodeSize: nodeSize,
                portPosition: port.position,
                nodeVersion: nodeVersion
            )
        }
        
        // Cache output ports
        for port in node.outputPorts {
            _ = getPosition(
                portId: port.id,
                nodeId: node.id,
                nodePosition: node.position,
                nodeSize: nodeSize,
                portPosition: port.position,
                nodeVersion: nodeVersion
            )
        }
    }
    
    // MARK: - Private
    
    private func calculatePortPositionWithSize(
        position: PortPosition,
        nodeTopLeft: CGPoint,
        nodeSize: CGSize
    ) -> CGPoint {
        switch position {
        case .left:
            return CGPoint(
                x: nodeTopLeft.x,
                y: nodeTopLeft.y + nodeSize.height / 2
            )
        case .right:
            return CGPoint(
                x: nodeTopLeft.x + nodeSize.width,
                y: nodeTopLeft.y + nodeSize.height / 2
            )
        case .top:
            return CGPoint(
                x: nodeTopLeft.x + nodeSize.width / 2,
                y: nodeTopLeft.y
            )
        case .bottom:
            return CGPoint(
                x: nodeTopLeft.x + nodeSize.width / 2,
                y: nodeTopLeft.y + nodeSize.height
            )
        }
    }
}
