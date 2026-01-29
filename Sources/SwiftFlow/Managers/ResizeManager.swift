//
//  ResizeManager.swift
//  SwiftFlow
//
//  Manages node resize operations with aspect ratio preservation.
//

import Foundation
import SwiftUI
import Combine

/// Manages node resize operations
@MainActor
public class ResizeManager: ObservableObject {
    // MARK: - Published Properties

    /// Current resize state (nil if not resizing)
    @Published public private(set) var resizeState: ResizeState?

    // MARK: - Configuration

    /// Minimum distance before resize starts
    public var resizeThreshold: CGFloat

    /// Whether to preserve aspect ratio during resize
    public var preserveAspectRatio: Bool

    /// Minimum node size
    public var minNodeSize: CGSize

    // MARK: - Callbacks

    /// Called when resize starts
    public var onResizeStarted: ((UUID) -> Void)?

    /// Called during resize with new size
    public var onResizeChanged: ((UUID, CGSize) -> Void)?

    /// Called when resize ends with final size
    public var onResizeEnded: ((UUID, CGSize) -> Void)?

    /// Called to calculate helper lines during resize
    /// Returns snap offset to apply
    public var onCalculateHelperLines: ((UUID, CGPoint, CGSize) -> CGSize)?

    /// Called to clear helper lines when resize ends
    public var onClearHelperLines: (() -> Void)?

    // MARK: - Initialization

    public init(
        resizeThreshold: CGFloat = 3.0,
        preserveAspectRatio: Bool = true,
        minNodeSize: CGSize = CGSize(width: 50, height: 50)
    ) {
        self.resizeThreshold = resizeThreshold
        self.preserveAspectRatio = preserveAspectRatio
        self.minNodeSize = minNodeSize
    }

    // MARK: - Resize Operations

    /// Start a resize operation
    /// - Parameters:
    ///   - nodeId: ID of node to resize
    ///   - originalSize: Current size of the node
    ///   - startPoint: Starting point of resize drag in node-local coordinates
    ///   - anchor: Anchor point that stays fixed during resize
    public func startResize(
        nodeId: UUID,
        originalSize: CGSize,
        at startPoint: CGPoint,
        anchor: ResizeAnchor
    ) {
        resizeState = ResizeState(
            nodeId: nodeId,
            originalSize: originalSize,
            currentSize: originalSize,
            startPoint: startPoint,
            anchor: anchor,
            hasMoved: false,
            aspectRatio: originalSize.width / originalSize.height
        )

        onResizeStarted?(nodeId)
    }

    /// Update the resize with a new position
    /// - Parameter point: Current drag point in node-local coordinates
    public func updateResize(to point: CGPoint) {
        guard var state = resizeState else { return }

        // Calculate delta from start
        let delta = CGSize(
            width: point.x - state.startPoint.x,
            height: point.y - state.startPoint.y
        )

        // Check if we've moved beyond threshold
        if !state.hasMoved {
            let distance = sqrt(delta.width * delta.width + delta.height * delta.height)
            if distance < resizeThreshold {
                return
            }
            state.hasMoved = true
        }

        // Calculate new size based on anchor
        var newSize: CGSize

        switch state.anchor {
        case .topLeft:
            // Dragging from bottom-right
            newSize = CGSize(
                width: state.originalSize.width + delta.width,
                height: state.originalSize.height + delta.height
            )

        case .bottomRight:
            // Dragging from top-left
            newSize = CGSize(
                width: state.originalSize.width - delta.width,
                height: state.originalSize.height - delta.height
            )

        case .topRight:
            // Dragging from bottom-left
            newSize = CGSize(
                width: state.originalSize.width - delta.width,
                height: state.originalSize.height + delta.height
            )

        case .bottomLeft:
            // Dragging from top-right
            newSize = CGSize(
                width: state.originalSize.width + delta.width,
                height: state.originalSize.height - delta.height
            )

        default:
            // For edge anchors, calculate based on direction
            newSize = state.originalSize
        }

        // Apply aspect ratio preservation if enabled
        if preserveAspectRatio {
            // Use width as the primary dimension
            let scaleFactor = newSize.width / state.originalSize.width
            newSize.height = state.originalSize.height * scaleFactor
        }

        // Apply minimum size constraints
        newSize.width = max(newSize.width, minNodeSize.width)
        newSize.height = max(newSize.height, minNodeSize.height)

        // Calculate helper lines and snap offset (if enabled)
        if let helperLinesCallback = onCalculateHelperLines {
            // Calculate the new position based on current position and new size
            // This is used to check edge alignments
            let currentPosition = CGPoint.zero // Position is managed externally, we only care about size edges
            let snapOffset = helperLinesCallback(state.nodeId, currentPosition, newSize)

            // Apply snap offset to size (adjust edges to align)
            if snapOffset.width != 0 {
                newSize.width += snapOffset.width
                // Re-apply minimum constraint after snap
                newSize.width = max(newSize.width, minNodeSize.width)
            }
            if snapOffset.height != 0 {
                newSize.height += snapOffset.height
                // Re-apply minimum constraint after snap
                newSize.height = max(newSize.height, minNodeSize.height)
            }
        }

        // Only update if size actually changed (avoid unnecessary publishes)
        let sizeChanged = abs(newSize.width - state.currentSize.width) > 0.1 ||
                         abs(newSize.height - state.currentSize.height) > 0.1

        if sizeChanged {
            state.currentSize = newSize
            resizeState = state

            // Notify about size changes
            onResizeChanged?(state.nodeId, newSize)
        }
    }

    /// End the current resize operation
    /// - Returns: Final size, or nil if resize was cancelled
    @discardableResult
    public func endResize() -> CGSize? {
        guard let state = resizeState else { return nil }

        let finalSize = state.hasMoved ? state.currentSize : nil

        if let size = finalSize {
            onResizeEnded?(state.nodeId, size)
        }

        // Clear helper lines
        onClearHelperLines?()

        resizeState = nil
        return finalSize
    }

    /// Cancel the current resize operation without applying changes
    public func cancelResize() {
        // Clear helper lines
        onClearHelperLines?()

        resizeState = nil
    }

    // MARK: - Helpers

    /// Whether a resize is currently in progress
    public var isResizing: Bool {
        resizeState != nil
    }

    /// Whether the current resize has moved beyond threshold
    public var hasMoved: Bool {
        resizeState?.hasMoved ?? false
    }

    /// Get the current size preview for a node being resized
    /// - Parameter nodeId: ID of the node
    /// - Returns: Current preview size, or nil if not being resized
    public func currentSize(for nodeId: UUID) -> CGSize? {
        guard let state = resizeState,
              state.nodeId == nodeId,
              state.hasMoved else {
            return nil
        }
        return state.currentSize
    }
}

// MARK: - ResizeState

/// Represents the state of an active resize operation on a node
public struct ResizeState: Equatable, Sendable {
    /// ID of node being resized
    public var nodeId: UUID

    /// Original size when resize started
    public var originalSize: CGSize

    /// Current size during resize
    public var currentSize: CGSize

    /// Starting point of the resize drag in node-local coordinates
    public var startPoint: CGPoint

    /// Anchor point that stays fixed during resize
    public var anchor: ResizeAnchor

    /// Whether the resize has moved beyond the threshold
    public var hasMoved: Bool

    /// Original aspect ratio (width / height)
    public var aspectRatio: CGFloat

    public init(
        nodeId: UUID,
        originalSize: CGSize,
        currentSize: CGSize,
        startPoint: CGPoint,
        anchor: ResizeAnchor,
        hasMoved: Bool = false,
        aspectRatio: CGFloat
    ) {
        self.nodeId = nodeId
        self.originalSize = originalSize
        self.currentSize = currentSize
        self.startPoint = startPoint
        self.anchor = anchor
        self.hasMoved = hasMoved
        self.aspectRatio = aspectRatio
    }
}
