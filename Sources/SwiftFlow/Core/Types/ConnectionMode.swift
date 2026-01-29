//
//  ConnectionMode.swift
//  SwiftFlow
//
//  Defines how connections can be created between nodes.
//

import Foundation

/// Mode for creating connections between nodes
public enum ConnectionMode: Equatable, Sendable, Hashable, Codable {
    /// Connections can only be made from outputs to inputs (strict directionality)
    case strict
    
    /// Connections can be made in any direction (loose mode)
    case loose
    
    public static let `default`: ConnectionMode = .strict
}
