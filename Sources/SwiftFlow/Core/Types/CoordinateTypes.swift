//
//  CoordinateTypes.swift
//  SwiftFlow
//
//  Type-safe coordinate types to prevent mixing screen and canvas coordinates.
//  These types are opt-in for power users who want compile-time safety.
//

import Foundation
import CoreGraphics

// MARK: - CanvasPoint

/// Point in canvas coordinate space where nodes live.
/// Origin is top-left of the infinite canvas, Y increases downward.
///
/// # Coordinate System
/// - Canvas coordinates are independent of zoom/pan state
/// - Node positions are stored in canvas coordinates
/// - (0, 0) is the canvas origin, not the viewport origin
///
/// # Usage
/// ```swift
/// let nodePosition = CanvasPoint(x: 100, y: 200)
/// let cgPoint = nodePosition.cgPoint  // Convert to CGPoint
/// ```
public struct CanvasPoint: Equatable, Sendable, Hashable, Codable {
    
    /// X coordinate in canvas space
    public var x: CGFloat
    
    /// Y coordinate in canvas space
    public var y: CGFloat
    
    // MARK: - Initialization
    
    /// Creates a canvas point with the specified coordinates.
    public init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }
    
    /// Creates a canvas point from a CGPoint.
    public init(_ point: CGPoint) {
        self.x = point.x
        self.y = point.y
    }
    
    // MARK: - Conversion
    
    /// Converts to CGPoint for use with CoreGraphics/SwiftUI APIs.
    public var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
    
    // MARK: - Presets
    
    /// The origin point (0, 0)
    public static let zero = CanvasPoint(x: 0, y: 0)
    
    // MARK: - Operations
    
    /// Returns a point offset by the given delta.
    public func offset(by delta: CGSize) -> CanvasPoint {
        CanvasPoint(x: x + delta.width, y: y + delta.height)
    }
    
    /// Returns a point offset by dx and dy.
    public func offset(dx: CGFloat, dy: CGFloat) -> CanvasPoint {
        CanvasPoint(x: x + dx, y: y + dy)
    }
    
    /// Calculates the distance to another canvas point.
    public func distance(to other: CanvasPoint) -> CGFloat {
        let dx = other.x - x
        let dy = other.y - y
        return sqrt(dx * dx + dy * dy)
    }
    
    /// Returns the midpoint between this point and another.
    public func midpoint(to other: CanvasPoint) -> CanvasPoint {
        CanvasPoint(
            x: (x + other.x) / 2,
            y: (y + other.y) / 2
        )
    }
}

// MARK: - ScreenPoint

/// Point in screen coordinate space where user interacts.
/// Origin is top-left of the viewport, Y increases downward.
///
/// # Coordinate System
/// - Screen coordinates are relative to the viewport
/// - Mouse/touch positions are in screen coordinates
/// - Screen coordinates change when the user pans/zooms
///
/// # Special Values
/// - `.viewportCenter` is a sentinel value meaning "center of current viewport"
///
/// # Usage
/// ```swift
/// let clickPosition = ScreenPoint(x: 400, y: 300)
/// controller.zoomIn(at: .viewportCenter)  // Zoom at viewport center
/// ```
public struct ScreenPoint: Equatable, Sendable, Hashable, Codable {
    
    /// X coordinate in screen space
    public var x: CGFloat
    
    /// Y coordinate in screen space
    public var y: CGFloat
    
    // MARK: - Initialization
    
    /// Creates a screen point with the specified coordinates.
    public init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }
    
    /// Creates a screen point from a CGPoint.
    public init(_ point: CGPoint) {
        self.x = point.x
        self.y = point.y
    }
    
    // MARK: - Conversion
    
    /// Converts to CGPoint for use with CoreGraphics/SwiftUI APIs.
    public var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
    
    // MARK: - Presets
    
    /// The origin point (0, 0)
    public static let zero = ScreenPoint(x: 0, y: 0)
    
    /// Sentinel value meaning "center of viewport".
    /// Used as default anchor for zoom operations.
    public static let viewportCenter = ScreenPoint(x: .nan, y: .nan)
    
    // MARK: - Checks
    
    /// Returns true if this point represents the viewport center sentinel.
    public var isViewportCenter: Bool {
        x.isNaN && y.isNaN
    }
    
    // MARK: - Operations
    
    /// Returns a point offset by the given delta.
    public func offset(by delta: CGSize) -> ScreenPoint {
        ScreenPoint(x: x + delta.width, y: y + delta.height)
    }
    
    /// Returns a point offset by dx and dy.
    public func offset(dx: CGFloat, dy: CGFloat) -> ScreenPoint {
        ScreenPoint(x: x + dx, y: y + dy)
    }
    
    /// Calculates the distance to another screen point.
    public func distance(to other: ScreenPoint) -> CGFloat {
        let dx = other.x - x
        let dy = other.y - y
        return sqrt(dx * dx + dy * dy)
    }
}

// MARK: - CanvasRect

/// Rectangle in canvas coordinate space.
/// Used to represent node bounds, selection areas, etc.
///
/// # Coordinate System
/// - Origin is at top-left of the rectangle
/// - Size extends rightward and downward
public struct CanvasRect: Equatable, Sendable, Hashable, Codable {
    
    /// Top-left origin of the rectangle
    public var origin: CanvasPoint
    
    /// Size of the rectangle
    public var size: CGSize
    
    // MARK: - Initialization
    
    /// Creates a canvas rectangle with the specified origin and size.
    public init(origin: CanvasPoint, size: CGSize) {
        self.origin = origin
        self.size = size
    }
    
    /// Creates a canvas rectangle from a CGRect.
    public init(_ rect: CGRect) {
        self.origin = CanvasPoint(rect.origin)
        self.size = rect.size
    }
    
    /// Creates a canvas rectangle with individual components.
    public init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        self.origin = CanvasPoint(x: x, y: y)
        self.size = CGSize(width: width, height: height)
    }
    
    // MARK: - Conversion
    
    /// Converts to CGRect for use with CoreGraphics/SwiftUI APIs.
    public var cgRect: CGRect {
        CGRect(origin: origin.cgPoint, size: size)
    }
    
    // MARK: - Presets
    
    /// A zero-sized rectangle at the origin
    public static let zero = CanvasRect(origin: .zero, size: .zero)
    
    // MARK: - Computed Properties
    
    /// The x-coordinate of the left edge
    public var minX: CGFloat { origin.x }
    
    /// The x-coordinate of the right edge
    public var maxX: CGFloat { origin.x + size.width }
    
    /// The y-coordinate of the top edge
    public var minY: CGFloat { origin.y }
    
    /// The y-coordinate of the bottom edge
    public var maxY: CGFloat { origin.y + size.height }
    
    /// The width of the rectangle
    public var width: CGFloat { size.width }
    
    /// The height of the rectangle
    public var height: CGFloat { size.height }
    
    /// The center point of the rectangle
    public var center: CanvasPoint {
        CanvasPoint(
            x: origin.x + size.width / 2,
            y: origin.y + size.height / 2
        )
    }
    
    /// Whether the rectangle has zero or negative size
    public var isEmpty: Bool {
        size.width <= 0 || size.height <= 0
    }
    
    // MARK: - Operations
    
    /// Returns true if this rectangle contains the specified point.
    public func contains(_ point: CanvasPoint) -> Bool {
        point.x >= minX && point.x <= maxX &&
        point.y >= minY && point.y <= maxY
    }
    
    /// Returns true if this rectangle intersects with another.
    public func intersects(_ other: CanvasRect) -> Bool {
        cgRect.intersects(other.cgRect)
    }
    
    /// Returns the union of this rectangle with another.
    public func union(_ other: CanvasRect) -> CanvasRect {
        CanvasRect(cgRect.union(other.cgRect))
    }
    
    /// Returns a rectangle inset by the specified amounts.
    public func insetBy(dx: CGFloat, dy: CGFloat) -> CanvasRect {
        CanvasRect(cgRect.insetBy(dx: dx, dy: dy))
    }
    
    /// Returns a rectangle expanded by the specified padding.
    public func expanded(by padding: CGFloat) -> CanvasRect {
        insetBy(dx: -padding, dy: -padding)
    }
}

// MARK: - ScreenRect

/// Rectangle in screen coordinate space.
/// Used to represent viewport bounds, hit areas, etc.
public struct ScreenRect: Equatable, Sendable, Hashable, Codable {
    
    /// Top-left origin of the rectangle
    public var origin: ScreenPoint
    
    /// Size of the rectangle
    public var size: CGSize
    
    // MARK: - Initialization
    
    /// Creates a screen rectangle with the specified origin and size.
    public init(origin: ScreenPoint, size: CGSize) {
        self.origin = origin
        self.size = size
    }
    
    /// Creates a screen rectangle from a CGRect.
    public init(_ rect: CGRect) {
        self.origin = ScreenPoint(rect.origin)
        self.size = rect.size
    }
    
    // MARK: - Conversion
    
    /// Converts to CGRect for use with CoreGraphics/SwiftUI APIs.
    public var cgRect: CGRect {
        CGRect(origin: origin.cgPoint, size: size)
    }
    
    // MARK: - Presets
    
    /// A zero-sized rectangle at the origin
    public static let zero = ScreenRect(origin: .zero, size: .zero)
    
    // MARK: - Computed Properties
    
    /// The center point of the rectangle
    public var center: ScreenPoint {
        ScreenPoint(
            x: origin.x + size.width / 2,
            y: origin.y + size.height / 2
        )
    }
}

// MARK: - CanvasSize

/// Size in canvas coordinate space.
/// Used when you need to distinguish canvas sizes from screen sizes.
public struct CanvasSize: Equatable, Sendable, Hashable, Codable {
    
    /// Width in canvas units
    public var width: CGFloat
    
    /// Height in canvas units
    public var height: CGFloat
    
    // MARK: - Initialization
    
    public init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
    }
    
    public init(_ size: CGSize) {
        self.width = size.width
        self.height = size.height
    }
    
    // MARK: - Conversion
    
    public var cgSize: CGSize {
        CGSize(width: width, height: height)
    }
    
    // MARK: - Presets
    
    public static let zero = CanvasSize(width: 0, height: 0)
}

// MARK: - CustomStringConvertible

extension CanvasPoint: CustomStringConvertible {
    public var description: String {
        "CanvasPoint(x: \(String(format: "%.1f", x)), y: \(String(format: "%.1f", y)))"
    }
}

extension ScreenPoint: CustomStringConvertible {
    public var description: String {
        if isViewportCenter {
            return "ScreenPoint.viewportCenter"
        }
        return "ScreenPoint(x: \(String(format: "%.1f", x)), y: \(String(format: "%.1f", y)))"
    }
}

extension CanvasRect: CustomStringConvertible {
    public var description: String {
        "CanvasRect(x: \(String(format: "%.1f", origin.x)), y: \(String(format: "%.1f", origin.y)), w: \(String(format: "%.1f", size.width)), h: \(String(format: "%.1f", size.height)))"
    }
}
