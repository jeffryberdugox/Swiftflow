//
//  PortPositionRegistry.swift
//  SwiftFlow
//
//  Registry for tracking port positions in node-local coordinates (relative to top-left).
//

import Foundation
import SwiftUI

/// Registry that tracks port positions as offsets relative to their node's top-left corner.
/// This approach ensures correct positioning during node dragging, resizing, and zooming.
///
/// # Coordinate System
/// - All offsets are stored in **node-local space** (relative to node.position / top-left)
/// - Port positions adapt automatically during resize if using presets
/// - Custom offsets remain fixed relative to top-left
@MainActor
public class PortPositionRegistry: ObservableObject {
    // MARK: - Properties

    /// Map of port IDs to their node-local offsets (from node's top-left corner)
    @Published private var nodeLocalOffsets: [UUID: CGPoint] = [:]

    /// Map of port IDs to their layouts (presets + custom offsets)
    private var portLayouts: [UUID: PortLayout] = [:]

    /// Map of port IDs to their node IDs (for filtering)
    private var portToNode: [UUID: UUID] = [:]

    /// Map of port IDs to whether they are input ports
    private var portIsInput: [UUID: Bool] = [:]

    /// Map of port IDs to their PortPosition (side of node)
    private var portPositions: [UUID: PortPosition] = [:]

    // MARK: - Initialization

    public init() {}
    
    // MARK: - Registration
    
    /// Register a port's position in node-local coordinates.
    /// - Parameters:
    ///   - portId: The port's unique identifier
    ///   - nodeId: The node's unique identifier
    ///   - nodeLocalOffset: The port's offset from the node's top-left corner
    ///   - layout: The port's layout (preset + offset) for resize adaptation
    ///   - isInput: Whether this is an input port
    ///   - portPosition: The side of the node the port is on
    public func register(
        portId: UUID,
        nodeId: UUID,
        nodeLocalOffset: CGPoint,
        layout: PortLayout? = nil,
        isInput: Bool,
        portPosition: PortPosition
    ) {
        nodeLocalOffsets[portId] = nodeLocalOffset
        if let layout = layout {
            portLayouts[portId] = layout
        }
        portToNode[portId] = nodeId
        portIsInput[portId] = isInput
        portPositions[portId] = portPosition
    }
    
    /// Force update a port's node-local offset (use sparingly).
    /// - Parameters:
    ///   - portId: The port's unique identifier
    ///   - nodeLocalOffset: The new node-local offset
    public func updateNodeLocalOffset(portId: UUID, nodeLocalOffset: CGPoint) {
        nodeLocalOffsets[portId] = nodeLocalOffset
    }
    
    /// Unregister a port
    /// NOTE: This does NOT remove the port from the registry to prevent flickering
    /// during view redraws (zoom, pan, etc.). Port positions are kept indefinitely
    /// and only cleaned up when the entire node is removed via unregisterNode().
    /// - Parameter portId: The port's unique identifier
    public func unregister(portId: UUID) {
        // Intentionally empty - we keep port positions in the registry
        // even when the view temporarily disappears during redraws
    }

    /// Unregister all ports for a node (called when node is deleted)
    /// - Parameter nodeId: The node's unique identifier
    public func unregisterNode(nodeId: UUID) {
        let portsToRemove = portToNode.filter { $0.value == nodeId }.map { $0.key }
        for portId in portsToRemove {
            nodeLocalOffsets.removeValue(forKey: portId)
            portLayouts.removeValue(forKey: portId)
            portToNode.removeValue(forKey: portId)
            portIsInput.removeValue(forKey: portId)
            portPositions.removeValue(forKey: portId)
        }
    }

    /// Recalculate port positions for a resized node using their layouts.
    /// Presets with custom offsets preserve their offsets, pure presets adapt to new size.
    /// - Parameters:
    ///   - nodeId: The node's unique identifier
    ///   - newSize: The new size of the node
    public func updatePortsForResize(nodeId: UUID, newSize: CGSize) {
        // Find all ports for this node
        let portIds = portToNode.filter { $0.value == nodeId }.map { $0.key }

        // Recalculate each port's position using its layout
        for portId in portIds {
            if let layout = portLayouts[portId] {
                // If layout has a non-zero offset, preserve it (maintains relative position)
                if layout.offset != .zero {
                    // Custom offset: recalculate preset position but keep custom offset
                    let newOffset = layout.position(nodeSize: newSize)
                    nodeLocalOffsets[portId] = newOffset
                } else {
                    // Pure preset without offset: keep existing node-local offset
                    // This preserves the actual rendered position from VStack layout
                    // Don't recalculate, as it would move all ports to .leftCenter/.rightCenter
                }
            }
            // If no layout, keep existing offset (custom position stays fixed)
        }
    }
    
    // MARK: - Queries
    
    /// Get the node-local offset of a port from its node's top-left corner.
    /// - Parameter portId: The port's unique identifier
    /// - Returns: The node-local offset, or nil if not registered
    public func nodeLocalOffset(for portId: UUID) -> CGPoint? {
        nodeLocalOffsets[portId]
    }
    
    /// Get the absolute canvas position of a port given the current node position.
    /// - Parameters:
    ///   - portId: The port's unique identifier
    ///   - nodePosition: The current position (top-left) of the node
    /// - Returns: The absolute position of the port in canvas coordinates
    public func canvasPosition(for portId: UUID, nodePosition: CGPoint) -> CGPoint? {
        guard let offset = nodeLocalOffsets[portId] else { return nil }
        return CGPoint(
            x: nodePosition.x + offset.x,
            y: nodePosition.y + offset.y
        )
    }
    
    /// Get the port's layout (preset + offset).
    /// - Parameter portId: The port's unique identifier
    /// - Returns: The port layout, or nil if not registered or no layout stored
    public func layout(for portId: UUID) -> PortLayout? {
        portLayouts[portId]
    }
    
    /// Get the node ID for a port
    /// - Parameter portId: The port's unique identifier
    /// - Returns: The node ID, or nil if not registered
    public func nodeId(for portId: UUID) -> UUID? {
        portToNode[portId]
    }
    
    /// Check if a port is an input port
    /// - Parameter portId: The port's unique identifier
    /// - Returns: True if input port, false if output, nil if not registered
    public func isInputPort(_ portId: UUID) -> Bool? {
        portIsInput[portId]
    }
    
    /// Get the port position (side) for a port
    /// - Parameter portId: The port's unique identifier
    /// - Returns: The port position, or nil if not registered
    public func portPosition(for portId: UUID) -> PortPosition? {
        portPositions[portId]
    }
    
    /// Find the closest port to a position
    /// - Parameters:
    ///   - position: The position to search from (in canvas coordinates)
    ///   - radius: Maximum distance to search
    ///   - nodePositions: Current positions (top-left) of all nodes
    ///   - excludeNodeId: Node ID to exclude from search
    ///   - lookingForInput: Whether to look for input ports (true) or output ports (false)
    /// - Returns: Tuple of (nodeId, portId, position, portPosition) if found
    public func findClosestPort(
        to position: CGPoint,
        radius: CGFloat,
        nodePositions: [UUID: CGPoint],
        excludeNodeId: UUID?,
        lookingForInput: Bool
    ) -> (nodeId: UUID, portId: UUID, position: CGPoint, portPosition: PortPosition)? {
        var closestPort: (nodeId: UUID, portId: UUID, position: CGPoint, portPosition: PortPosition)?
        var closestDistance: CGFloat = radius
        
        for (portId, offset) in nodeLocalOffsets {
            // Skip if this port belongs to excluded node
            guard let nodeId = portToNode[portId],
                  nodeId != excludeNodeId else { continue }
            
            // Skip if wrong type (input vs output)
            guard let isInput = portIsInput[portId],
                  isInput == lookingForInput else { continue }
            
            // Get port position side
            guard let portPosition = portPositions[portId] else { continue }
            
            // Get current node position (top-left)
            guard let nodePos = nodePositions[nodeId] else { continue }
            
            // Calculate absolute port position in canvas coords
            let portPos = CGPoint(
                x: nodePos.x + offset.x,
                y: nodePos.y + offset.y
            )
            
            // Calculate distance
            let distance = sqrt(
                pow(position.x - portPos.x, 2) +
                pow(position.y - portPos.y, 2)
            )
            
            if distance < closestDistance {
                closestDistance = distance
                closestPort = (nodeId, portId, portPos, portPosition)
            }
        }
        
        return closestPort
    }
    
    /// Get all registered port node-local offsets for debugging
    public var allNodeLocalOffsets: [UUID: CGPoint] {
        nodeLocalOffsets
    }
}

// MARK: - Environment Key

private struct PortPositionRegistryKey: EnvironmentKey {
    static let defaultValue: PortPositionRegistry? = nil
}

public extension EnvironmentValues {
    /// The port position registry for the current canvas
    var portPositionRegistry: PortPositionRegistry? {
        get { self[PortPositionRegistryKey.self] }
        set { self[PortPositionRegistryKey.self] = newValue }
    }
}
