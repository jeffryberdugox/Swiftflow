//
//  CopyPasteManager.swift
//  SwiftFlow
//
//  Manager for copy/paste operations on nodes.
//

import Foundation
import AppKit

/// Manager for copy/paste operations
@MainActor
public class CopyPasteManager<Node: FlowNode, Edge: FlowEdge>: ObservableObject where Node: Codable, Edge: Codable {
    
    // Pasteboard
    private let pasteboard = NSPasteboard.general
    private let pasteboardType = NSPasteboard.PasteboardType("com.swiftflow.nodes")
    
    // State
    @Published public private(set) var clipboardNodes: [Node] = []
    @Published public private(set) var clipboardEdges: [Edge] = []
    
    // Offset for pasted nodes
    public var pasteOffset: CGSize = CGSize(width: 20, height: 20)
    
    public init() {}
    
    // MARK: - Copy
    
    /// Copy selected nodes and their edges
    public func copy(
        nodes: [Node],
        edges: [Edge],
        selectedNodeIds: Set<UUID>
    ) {
        let selectedNodes = nodes.filter { selectedNodeIds.contains($0.id) }
        
        // Get edges between selected nodes
        let selectedEdges = edges.filter { edge in
            selectedNodeIds.contains(edge.sourceNodeId) &&
            selectedNodeIds.contains(edge.targetNodeId)
        }
        
        clipboardNodes = selectedNodes
        clipboardEdges = selectedEdges
        
        // Write to system pasteboard
        do {
            let data = try JSONEncoder().encode(ClipboardData(
                nodes: selectedNodes,
                edges: selectedEdges
            ))
            
            pasteboard.clearContents()
            pasteboard.setData(data, forType: pasteboardType)
        } catch {
            print("Failed to copy nodes: \(error)")
        }
    }
    
    // MARK: - Cut
    
    /// Cut selected nodes (copy + mark for deletion)
    public func cut(
        nodes: [Node],
        edges: [Edge],
        selectedNodeIds: Set<UUID>
    ) -> (nodesToDelete: Set<UUID>, edgesToDelete: Set<UUID>) {
        copy(nodes: nodes, edges: edges, selectedNodeIds: selectedNodeIds)
        
        // Return IDs to delete
        let edgesToDelete = Set(clipboardEdges.map { $0.id })
        
        return (selectedNodeIds, edgesToDelete)
    }
    
    // MARK: - Paste
    
    /// Paste nodes from clipboard
    public func paste() -> (nodes: [Node], edges: [Edge])? {
        // Try to read from system pasteboard first
        if let data = pasteboard.data(forType: pasteboardType) {
            do {
                let clipboardData = try JSONDecoder().decode(ClipboardData<Node, Edge>.self, from: data)
                return createPastedNodes(from: clipboardData.nodes, edges: clipboardData.edges)
            } catch {
                print("Failed to paste nodes: \(error)")
            }
        }
        
        // Fall back to internal clipboard
        guard !clipboardNodes.isEmpty else { return nil }
        
        return createPastedNodes(from: clipboardNodes, edges: clipboardEdges)
    }
    
    private func createPastedNodes(
        from sourceNodes: [Node],
        edges sourceEdges: [Edge]
    ) -> (nodes: [Node], edges: [Edge]) {
        // Note: This function returns the source nodes/edges with offset positions
        // The actual ID changes must be handled by the application layer when adding nodes
        
        var newNodes: [Node] = []
        
        // Create new nodes with offset positions
        // IDs will remain the same - app should handle ID regeneration
        for sourceNode in sourceNodes {
            var newNode = sourceNode
            newNode.position = CGPoint(
                x: sourceNode.position.x + pasteOffset.width,
                y: sourceNode.position.y + pasteOffset.height
            )
            
            newNodes.append(newNode)
        }
        
        // Return edges as-is (app should handle ID regeneration)
        let newEdges = Array(sourceEdges)
        
        return (newNodes, newEdges)
    }
    
    // MARK: - Duplicate
    
    /// Duplicate selected nodes (copy + paste in one operation)
    public func duplicate(
        nodes: [Node],
        edges: [Edge],
        selectedNodeIds: Set<UUID>
    ) -> (nodes: [Node], edges: [Edge])? {
        copy(nodes: nodes, edges: edges, selectedNodeIds: selectedNodeIds)
        return paste()
    }
    
    // MARK: - Has Clipboard Data
    
    /// Check if there's data in clipboard
    public var hasClipboardData: Bool {
        return !clipboardNodes.isEmpty || pasteboard.data(forType: pasteboardType) != nil
    }
}

// MARK: - Clipboard Data Structure

private struct ClipboardData<Node: Codable, Edge: Codable>: Codable {
    let nodes: [Node]
    let edges: [Edge]
}

// MARK: - Notes
//
// Copy/Paste returns nodes and edges with adjusted positions but same IDs.
// The application layer is responsible for:
// 1. Generating new UUIDs for pasted nodes/edges
// 2. Updating edge references to new node IDs
// 3. Adding pasted items to the canvas
//
// This design is necessary because FlowNode and FlowEdge protocols
// have read-only ID properties.
