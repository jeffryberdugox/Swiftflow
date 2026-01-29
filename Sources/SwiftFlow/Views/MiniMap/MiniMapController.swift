//
//  MiniMapController.swift
//  SwiftFlow
//
//  Controller for minimap calculations.
//  Separates the camera model from the view to fix bounds calculation issues.
//
//  FIXES INCLUDED:
//  ✅ Viewport indicator updates in realtime (no throttle)
//  ✅ Bounds/scale/offset updates are throttled, BUT force-refit immediately when stale
//  ✅ Prevents "giant blue indicator" when viewport changes before bounds catch up
//  ✅ Keeps the "chever" auto-adjust effect (bounds update lags slightly unless required)
//

import Foundation
import SwiftUI
import Combine

@MainActor
public final class MiniMapController: ObservableObject {

    // MARK: - Inputs (set externally)

    /// Bounds of all nodes in canvas coordinates.
    /// Set this when nodes change (add/remove/move/resize).
    public var nodesBounds: CanvasRect = .zero {
        didSet {
            guard nodesBounds != oldValue else { return }
            // Bounds can change a lot when moving nodes; throttle is fine
            scheduleBoundsUpdate(reason: .nodesChanged, immediate: false)
        }
    }

    /// Current viewport rectangle in canvas coordinates.
    /// Set this on every pan/zoom tick for realtime indicator.
    public var viewportRectCanvas: CanvasRect = .zero {
        didSet {
            guard viewportRectCanvas != oldValue else { return }

            // ✅ 1) Always update indicator in realtime
            updateIndicatorNow()

            // ✅ 2) If current bounds/scale are stale and viewport doesn't fit,
            // force an IMMEDIATE refit to avoid "giant blue rect"
            if shouldForceImmediateRefit(for: viewportRectCanvas) {
                scheduleBoundsUpdate(reason: .hysteresisTriggered, immediate: true)
                updateIndicatorNow() // recompute after new scale/offset
                return
            }

            // ✅ 3) Otherwise keep the "chever" behavior (lazy refit)
            maybeScheduleAutoFitIfNeeded()
        }
    }

    /// Size of the minimap view in points.
    public var miniMapSize: CGSize = CGSize(width: 200, height: 150) {
        didSet {
            guard miniMapSize != oldValue else { return }
            scheduleBoundsUpdate(reason: .miniMapResized, immediate: true)
        }
    }

    /// Padding around content in the minimap.
    public var contentPadding: CGFloat = 20 {
        didSet {
            guard contentPadding != oldValue else { return }
            scheduleBoundsUpdate(reason: .paddingChanged, immediate: true)
        }
    }

    // MARK: - Outputs (published for view)

    /// Combined bounds of nodes and viewport in canvas coordinates.
    @Published public private(set) var contentBounds: CanvasRect = .zero

    /// Scale factor from canvas coordinates to minimap coordinates.
    @Published public private(set) var scale: CGFloat = 1.0

    /// Offset to apply when rendering in minimap coordinates.
    @Published public private(set) var offset: CGPoint = .zero

    /// Frame of the viewport indicator in minimap coordinates.
    @Published public private(set) var viewportIndicatorFrame: CGRect = .zero

    // MARK: - Throttling

    private var boundsUpdateTask: Task<Void, Never>?
    private let boundsUpdateThrottle: TimeInterval = 1.0 / 30.0 // 30 FPS max for bounds

    // Optional: keep a small hysteresis so bounds doesn't refit constantly.
    private let autoFitMarginFactor: CGFloat = 0.15 // 15% margin outside current bounds triggers refit

    // MARK: - Initialization

    public init() {}

    public init(miniMapSize: CGSize, contentPadding: CGFloat = 20) {
        self.miniMapSize = miniMapSize
        self.contentPadding = contentPadding
    }

    // MARK: - Update Scheduling

    private enum UpdateReason {
        case nodesChanged
        case viewportMoved
        case miniMapResized
        case paddingChanged
        case hysteresisTriggered
        case autoFit
    }

    private func scheduleBoundsUpdate(reason: UpdateReason, immediate: Bool) {
        boundsUpdateTask?.cancel()

        if immediate {
            recalculateBoundsScaleOffset()
            return
        }

        boundsUpdateTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(boundsUpdateThrottle))
            guard !Task.isCancelled else { return }
            recalculateBoundsScaleOffset()
        }
    }

    /// Force an immediate recalculation (bypasses throttling).
    public func forceUpdate() {
        boundsUpdateTask?.cancel()
        recalculateBoundsScaleOffset()
        updateIndicatorNow()
    }

    // MARK: - Core Calculation (Bounds/Scale/Offset)

    private func recalculateBoundsScaleOffset() {
        // 1) Pad nodes bounds (or default area)
        let paddedNodesBounds: CGRect
        if nodesBounds.isEmpty {
            paddedNodesBounds = CGRect(
                x: -100 - contentPadding,
                y: -100 - contentPadding,
                width: 200 + contentPadding * 2,
                height: 200 + contentPadding * 2
            )
        } else {
            paddedNodesBounds = nodesBounds.cgRect.insetBy(dx: -contentPadding, dy: -contentPadding)
        }

        // 2) Always include viewport
        let viewportRect = viewportRectCanvas.cgRect
        let combinedBounds: CGRect

        if viewportRect.isEmpty || viewportRect.isNull || viewportRect.isInfinite {
            combinedBounds = paddedNodesBounds
        } else {
            combinedBounds = paddedNodesBounds.union(viewportRect)
        }

        // Update published content bounds
        contentBounds = CanvasRect(combinedBounds)

        // 3) Compute scale
        guard combinedBounds.width > 0, combinedBounds.height > 0 else {
            scale = 1.0
            offset = .zero
            viewportIndicatorFrame = .zero
            return
        }

        let scaleX = miniMapSize.width / combinedBounds.width
        let scaleY = miniMapSize.height / combinedBounds.height
        scale = min(scaleX, scaleY)

        // 4) Compute offset (center content + translate origin)
        let scaledWidth = combinedBounds.width * scale
        let scaledHeight = combinedBounds.height * scale

        offset = CGPoint(
            x: (miniMapSize.width - scaledWidth) / 2 - combinedBounds.origin.x * scale,
            y: (miniMapSize.height - scaledHeight) / 2 - combinedBounds.origin.y * scale
        )

        // 5) Indicator uses current scale/offset
        updateIndicatorNow()
    }

    // MARK: - Realtime Indicator Update

    private func updateIndicatorNow() {
        let vp = viewportRectCanvas.cgRect
        guard scale > 0, !vp.isEmpty, !vp.isNull, !vp.isInfinite else {
            viewportIndicatorFrame = .zero
            return
        }

        viewportIndicatorFrame = CGRect(
            x: vp.origin.x * scale + offset.x,
            y: vp.origin.y * scale + offset.y,
            width: vp.width * scale,
            height: vp.height * scale
        )
    }

    // MARK: - Auto-fit Logic (the "chever" effect)

    /// If viewport goes outside contentBounds by a margin, schedule a throttled refit.
    private func maybeScheduleAutoFitIfNeeded() {
        let vp = viewportRectCanvas.cgRect
        guard !vp.isEmpty, !vp.isNull, !vp.isInfinite else { return }
        let cb = contentBounds.cgRect
        guard !cb.isEmpty else {
            scheduleBoundsUpdate(reason: .autoFit, immediate: true)
            return
        }

        // Expand current bounds by a margin so we don't refit constantly
        let marginX = cb.width * autoFitMarginFactor
        let marginY = cb.height * autoFitMarginFactor
        let cbWithMargin = cb.insetBy(dx: -marginX, dy: -marginY)

        // If viewport escapes margin, refit (throttled)
        if !cbWithMargin.contains(vp) {
            scheduleBoundsUpdate(reason: .autoFit, immediate: false)
        }
    }

    // MARK: - Critical Fix: Detect stale scale/bounds (giant indicator prevention)

    private func shouldForceImmediateRefit(for viewport: CanvasRect) -> Bool {
        let vp = viewport.cgRect

        // If we still have no valid world, we must fit immediately
        if contentBounds.isEmpty || contentBounds.cgRect.width <= 0 || contentBounds.cgRect.height <= 0 {
            return !vp.isEmpty
        }

        // If viewport is invalid, don't refit
        if vp.isEmpty || vp.isNull || vp.isInfinite {
            return false
        }

        let cb = contentBounds.cgRect

        // If the viewport isn't contained, our bounds may be stale (especially first update)
        if !cb.contains(vp) {
            return true
        }

        // Safety: if indicator would exceed minimap size, it's definitely stale
        if scale > 0 {
            let indicatorW = vp.width * scale
            let indicatorH = vp.height * scale
            if indicatorW > miniMapSize.width * 1.05 || indicatorH > miniMapSize.height * 1.05 {
                return true
            }
        }

        return false
    }

    // MARK: - Coordinate Conversion

    /// Convert a point in minimap coordinates to canvas coordinates.
    /// Used when the user clicks/drags on the minimap.
    public func miniMapToCanvas(_ point: CGPoint) -> CanvasPoint {
        CanvasPoint(
            x: (point.x - offset.x) / scale,
            y: (point.y - offset.y) / scale
        )
    }

    /// Convert a point in canvas coordinates to minimap coordinates.
    public func canvasToMiniMap(_ point: CanvasPoint) -> CGPoint {
        CGPoint(
            x: point.x * scale + offset.x,
            y: point.y * scale + offset.y
        )
    }

    /// Convert a canvas rectangle to minimap coordinates.
    public func canvasToMiniMap(_ rect: CanvasRect) -> CGRect {
        CGRect(
            x: rect.origin.x * scale + offset.x,
            y: rect.origin.y * scale + offset.y,
            width: rect.size.width * scale,
            height: rect.size.height * scale
        )
    }

    // MARK: - Interaction

    /// Calculate the new viewport center when user clicks/drags in minimap.
    public func calculateNewViewportCenter(from miniMapPoint: CGPoint) -> CanvasPoint {
        miniMapToCanvas(miniMapPoint)
    }

    /// Calculate pan delta to apply to main transform (screen coords).
    public func calculatePanDelta(from startMiniMap: CGPoint, to endMiniMap: CGPoint, mainScale: CGFloat) -> CGSize {
        let startCanvas = miniMapToCanvas(startMiniMap)
        let endCanvas = miniMapToCanvas(endMiniMap)

        // Delta in canvas coordinates
        let canvasDelta = CGSize(
            width: endCanvas.x - startCanvas.x,
            height: endCanvas.y - startCanvas.y
        )

        // Convert to screen coordinates (multiply by main canvas scale)
        return CGSize(
            width: -canvasDelta.width * mainScale,
            height: -canvasDelta.height * mainScale
        )
    }
}

// MARK: - Helper Extensions

private extension CGRect {
    var isInfinite: Bool {
        width.isInfinite || height.isInfinite ||
        origin.x.isInfinite || origin.y.isInfinite
    }
}