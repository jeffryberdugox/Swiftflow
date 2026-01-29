//
//  HelperLinesManager.swift
//  SwiftFlow
//
//  Manages helper lines (alignment guides) calculation during node dragging.
//

import Foundation
import SwiftUI
import Combine

/// Manages helper lines calculation and state
@MainActor
public class HelperLinesManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current horizontal guide positions (Y in canvas coords)
    @Published public private(set) var horizontalGuides: [CGFloat] = []
    
    /// Current vertical guide positions (X in canvas coords)
    @Published public private(set) var verticalGuides: [CGFloat] = []
    
    /// Current snap offset to apply
    @Published public private(set) var snapOffset: CGSize = .zero
    
    /// Whether guides are currently visible
    @Published public private(set) var isActive: Bool = false
    
    /// Whether snap occurred in current drag (for haptic feedback)
    @Published public private(set) var didSnap: Bool = false
    
    // MARK: - Configuration
    
    /// Helper lines configuration
    public var config: HelperLinesConfig
    
    // MARK: - Callbacks
    
    /// Called when alignment changes
    public var onAlignmentChanged: ((AlignmentResult) -> Void)?
    
    /// Called when snap occurs (for haptic feedback)
    public var onSnapOccurred: (() -> Void)?
    
    // MARK: - Initialization
    
    public init(config: HelperLinesConfig = .default) {
        self.config = config
    }
    
    // MARK: - Alignment Calculation
    
    /// Calculate alignments for dragged nodes against other nodes
    public func calculateAlignments<Node: FlowNode>(
        draggedNodeIds: Set<UUID>,
        currentPositions: [UUID: CGPoint],
        nodeSizes: [UUID: CGSize],
        allNodes: [Node]
    ) -> AlignmentResult {
        guard config.enabled else { return .empty }
        
        var hGuides: Set<CGFloat> = []
        var vGuides: Set<CGFloat> = []
        var bestSnapX: CGFloat? = nil
        var bestSnapY: CGFloat? = nil
        var minDistX: CGFloat = config.threshold
        var minDistY: CGFloat = config.threshold
        
        // Get reference nodes (not being dragged)
        let referenceNodes = allNodes.filter { !draggedNodeIds.contains($0.id) }
        
        for draggedId in draggedNodeIds {
            guard let draggedPos = currentPositions[draggedId],
                  let draggedSize = nodeSizes[draggedId] else { continue }
            
            let draggedBounds = NodeBounds(position: draggedPos, size: draggedSize)
            
            for refNode in referenceNodes {
                let refBounds = NodeBounds(
                    position: refNode.position,
                    size: CGSize(width: refNode.width, height: refNode.height)
                )
                
                // Check vertical alignments (X axis)
                if config.showEdgeGuides {
                    checkAlignment(draggedBounds.left, refBounds.left, threshold: config.threshold,
                                   guides: &vGuides, bestSnap: &bestSnapX, minDist: &minDistX)
                    checkAlignment(draggedBounds.left, refBounds.right, threshold: config.threshold,
                                   guides: &vGuides, bestSnap: &bestSnapX, minDist: &minDistX)
                    checkAlignment(draggedBounds.right, refBounds.left, threshold: config.threshold,
                                   guides: &vGuides, bestSnap: &bestSnapX, minDist: &minDistX)
                    checkAlignment(draggedBounds.right, refBounds.right, threshold: config.threshold,
                                   guides: &vGuides, bestSnap: &bestSnapX, minDist: &minDistX)
                }
                
                if config.showCenterGuides {
                    checkAlignment(draggedBounds.centerX, refBounds.centerX, threshold: config.threshold,
                                   guides: &vGuides, bestSnap: &bestSnapX, minDist: &minDistX)
                }
                
                // Check horizontal alignments (Y axis)
                if config.showEdgeGuides {
                    checkAlignment(draggedBounds.top, refBounds.top, threshold: config.threshold,
                                   guides: &hGuides, bestSnap: &bestSnapY, minDist: &minDistY)
                    checkAlignment(draggedBounds.top, refBounds.bottom, threshold: config.threshold,
                                   guides: &hGuides, bestSnap: &bestSnapY, minDist: &minDistY)
                    checkAlignment(draggedBounds.bottom, refBounds.top, threshold: config.threshold,
                                   guides: &hGuides, bestSnap: &bestSnapY, minDist: &minDistY)
                    checkAlignment(draggedBounds.bottom, refBounds.bottom, threshold: config.threshold,
                                   guides: &hGuides, bestSnap: &bestSnapY, minDist: &minDistY)
                }
                
                if config.showCenterGuides {
                    checkAlignment(draggedBounds.centerY, refBounds.centerY, threshold: config.threshold,
                                   guides: &hGuides, bestSnap: &bestSnapY, minDist: &minDistY)
                }
            }
        }
        
        let snapOff = config.snapToGuides
            ? CGSize(width: bestSnapX ?? 0, height: bestSnapY ?? 0)
            : .zero
        
        let result = AlignmentResult(
            horizontalGuides: Array(hGuides).sorted(),
            verticalGuides: Array(vGuides).sorted(),
            snapOffset: snapOff
        )
        
        // Detect if snap occurred
        let hasSnap = snapOff != .zero
        
        // Trigger haptic feedback on new snap (not continuous)
        if config.hapticFeedback && hasSnap && !didSnap {
            didSnap = true
            onSnapOccurred?()
        } else if !hasSnap {
            didSnap = false
        }
        
        // Update published state
        horizontalGuides = result.horizontalGuides
        verticalGuides = result.verticalGuides
        snapOffset = result.snapOffset
        isActive = result.hasAlignment
        
        onAlignmentChanged?(result)
        
        return result
    }
    
    /// Clear all guides (call when drag ends)
    public func clearGuides() {
        horizontalGuides = []
        verticalGuides = []
        snapOffset = .zero
        isActive = false
        didSnap = false
    }
    
    // MARK: - Private Helpers
    
    private func checkAlignment(
        _ draggedValue: CGFloat,
        _ refValue: CGFloat,
        threshold: CGFloat,
        guides: inout Set<CGFloat>,
        bestSnap: inout CGFloat?,
        minDist: inout CGFloat
    ) {
        let dist = abs(draggedValue - refValue)
        if dist < threshold {
            guides.insert(refValue)
            if dist < minDist {
                minDist = dist
                bestSnap = refValue - draggedValue
            }
        }
    }
}

// MARK: - NodeBounds Helper

private struct NodeBounds {
    let position: CGPoint
    let size: CGSize
    
    var left: CGFloat { position.x }
    var right: CGFloat { position.x + size.width }
    var top: CGFloat { position.y }
    var bottom: CGFloat { position.y + size.height }
    var centerX: CGFloat { position.x + size.width / 2 }
    var centerY: CGFloat { position.y + size.height / 2 }
}
