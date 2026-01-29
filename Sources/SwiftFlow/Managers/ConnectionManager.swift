//
//  ConnectionManager.swift
//  SwiftFlow
//
//  Manages connection creation between ports.
//

import Foundation
import SwiftUI
import Combine

/// Manages the creation of connections between ports
@MainActor
public class ConnectionManager: ObservableObject {
    // MARK: - Published Properties
    
    /// Current connection being drawn (nil if not connecting)
    @Published public private(set) var connectionInProgress: ConnectionState?
    
    // MARK: - Configuration
    
    /// Radius for detecting nearby ports
    public var connectionRadius: CGFloat
    
    /// Minimum drag distance before connection starts
    public var connectionThreshold: CGFloat
    
    // MARK: - Callbacks
    
    /// Called when a connection is successfully created
    public var onConnectionCreated: ((UUID, UUID, UUID, UUID) -> Void)?
    
    /// Called to validate if a connection is allowed
    public var validateConnection: ((UUID, UUID, UUID, UUID) -> Bool)?
    
    /// Whether to detect drops on empty canvas areas
    public var enableCanvasDropDetection: Bool
    
    /// Called when a connection is dropped on empty canvas area
    /// Return a ConnectionDropAction to control what happens next
    public var onConnectionDroppedOnCanvas: ((ConnectionDropContext) -> ConnectionDropAction)?
    
    // MARK: - Initialization
    
    public init(
        connectionRadius: CGFloat = 20,
        connectionThreshold: CGFloat = 5,
        enableCanvasDropDetection: Bool = false
    ) {
        self.connectionRadius = connectionRadius
        self.connectionThreshold = connectionThreshold
        self.enableCanvasDropDetection = enableCanvasDropDetection
    }
    
    // MARK: - Connection Operations
    
    /// Start a connection from a port
    /// - Parameters:
    ///   - nodeId: ID of the source node
    ///   - portId: ID of the source port
    ///   - position: Position of the port in canvas coordinates
    ///   - portPosition: Side of the node the port is on
    ///   - isFromInput: Whether starting from an input port (reverse direction)
    public func startConnection(
        from nodeId: UUID,
        portId: UUID,
        at position: CGPoint,
        portPosition: PortPosition,
        isFromInput: Bool = false
    ) {
        connectionInProgress = ConnectionState(
            sourceNodeId: nodeId,
            sourcePortId: portId,
            sourcePosition: position,
            sourcePortPosition: portPosition,
            currentPosition: position,
            isValid: false,
            isFromInput: isFromInput
        )
    }
    
    /// Update the connection endpoint
    /// - Parameters:
    ///   - position: Current position in canvas coordinates
    ///   - nearbyPort: Information about a nearby valid port, if any
    public func updateConnection(
        to position: CGPoint,
        nearbyPort: (nodeId: UUID, portId: UUID, position: CGPoint, portPosition: PortPosition)? = nil
    ) {
        guard var state = connectionInProgress else { return }
        
        if let port = nearbyPort {
            // Check if connection is valid
            let isValid: Bool
            if state.isFromInput {
                // Connecting from input to output
                isValid = validateConnectionIfNeeded(
                    sourceNodeId: port.nodeId,
                    sourcePortId: port.portId,
                    targetNodeId: state.sourceNodeId,
                    targetPortId: state.sourcePortId
                )
            } else {
                // Connecting from output to input
                isValid = validateConnectionIfNeeded(
                    sourceNodeId: state.sourceNodeId,
                    sourcePortId: state.sourcePortId,
                    targetNodeId: port.nodeId,
                    targetPortId: port.portId
                )
            }
            
            state.currentPosition = port.position
            state.targetNodeId = port.nodeId
            state.targetPortId = port.portId
            state.targetPortPosition = port.portPosition
            state.isValid = isValid
        } else {
            state.currentPosition = position
            state.targetNodeId = nil
            state.targetPortId = nil
            state.targetPortPosition = nil
            state.isValid = false
        }
        
        connectionInProgress = state
    }
    
    /// End the connection attempt
    /// - Returns: True if a valid connection was created
    @discardableResult
    public func endConnection() -> Bool {
        guard let state = connectionInProgress else { return false }
        
        // Check if we have a valid target
        if state.hasValidTarget,
           let targetNodeId = state.targetNodeId,
           let targetPortId = state.targetPortId {
            
            // Determine actual source/target based on direction
            let actualSourceNodeId: UUID
            let actualSourcePortId: UUID
            let actualTargetNodeId: UUID
            let actualTargetPortId: UUID
            
            if state.isFromInput {
                // Started from input, so target becomes source
                actualSourceNodeId = targetNodeId
                actualSourcePortId = targetPortId
                actualTargetNodeId = state.sourceNodeId
                actualTargetPortId = state.sourcePortId
            } else {
                actualSourceNodeId = state.sourceNodeId
                actualSourcePortId = state.sourcePortId
                actualTargetNodeId = targetNodeId
                actualTargetPortId = targetPortId
            }
            
            // Clear connection state
            connectionInProgress = nil
            
            // Notify about the new connection
            onConnectionCreated?(
                actualSourceNodeId,
                actualSourcePortId,
                actualTargetNodeId,
                actualTargetPortId
            )
            
            return true
        } else {
            // No valid target - check if canvas drop detection is enabled
            if enableCanvasDropDetection, let handler = onConnectionDroppedOnCanvas {
                let context = ConnectionDropContext(
                    sourceNodeId: state.sourceNodeId,
                    sourcePortId: state.sourcePortId,
                    sourcePortPosition: state.sourcePortPosition,
                    dropPosition: state.currentPosition,
                    isFromInput: state.isFromInput,
                    completeConnection: { [weak self] targetNodeId, targetPortId in
                        self?.completeConnection(targetNodeId: targetNodeId, targetPortId: targetPortId)
                    },
                    cancelConnection: { [weak self] in
                        self?.cancelConnection()
                    }
                )
                
                let action = handler(context)
                
                switch action {
                case .cancel:
                    // Clear connection state and cancel
                    connectionInProgress = nil
                    return false
                    
                case .continueConnection:
                    // Keep connection state alive - don't clear it
                    // This allows async operations (like showing a menu)
                    return false
                    
                case .complete(let targetNodeId, let targetPortId):
                    // Complete connection programmatically
                    let actualSourceNodeId: UUID
                    let actualSourcePortId: UUID
                    let actualTargetNodeId: UUID
                    let actualTargetPortId: UUID
                    
                    if state.isFromInput {
                        actualSourceNodeId = targetNodeId
                        actualSourcePortId = targetPortId
                        actualTargetNodeId = state.sourceNodeId
                        actualTargetPortId = state.sourcePortId
                    } else {
                        actualSourceNodeId = state.sourceNodeId
                        actualSourcePortId = state.sourcePortId
                        actualTargetNodeId = targetNodeId
                        actualTargetPortId = targetPortId
                    }
                    
                    // Clear connection state
                    connectionInProgress = nil
                    
                    // Notify about the new connection
                    onConnectionCreated?(
                        actualSourceNodeId,
                        actualSourcePortId,
                        actualTargetNodeId,
                        actualTargetPortId
                    )
                    
                    return true
                }
            } else {
                // Canvas drop detection disabled or no handler - just cancel
                connectionInProgress = nil
                return false
            }
        }
    }
    
    /// Cancel the current connection without creating it
    public func cancelConnection() {
        connectionInProgress = nil
    }
    
    /// Programmatically complete a connection that was kept alive with .continueConnection
    /// - Parameters:
    ///   - targetNodeId: ID of the target node
    ///   - targetPortId: ID of the target port
    /// - Returns: True if connection was successfully completed
    @discardableResult
    public func completeConnection(targetNodeId: UUID, targetPortId: UUID) -> Bool {
        guard let state = connectionInProgress else { return false }
        
        // Determine actual source/target based on direction
        let actualSourceNodeId: UUID
        let actualSourcePortId: UUID
        let actualTargetNodeId: UUID
        let actualTargetPortId: UUID
        
        if state.isFromInput {
            actualSourceNodeId = targetNodeId
            actualSourcePortId = targetPortId
            actualTargetNodeId = state.sourceNodeId
            actualTargetPortId = state.sourcePortId
        } else {
            actualSourceNodeId = state.sourceNodeId
            actualSourcePortId = state.sourcePortId
            actualTargetNodeId = targetNodeId
            actualTargetPortId = targetPortId
        }
        
        // Clear connection state
        connectionInProgress = nil
        
        // Notify about the new connection
        onConnectionCreated?(
            actualSourceNodeId,
            actualSourcePortId,
            actualTargetNodeId,
            actualTargetPortId
        )
        
        return true
    }
    
    // MARK: - Port Detection
    
    /// Find the closest port within connection radius
    /// - Parameters:
    ///   - position: Current position in canvas coordinates
    ///   - nodes: All nodes to check
    ///   - excludeNodeId: Node ID to exclude (typically the source node)
    ///   - lookingForInput: Whether to look for input ports (true) or output ports (false)
    /// - Returns: Closest valid port information, or nil if none found
    public func findClosestPort<Node: FlowNode>(
        to position: CGPoint,
        in nodes: [Node],
        excludeNodeId: UUID?,
        lookingForInput: Bool
    ) -> (nodeId: UUID, portId: UUID, position: CGPoint, portPosition: PortPosition)? {
        var closestPort: (nodeId: UUID, portId: UUID, position: CGPoint, portPosition: PortPosition)?
        var closestDistance: CGFloat = connectionRadius
        
        for node in nodes {
            // Skip excluded node
            if node.id == excludeNodeId { continue }
            
            // Check appropriate ports
            let ports = lookingForInput ? node.inputPorts : node.outputPorts
            
            for port in ports {
                let portPos = calculatePortPosition(
                    port: port,
                    on: node,
                    isInput: lookingForInput
                )
                
                let distance = sqrt(
                    pow(position.x - portPos.x, 2) +
                    pow(position.y - portPos.y, 2)
                )
                
                if distance < closestDistance {
                    closestDistance = distance
                    closestPort = (node.id, port.id, portPos, port.position)
                }
            }
        }
        
        return closestPort
    }
    
    // MARK: - Helpers
    
    /// Whether a connection is in progress
    public var isConnecting: Bool {
        connectionInProgress != nil
    }
    
    private func validateConnectionIfNeeded(
        sourceNodeId: UUID,
        sourcePortId: UUID,
        targetNodeId: UUID,
        targetPortId: UUID
    ) -> Bool {
        // Don't allow self-connections
        if sourceNodeId == targetNodeId {
            return false
        }
        
        // Use custom validator if provided
        if let validator = validateConnection {
            return validator(sourceNodeId, sourcePortId, targetNodeId, targetPortId)
        }
        
        return true
    }
}
