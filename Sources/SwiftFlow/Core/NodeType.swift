//
//  NodeType.swift
//  SwiftFlow
//
//  System for registering and using custom node types.
//

import SwiftUI

/// Type-erased wrapper for node view builders
public struct NodeTypeBuilder {
    let id: String
    let build: (any FlowNode, Bool) -> AnyView
    
    public init<Node: FlowNode, Content: View>(
        id: String,
        @ViewBuilder builder: @escaping (Node, Bool) -> Content
    ) {
        self.id = id
        self.build = { node, isSelected in
            if let typedNode = node as? Node {
                return AnyView(builder(typedNode, isSelected))
            }
            return AnyView(Text("Invalid Node Type"))
        }
    }
}

/// Registry for custom node types
public class NodeTypeRegistry {
    public static let shared = NodeTypeRegistry()
    
    private var nodeTypes: [String: NodeTypeBuilder] = [:]
    private let lock = NSLock()
    
    private init() {
        // Register default types
        registerDefaultTypes()
    }
    
    /// Register a custom node type
    public func register<Node: FlowNode, Content: View>(
        type: String,
        @ViewBuilder builder: @escaping (Node, Bool) -> Content
    ) {
        lock.lock()
        defer { lock.unlock() }
        
        nodeTypes[type] = NodeTypeBuilder(id: type, builder: builder)
    }
    
    /// Get a node type builder
    public func get(type: String) -> NodeTypeBuilder? {
        lock.lock()
        defer { lock.unlock() }
        
        return nodeTypes[type]
    }
    
    /// Build a view for a node
    public func buildView<Node: FlowNode>(
        for node: Node,
        type: String,
        isSelected: Bool
    ) -> AnyView {
        if let builder = get(type: type) {
            return builder.build(node, isSelected)
        }
        
        // Fallback to default
        if let defaultBuilder = get(type: "default") {
            return defaultBuilder.build(node, isSelected)
        }
        
        return AnyView(Text("Unknown Node Type: \(type)"))
    }
    
    /// Register default node types
    private func registerDefaultTypes() {
        // We use a workaround for type-erased nodes
        // The views accept any FlowNode, so we create a dummy type
        struct AnyNode: FlowNode {
            let id: UUID
            var position: CGPoint
            var width: CGFloat
            var height: CGFloat
            var isDraggable: Bool
            var isSelectable: Bool
            var inputPorts: [any FlowPort]
            var outputPorts: [any FlowPort]
        }
        
        // Default node
        nodeTypes["default"] = NodeTypeBuilder(id: "default") { (node: AnyNode, isSelected: Bool) in
            DefaultNodeView(node: node, isSelected: isSelected)
        }
        
        // Input node
        nodeTypes["input"] = NodeTypeBuilder(id: "input") { (node: AnyNode, isSelected: Bool) in
            InputNodeView(node: node, isSelected: isSelected)
        }
        
        // Output node
        nodeTypes["output"] = NodeTypeBuilder(id: "output") { (node: AnyNode, isSelected: Bool) in
            OutputNodeView(node: node, isSelected: isSelected)
        }
        
        // Group node
        nodeTypes["group"] = NodeTypeBuilder(id: "group") { (node: AnyNode, isSelected: Bool) in
            GroupNodeView(node: node, isSelected: isSelected)
        }
    }
}

// MARK: - Global Registration Function

/// Register a custom node type globally
public func registerNodeType<Node: FlowNode, Content: View>(
    _ type: String,
    @ViewBuilder builder: @escaping (Node, Bool) -> Content
) {
    NodeTypeRegistry.shared.register(type: type, builder: builder)
}

// MARK: - Node Type Protocol Extension

/// Protocol for nodes that have a type string
public protocol TypedFlowNode: FlowNode {
    var nodeType: String { get }
}

public extension TypedFlowNode {
    /// Default node type
    var nodeType: String { "default" }
}
