//
//  ConnectionState.swift
//  SwiftFlow
//
//  Represents the state of an in-progress connection between ports.
//

import Foundation
import CoreGraphics

/// Represents an in-progress connection being drawn from one port to another
public struct ConnectionState: Equatable, Sendable {
    /// ID of the source node
    public var sourceNodeId: UUID
    
    /// ID of the source port
    public var sourcePortId: UUID
    
    /// Position of the source port in canvas coordinates
    public var sourcePosition: CGPoint
    
    /// Position of the source port side (for edge rendering)
    public var sourcePortPosition: PortPosition
    
    /// Current endpoint of the connection preview (follows mouse/touch)
    public var currentPosition: CGPoint
    
    /// ID of the target node if hovering over a valid target
    public var targetNodeId: UUID?
    
    /// ID of the target port if hovering over a valid target
    public var targetPortId: UUID?
    
    /// Position of the target port side (for edge rendering)
    public var targetPortPosition: PortPosition?
    
    /// Whether the current target is a valid connection
    public var isValid: Bool
    
    /// Whether this connection started from an input port (reverse direction)
    public var isFromInput: Bool
    
    public init(
        sourceNodeId: UUID,
        sourcePortId: UUID,
        sourcePosition: CGPoint,
        sourcePortPosition: PortPosition,
        currentPosition: CGPoint,
        targetNodeId: UUID? = nil,
        targetPortId: UUID? = nil,
        targetPortPosition: PortPosition? = nil,
        isValid: Bool = false,
        isFromInput: Bool = false
    ) {
        self.sourceNodeId = sourceNodeId
        self.sourcePortId = sourcePortId
        self.sourcePosition = sourcePosition
        self.sourcePortPosition = sourcePortPosition
        self.currentPosition = currentPosition
        self.targetNodeId = targetNodeId
        self.targetPortId = targetPortId
        self.targetPortPosition = targetPortPosition
        self.isValid = isValid
        self.isFromInput = isFromInput
    }
    
    /// Whether there's a valid target for the connection
    public var hasValidTarget: Bool {
        targetNodeId != nil && targetPortId != nil && isValid
    }
    
    /// The effective source position for edge rendering
    /// (swapped if connection started from input)
    public var effectiveSourcePosition: CGPoint {
        isFromInput ? currentPosition : sourcePosition
    }
    
    /// The effective target position for edge rendering
    public var effectiveTargetPosition: CGPoint {
        isFromInput ? sourcePosition : currentPosition
    }
}
