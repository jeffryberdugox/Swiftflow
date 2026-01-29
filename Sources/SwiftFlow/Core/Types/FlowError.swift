//
//  FlowError.swift
//  SwiftFlow
//
//  Error types for SwiftFlow operations.
//

import Foundation

/// Error codes for SwiftFlow operations
public enum ErrorCode: String, Equatable, Sendable, Codable {
    // Node errors
    case nodeNotFound = "NODE_NOT_FOUND"
    case nodeMissingDimensions = "NODE_MISSING_DIMENSIONS"
    case nodeInvalid = "NODE_INVALID"
    
    // Edge errors
    case edgeNotFound = "EDGE_NOT_FOUND"
    case edgeInvalid = "EDGE_INVALID"
    case edgeSourceMissing = "EDGE_SOURCE_MISSING"
    case edgeTargetMissing = "EDGE_TARGET_MISSING"
    
    // Connection errors
    case connectionInvalid = "CONNECTION_INVALID"
    case connectionExists = "CONNECTION_EXISTS"
    case connectionCycle = "CONNECTION_CYCLE"
    case portNotFound = "PORT_NOT_FOUND"
    
    // Transform errors
    case transformInvalid = "TRANSFORM_INVALID"
    case zoomOutOfBounds = "ZOOM_OUT_OF_BOUNDS"
    
    // Command errors
    case commandFailed = "COMMAND_FAILED"
    case commandInvalid = "COMMAND_INVALID"
    
    // State errors
    case stateInvalid = "STATE_INVALID"
    case operationNotAllowed = "OPERATION_NOT_ALLOWED"
}

/// Error type for SwiftFlow operations
public struct FlowError: Error, Equatable, Sendable {
    /// Error code
    public let code: ErrorCode
    
    /// Human-readable error message
    public let message: String
    
    /// Additional context data
    public let context: [String: String]?
    
    public init(
        code: ErrorCode,
        message: String,
        context: [String: String]? = nil
    ) {
        self.code = code
        self.message = message
        self.context = context
    }
    
    // MARK: - Convenience Initializers
    
    /// Node not found error
    public static func nodeNotFound(id: UUID) -> FlowError {
        FlowError(
            code: .nodeNotFound,
            message: "Node with ID \(id) not found",
            context: ["nodeId": id.uuidString]
        )
    }
    
    /// Edge not found error
    public static func edgeNotFound(id: UUID) -> FlowError {
        FlowError(
            code: .edgeNotFound,
            message: "Edge with ID \(id) not found",
            context: ["edgeId": id.uuidString]
        )
    }
    
    /// Invalid connection error
    public static func invalidConnection(reason: String) -> FlowError {
        FlowError(
            code: .connectionInvalid,
            message: "Invalid connection: \(reason)"
        )
    }
    
    /// Connection already exists error
    public static func connectionExists() -> FlowError {
        FlowError(
            code: .connectionExists,
            message: "Connection already exists between these nodes"
        )
    }
    
    /// Connection would create cycle error
    public static func connectionCycle() -> FlowError {
        FlowError(
            code: .connectionCycle,
            message: "Connection would create a cycle in the graph"
        )
    }
    
    /// Port not found error
    public static func portNotFound(id: UUID) -> FlowError {
        FlowError(
            code: .portNotFound,
            message: "Port with ID \(id) not found",
            context: ["portId": id.uuidString]
        )
    }
    
    /// Zoom out of bounds error
    public static func zoomOutOfBounds(value: CGFloat, min: CGFloat, max: CGFloat) -> FlowError {
        FlowError(
            code: .zoomOutOfBounds,
            message: "Zoom value \(value) is outside allowed range [\(min), \(max)]",
            context: [
                "value": "\(value)",
                "min": "\(min)",
                "max": "\(max)"
            ]
        )
    }
    
    /// Command failed error
    public static func commandFailed(reason: String) -> FlowError {
        FlowError(
            code: .commandFailed,
            message: "Command execution failed: \(reason)"
        )
    }
    
    /// Operation not allowed error
    public static func operationNotAllowed(reason: String) -> FlowError {
        FlowError(
            code: .operationNotAllowed,
            message: "Operation not allowed: \(reason)"
        )
    }
}

// MARK: - Error Checking Utilities

/// Check if an error matches a specific error code
/// - Parameters:
///   - error: Error to check
///   - code: Error code to match
/// - Returns: True if error matches code
public func isErrorOfType(_ error: Error, code: ErrorCode) -> Bool {
    guard let flowError = error as? FlowError else { return false }
    return flowError.code == code
}

/// Extract FlowError from any error
/// - Parameter error: Error to extract from
/// - Returns: FlowError if available, nil otherwise
public func asFlowError(_ error: Error) -> FlowError? {
    return error as? FlowError
}
