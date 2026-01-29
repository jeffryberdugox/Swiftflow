//
//  CanvasEnvironment.swift
//  SwiftFlow
//
//  Bridge between user's data model and canvas controller.
//  Defines how the controller reads and writes node/edge data.
//

import Foundation

// MARK: - CanvasEnvironment

/// Bridge between user's data model and the canvas controller.
/// Provides a clear interface for reading and modifying nodes/edges.
///
/// # Design Principle
/// The user owns the data (nodes/edges arrays), and the controller operates
/// on that data through this environment. This keeps the source of truth
/// clear and makes undo/redo and batch updates easier to implement.
///
/// # Usage
/// ```swift
/// let environment = CanvasEnvironment(
///     getNodes: { nodes },
///     getEdges: { edges },
///     applyNodeEdits: { edits in
///         for edit in edits {
///             switch edit {
///             case .move(let id, let position):
///                 nodes[id]?.position = position
///             // ... handle other edits
///             }
///         }
///     },
///     applyEdgeEdits: { edits in
///         // ... handle edge edits
///     }
/// )
/// ```
public struct CanvasEnvironment<Node: FlowNode, Edge: FlowEdge> {
    
    // MARK: - Read Access
    
    /// Get current nodes (read-only snapshot)
    public var getNodes: () -> [Node]
    
    /// Get current edges (read-only snapshot)
    public var getEdges: () -> [Edge]
    
    // MARK: - Write Access
    
    /// Apply a batch of node edits.
    /// The controller calls this to modify nodes.
    public var applyNodeEdits: ([NodeEdit]) -> Void
    
    /// Apply a batch of edge edits.
    /// The controller calls this to modify edges.
    public var applyEdgeEdits: ([EdgeEdit]) -> Void
    
    // MARK: - Optional Callbacks
    
    /// Called when nodes are about to be deleted.
    /// Return false to cancel the deletion.
    public var willDeleteNodes: ((Set<UUID>) -> Bool)?
    
    /// Called when edges are about to be deleted.
    /// Return false to cancel the deletion.
    public var willDeleteEdges: ((Set<UUID>) -> Bool)?
    
    /// Called to validate a new connection before it's created.
    /// Return false to reject the connection.
    public var validateConnection: ((UUID, UUID, UUID, UUID) -> Bool)?
    
    // MARK: - Initialization
    
    /// Creates a canvas environment with the specified accessors.
    public init(
        getNodes: @escaping () -> [Node],
        getEdges: @escaping () -> [Edge],
        applyNodeEdits: @escaping ([NodeEdit]) -> Void,
        applyEdgeEdits: @escaping ([EdgeEdit]) -> Void,
        willDeleteNodes: ((Set<UUID>) -> Bool)? = nil,
        willDeleteEdges: ((Set<UUID>) -> Bool)? = nil,
        validateConnection: ((UUID, UUID, UUID, UUID) -> Bool)? = nil
    ) {
        self.getNodes = getNodes
        self.getEdges = getEdges
        self.applyNodeEdits = applyNodeEdits
        self.applyEdgeEdits = applyEdgeEdits
        self.willDeleteNodes = willDeleteNodes
        self.willDeleteEdges = willDeleteEdges
        self.validateConnection = validateConnection
    }
    
    // MARK: - Convenience Methods
    
    /// Get a node by ID
    public func node(id: UUID) -> Node? {
        getNodes().first { $0.id == id }
    }
    
    /// Get an edge by ID
    public func edge(id: UUID) -> Edge? {
        getEdges().first { $0.id == id }
    }
    
    /// Get edges connected to a node
    public func edges(connectedTo nodeId: UUID) -> [Edge] {
        getEdges().filter { $0.sourceNodeId == nodeId || $0.targetNodeId == nodeId }
    }
    
    /// Get edges from a specific source node
    public func edges(from nodeId: UUID) -> [Edge] {
        getEdges().filter { $0.sourceNodeId == nodeId }
    }
    
    /// Get edges to a specific target node
    public func edges(to nodeId: UUID) -> [Edge] {
        getEdges().filter { $0.targetNodeId == nodeId }
    }
}

// MARK: - Type-Erased Environment

/// Type-erased wrapper for CanvasEnvironment.
/// Used internally by the controller to avoid generic constraints.
public struct AnyCanvasEnvironment {
    
    /// Get nodes as AnyFlowNode array
    public let getNodes: () -> [AnyFlowNode]
    
    /// Get edges as type-erased array
    public let getEdges: () -> [any FlowEdge]
    
    /// Apply node edits
    public let applyNodeEdits: ([NodeEdit]) -> Void
    
    /// Apply edge edits
    public let applyEdgeEdits: ([EdgeEdit]) -> Void
    
    /// Validate connection
    public let validateConnection: ((UUID, UUID, UUID, UUID) -> Bool)?
    
    /// Creates a type-erased environment from a typed one
    public init<Node: FlowNode, Edge: FlowEdge>(_ environment: CanvasEnvironment<Node, Edge>) {
        self.getNodes = { environment.getNodes().map { AnyFlowNode($0) } }
        self.getEdges = { environment.getEdges() }
        self.applyNodeEdits = environment.applyNodeEdits
        self.applyEdgeEdits = environment.applyEdgeEdits
        self.validateConnection = environment.validateConnection
    }
}

// MARK: - Binding-Based Environment

/// Factory for creating CanvasEnvironment from SwiftUI Bindings
public enum CanvasEnvironmentFactory {
    
    /// Creates a CanvasEnvironment that works with SwiftUI @State/@Binding arrays.
    ///
    /// # Usage
    /// ```swift
    /// @State var nodes: [MyNode] = []
    /// @State var edges: [MyEdge] = []
    ///
    /// let environment = CanvasEnvironmentFactory.create(
    ///     nodes: $nodes,
    ///     edges: $edges
    /// )
    /// ```
    public static func create<Node: FlowNode, Edge: FlowEdge>(
        nodes: @escaping () -> [Node],
        edges: @escaping () -> [Edge],
        setNodes: @escaping ([Node]) -> Void,
        setEdges: @escaping ([Edge]) -> Void,
        createEdge: @escaping (UUID, UUID, UUID, UUID) -> Edge
    ) -> CanvasEnvironment<Node, Edge> where Node: Codable {
        
        CanvasEnvironment(
            getNodes: nodes,
            getEdges: edges,
            applyNodeEdits: { edits in
                var currentNodes = nodes()
                
                for edit in edits {
                    switch edit {
                    case .move(let id, let position):
                        if let index = currentNodes.firstIndex(where: { $0.id == id }) {
                            currentNodes[index].position = position
                        }
                        
                    case .resize(let id, let size):
                        if let index = currentNodes.firstIndex(where: { $0.id == id }) {
                            currentNodes[index].width = size.width
                            currentNodes[index].height = size.height
                        }
                        
                    case .delete(let id):
                        currentNodes.removeAll { $0.id == id }
                        
                    case .setParent(let id, let parentId):
                        if let index = currentNodes.firstIndex(where: { $0.id == id }) {
                            currentNodes[index].parentId = parentId
                        }
                        
                    case .setZIndex(let id, let zIndex):
                        if let index = currentNodes.firstIndex(where: { $0.id == id }) {
                            currentNodes[index].zIndex = zIndex
                        }
                        
                    case .add, .updateData:
                        // These require more context - handled by controller
                        break
                    }
                }
                
                setNodes(currentNodes)
            },
            applyEdgeEdits: { edits in
                var currentEdges = edges()
                
                for edit in edits {
                    switch edit {
                    case .create(_, let sourceNode, let sourcePort, let targetNode, let targetPort):
                        let newEdge = createEdge(sourceNode, sourcePort, targetNode, targetPort)
                        currentEdges.append(newEdge)
                        
                    case .delete(let id):
                        currentEdges.removeAll { $0.id == id }
                        
                    case .updateStyle:
                        // Style updates require StyledFlowEdge conformance
                        break
                    }
                }
                
                setEdges(currentEdges)
            }
        )
    }
}
