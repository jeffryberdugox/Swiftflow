//
//  ConnectionDropContext.swift
//  SwiftFlow
//
//  Context information when a connection is dropped on empty canvas area.
//

import Foundation
import CoreGraphics

/// Context information provided when a connection is dropped on empty canvas area
public struct ConnectionDropContext {
    /// ID of the node where the connection started
    public let sourceNodeId: UUID
    
    /// ID of the port where the connection started
    public let sourcePortId: UUID
    
    /// Position of the source port (left, right, top, bottom)
    public let sourcePortPosition: PortPosition
    
    /// Position in canvas coordinates where the connection was dropped
    public let dropPosition: CGPoint
    
    /// Whether the connection started from an input port (true) or output port (false)
    public let isFromInput: Bool
    
    /// Convenience: Whether the connection started from an output port
    public var isFromOutput: Bool { !isFromInput }
    
    /// Complete the connection programmatically with the specified target
    public let completeConnection: (UUID, UUID) -> Void
    
    /// Cancel the connection
    public let cancelConnection: () -> Void
    
    public init(
        sourceNodeId: UUID,
        sourcePortId: UUID,
        sourcePortPosition: PortPosition,
        dropPosition: CGPoint,
        isFromInput: Bool,
        completeConnection: @escaping (UUID, UUID) -> Void,
        cancelConnection: @escaping () -> Void
    ) {
        self.sourceNodeId = sourceNodeId
        self.sourcePortId = sourcePortId
        self.sourcePortPosition = sourcePortPosition
        self.dropPosition = dropPosition
        self.isFromInput = isFromInput
        self.completeConnection = completeConnection
        self.cancelConnection = cancelConnection
    }
}

/// Action to take after a connection drop on canvas
public enum ConnectionDropAction: Sendable {
    /// Cancel the connection immediately
    case cancel
    
    /// Keep the connection preview alive (useful for async operations like showing menus)
    case continueConnection
    
    /// Complete the connection programmatically with specified target
    case complete(targetNodeId: UUID, targetPortId: UUID)
}
