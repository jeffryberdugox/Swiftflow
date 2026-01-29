//
//  ParentChildNodes.swift
//  SwiftFlow
//
//  Support for parent-child node hierarchy.
//

import Foundation
import CoreGraphics

/// Node extent configuration
public enum NodeExtent: Equatable, Codable, Sendable {
    /// Node is constrained within its parent bounds
    case parent

    /// Node is constrained within a specific coordinate rect
    case coordinates(CGRect)

    /// No constraints
    case none
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case type, rect
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "parent":
            self = .parent
        case "coordinates":
            let x = try container.decode(CGFloat.self, forKey: .rect)
            // Simplified for now
            self = .coordinates(CGRect(x: x, y: 0, width: 0, height: 0))
        default:
            self = .none
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .parent:
            try container.encode("parent", forKey: .type)
        case .coordinates(let rect):
            try container.encode("coordinates", forKey: .type)
            try container.encode(rect.origin.x, forKey: .rect)
        case .none:
            try container.encode("none", forKey: .type)
        }
    }
}

/// Node origin for positioning anchor
public struct NodeOrigin: Codable, Sendable {
    public var x: CGFloat
    public var y: CGFloat
    
    public init(x: CGFloat = 0, y: CGFloat = 0) {
        self.x = x
        self.y = y
    }
    
    /// Top-left origin [0, 0]
    public static let topLeft = NodeOrigin(x: 0, y: 0)
    
    /// Center origin [0.5, 0.5]
    public static let center = NodeOrigin(x: 0.5, y: 0.5)
    
    /// Top-center origin [0.5, 0]
    public static let topCenter = NodeOrigin(x: 0.5, y: 0)
}

/// Protocol extension for parent-child nodes
public protocol HierarchicalFlowNode: FlowNode {
    /// Parent node ID (nil for root nodes)
    var parentId: UUID? { get set }
    
    /// Node extent constraint
    var extent: NodeExtent { get set }
    
    /// Whether to expand parent when this node is moved outside
    var expandParent: Bool { get set }
    
    /// Node origin for positioning anchor
    var origin: NodeOrigin { get set }
    
    /// Z-index for layering
    var zIndex: Int { get set }
}

// Default implementations
public extension HierarchicalFlowNode {
    var parentId: UUID? {
        get { nil }
        set { }
    }
    
    var extent: NodeExtent {
        get { .none }
        set { }
    }
    
    var expandParent: Bool {
        get { false }
        set { }
    }
    
    var origin: NodeOrigin {
        get { .topLeft }
        set { }
    }
    
    var zIndex: Int {
        get { 0 }
        set { }
    }
}

// MARK: - Utility Functions

/// Calculate absolute position of a node considering parent hierarchy
public func calculateAbsolutePosition<Node: HierarchicalFlowNode>(
    node: Node,
    nodes: [Node]
) -> CGPoint {
    guard let parentId = node.parentId,
          let parent = nodes.first(where: { $0.id == parentId }) else {
        return node.position
    }
    
    // Recursively calculate parent's absolute position
    let parentAbsolutePos = calculateAbsolutePosition(node: parent, nodes: nodes)
    
    // Apply origin offset
    let originOffset = CGPoint(
        x: node.origin.x * node.width,
        y: node.origin.y * node.height
    )
    
    return CGPoint(
        x: parentAbsolutePos.x + node.position.x - originOffset.x,
        y: parentAbsolutePos.y + node.position.y - originOffset.y
    )
}

/// Get all child nodes of a parent
public func getChildNodes<Node: HierarchicalFlowNode>(
    of parentId: UUID,
    in nodes: [Node]
) -> [Node] {
    return nodes.filter { $0.parentId == parentId }
}

/// Get all descendant nodes (children, grandchildren, etc.)
public func getDescendantNodes<Node: HierarchicalFlowNode>(
    of parentId: UUID,
    in nodes: [Node]
) -> [Node] {
    var descendants: [Node] = []
    let children = getChildNodes(of: parentId, in: nodes)
    
    for child in children {
        descendants.append(child)
        descendants.append(contentsOf: getDescendantNodes(of: child.id, in: nodes))
    }
    
    return descendants
}

/// Check if node position is within extent constraints
public func isNodeWithinExtent<Node: HierarchicalFlowNode>(
    node: Node,
    nodes: [Node]
) -> Bool {
    switch node.extent {
    case .none:
        return true
        
    case .parent:
        guard let parentId = node.parentId,
              let parent = nodes.first(where: { $0.id == parentId }) else {
            return true
        }
        
        let nodeRect = CGRect(
            x: node.position.x,
            y: node.position.y,
            width: node.width,
            height: node.height
        )
        
        let parentRect = CGRect(
            x: 0,
            y: 0,
            width: parent.width,
            height: parent.height
        )
        
        return parentRect.contains(nodeRect)
        
    case .coordinates(let rect):
        let nodeRect = CGRect(
            x: node.position.x,
            y: node.position.y,
            width: node.width,
            height: node.height
        )
        
        return rect.contains(nodeRect)
    }
}

/// Constrain node position to extent
public func constrainNodeToExtent<Node: HierarchicalFlowNode>(
    node: inout Node,
    nodes: [Node]
) {
    switch node.extent {
    case .none:
        break

    case .parent:
        guard let parentId = node.parentId,
              let parent = nodes.first(where: { $0.id == parentId }) else {
            break
        }

        node.position.x = max(0, min(parent.width - node.width, node.position.x))
        node.position.y = max(0, min(parent.height - node.height, node.position.y))

    case .coordinates(let rect):
        node.position.x = max(rect.minX, min(rect.maxX - node.width, node.position.x))
        node.position.y = max(rect.minY, min(rect.maxY - node.height, node.position.y))
    }
}

/// Find which group node (if any) contains the given point.
/// Returns the group node that contains the point, excluding the dragged nodes themselves.
/// If multiple groups overlap, returns the one with the highest z-index.
public func findGroupContainingPoint<Node: HierarchicalFlowNode>(
    _ point: CGPoint,
    in allNodes: [Node],
    excluding excludedIds: Set<UUID> = []
) -> Node? {
    // Filter to potential parent nodes (not excluded, and larger than typical child)
    let potentialParents = allNodes.filter { node in
        !excludedIds.contains(node.id) &&
        node.width >= 200 && node.height >= 150 // Groups are typically larger
    }

    // Find all groups that contain the point
    var containingGroups: [(node: Node, zIndex: Int)] = []

    for node in potentialParents {
        let absolutePos = calculateAbsolutePosition(node: node, nodes: allNodes)
        let nodeBounds = CGRect(
            x: absolutePos.x,
            y: absolutePos.y,
            width: node.width,
            height: node.height
        )

        if nodeBounds.contains(point) {
            containingGroups.append((node: node, zIndex: node.zIndex))
        }
    }

    // Return the group with highest z-index (top-most)
    return containingGroups
        .sorted { $0.zIndex > $1.zIndex }
        .first?
        .node
}

/// Convert absolute position to relative position within a parent node.
public func toRelativePosition<Node: HierarchicalFlowNode>(
    absolutePosition: CGPoint,
    parent: Node,
    allNodes: [Node]
) -> CGPoint {
    let parentAbsolute = calculateAbsolutePosition(node: parent, nodes: allNodes)
    return CGPoint(
        x: absolutePosition.x - parentAbsolute.x,
        y: absolutePosition.y - parentAbsolute.y
    )
}

/// Check if any parent of the node is selected.
/// This is critical for drag operations: if a parent is being dragged,
/// don't drag the child separately (it moves automatically with parent).
public func isParentSelected<Node: HierarchicalFlowNode>(
    _ nodeId: UUID,
    selectedNodes: Set<UUID>,
    allNodes: [Node]
) -> Bool {
    var visitedIds = Set<UUID>()
    return isParentSelectedRecursive(nodeId, selectedNodes: selectedNodes, allNodes: allNodes, visitedIds: &visitedIds)
}

private func isParentSelectedRecursive<Node: HierarchicalFlowNode>(
    _ nodeId: UUID,
    selectedNodes: Set<UUID>,
    allNodes: [Node],
    visitedIds: inout Set<UUID>
) -> Bool {
    // Avoid infinite loops
    guard !visitedIds.contains(nodeId) else {
        return false
    }
    visitedIds.insert(nodeId)

    guard let node = allNodes.first(where: { $0.id == nodeId }),
          let parentId = node.parentId else {
        return false
    }

    // If parent is selected, return true
    if selectedNodes.contains(parentId) {
        return true
    }

    // Check grandparent recursively
    return isParentSelectedRecursive(parentId, selectedNodes: selectedNodes, allNodes: allNodes, visitedIds: &visitedIds)
}

// MARK: - Automatic Parent-Child Detection

/// Result of checking if a node should become a child of a group
public struct ParentChildUpdate {
    /// The new parent ID (nil if should be root)
    public let newParentId: UUID?

    /// The new position (relative if has parent, absolute if root)
    public let newPosition: CGPoint

    /// The new extent
    public let newExtent: NodeExtent

    /// Whether the update changed anything
    public var hasChanges: Bool {
        return true // Always return true for now, caller can compare
    }
}

/// Automatically detect if a node should become a child of a group based on its position.
/// This is called when a node is dropped after dragging.
///
/// Logic:
/// - If the node's center is inside a group → make it a child
/// - If the node was a child and is now outside → make it root
/// - Automatically converts positions between absolute and relative
///
/// - Parameters:
///   - nodeId: ID of the node that was dragged
///   - finalPosition: Final absolute position where the node was dropped
///   - allNodes: All nodes in the canvas
/// - Returns: Update information with new parent and position
public func detectParentChildRelationship<Node: HierarchicalFlowNode>(
    for nodeId: UUID,
    at finalPosition: CGPoint,
    in allNodes: [Node]
) -> ParentChildUpdate? {
    guard let node = allNodes.first(where: { $0.id == nodeId }) else {
        print("❌ Detection: Node not found with id \(nodeId)")
        return nil
    }

    // Calculate node bounds (use boundaries instead of center)
    let nodeBounds = CGRect(
        x: finalPosition.x,
        y: finalPosition.y,
        width: node.width,
        height: node.height
    )

    print("🔍 Detection: Node bounds: x=\(finalPosition.x), y=\(finalPosition.y), size: \(node.width)x\(node.height)")

    // Count potential parents
    let potentialParents = allNodes.filter { n in
        n.id != nodeId && n.width >= 200 && n.height >= 150
    }
    print("🔍 Detection: Found \(potentialParents.count) potential parent nodes")

    // Find if there's a group containing this node
    // Use overlap detection: node must be at least 50% inside the group
    var bestParent: Node? = nil
    var bestOverlapArea: CGFloat = 0
    var bestZIndex: Int = -1

    for potentialParent in potentialParents {
        let parentAbsolute = calculateAbsolutePosition(node: potentialParent, nodes: allNodes)
        let parentBounds = CGRect(
            x: parentAbsolute.x,
            y: parentAbsolute.y,
            width: potentialParent.width,
            height: potentialParent.height
        )

        // Calculate intersection (overlap)
        let intersection = nodeBounds.intersection(parentBounds)

        if !intersection.isNull {
            let overlapArea = intersection.width * intersection.height
            let nodeArea = nodeBounds.width * nodeBounds.height
            let overlapPercentage = overlapArea / nodeArea

            print("   Checking parent: overlap=\(Int(overlapPercentage * 100))%, z=\(potentialParent.zIndex)")

            // Require at least 50% overlap to consider as parent
            if overlapPercentage >= 0.5 {
                // Choose parent with highest z-index (topmost)
                if potentialParent.zIndex > bestZIndex || (potentialParent.zIndex == bestZIndex && overlapArea > bestOverlapArea) {
                    bestParent = potentialParent
                    bestOverlapArea = overlapArea
                    bestZIndex = potentialParent.zIndex
                }
            }
        }
    }

    let newParent = bestParent

    if let parent = newParent {
        let nodeArea = nodeBounds.width * nodeBounds.height
        let overlapPct = Int((bestOverlapArea / nodeArea) * 100)
        print("🎯 Detection: Found parent! Size: \(parent.width)x\(parent.height), overlap: \(overlapPct)%")
    } else {
        print("🎯 Detection: No parent found - will be root node (< 50% overlap)")
    }

    // Determine new parent ID
    let newParentId = newParent?.id

    // Calculate new position (relative if has parent, absolute if root)
    let newPosition: CGPoint
    let newExtent: NodeExtent

    if let parent = newParent {
        // Becoming a child - convert to relative position
        newPosition = toRelativePosition(
            absolutePosition: finalPosition,
            parent: parent,
            allNodes: allNodes
        )
        newExtent = .parent // Constrain within parent
        print("🎯 Detection: Converting to relative position: \(newPosition)")
    } else {
        // Becoming root - keep absolute position
        newPosition = finalPosition
        newExtent = .none // No constraints
    }

    return ParentChildUpdate(
        newParentId: newParentId,
        newPosition: newPosition,
        newExtent: newExtent
    )
}

/// Apply a parent-child update to a node.
/// This modifies the node in place.
public func applyParentChildUpdate<Node: HierarchicalFlowNode>(
    to node: inout Node,
    update: ParentChildUpdate
) {
    node.parentId = update.newParentId
    node.position = update.newPosition
    node.extent = update.newExtent
}
