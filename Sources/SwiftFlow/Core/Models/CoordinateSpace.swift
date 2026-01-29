//
//  CoordinateSpace.swift
//  SwiftFlow
//
//  Formal documentation and utilities for the coordinate system.
//  Defines the three coordinate spaces used throughout SwiftFlow.
//

import Foundation
import CoreGraphics

// MARK: - Coordinate System Documentation

/*
 # SwiftFlow Coordinate System
 
 SwiftFlow uses three distinct coordinate spaces to manage positions, transforms, and interactions:
 
 ## 1. Canvas Space (Logical World)
 
 The **canvas space** is the logical coordinate system where all node positions and edge endpoints live.
 This space does NOT change when you zoom or pan - it's the "world" coordinate system.
 
 - **node.position**: Top-left corner of the node in canvas coordinates
 - **node.bounds**: Full rectangle from (position.x, position.y) to (position.x + width, position.y + height)
 - **node.center**: Center point calculated as (position.x + width/2, position.y + height/2)
 - **edge endpoints**: Absolute positions where connections attach to nodes
 - **Port positions**: Calculated as node.topLeft + portOffset (in node-local space)
 
 Canvas coordinates are used for:
 - Storing node positions in your data model
 - Calculating edge paths
 - Collision detection and bounds checking
 - Serialization/deserialization
 
 ## 2. Screen Space (Viewport)
 
 The **screen space** is the actual pixel/point coordinates in the SwiftUI view.
 This is what the user sees and where gestures (drag, tap, scroll) report their locations.
 
 - **Gesture locations**: DragGesture.value.location is in screen space (unless using coordinateSpace)
 - **Viewport size**: The visible area of the canvas
 - **Rendered positions**: Where nodes actually appear on screen after transform
 
 Screen coordinates are affected by:
 - Pan offset (translation)
 - Zoom scale
 - View hierarchy transforms
 
 ## 3. Node-Local Space
 
 The **node-local space** is relative to a node's top-left corner (position).
 This is used for ports, resize handles, and internal node layout.
 
 - **Port offsets**: Position relative to node's top-left
 - **Resize handles**: Positioned at corners/edges of the node rectangle
 - **Custom node content**: Layout within the node's bounds
 
 Node-local coordinates are in the range:
 - X: [0, node.width]
 - Y: [0, node.height]
 
 ---
 
 # Coordinate Transformations
 
 ## Canvas ↔ Screen (via FlowTransform)
 
 ```swift
 // Convert canvas point to screen
 let screenPoint = transform.canvasToScreen(canvasPoint)
 // Formula: screenPoint = canvasPoint * scale + offset
 
 // Convert screen point to canvas
 let canvasPoint = transform.screenToCanvas(screenPoint)
 // Formula: canvasPoint = (screenPoint - offset) / scale
 ```
 
 ## Node-Local ↔ Canvas
 
 ```swift
 // Convert node-local point to canvas
 let canvasPoint = transform.nodeLocalToCanvas(localPoint, nodeTopLeft: node.position)
 // Formula: canvasPoint = nodeTopLeft + localPoint
 
 // Convert canvas point to node-local
 let localPoint = transform.canvasToNodeLocal(canvasPoint, nodeTopLeft: node.position)
 // Formula: localPoint = canvasPoint - nodeTopLeft
 ```
 
 ---
 
 # Golden Rules
 
 1. **Always know which space you're in**: Name variables clearly (canvasPos, screenPos, nodeLocalPos)
 2. **Model = Canvas**: Your data model stores positions in canvas space only
 3. **Camera = Transform**: Pan/zoom only affects the FlowTransform, never the model
 4. **View = Model * Camera**: Rendered positions = canvas positions * transform
 5. **Input = View → Model**: Convert gesture locations to canvas before modifying nodes
 6. **Never mix spaces**: Always convert explicitly before calculations
 
 ---
 
 # Common Patterns
 
 ## Drag Node
 
 ```swift
 // 1. Start: capture initial positions in canvas space
 let initialNodePos = node.position  // canvas (top-left)
 let cursorCanvas = transform.screenToCanvas(gesture.startLocation)
 let offset = CGSize(
     width: initialNodePos.x - cursorCanvas.x,
     height: initialNodePos.y - cursorCanvas.y
 )
 
 // 2. Update: calculate new position in canvas space
 let newCursorCanvas = transform.screenToCanvas(gesture.location)
 node.position = CGPoint(
     x: newCursorCanvas.x + offset.width,
     y: newCursorCanvas.y + offset.height
 )
 ```
 
 ## Zoom with Pivot
 
 ```swift
 // Keep the point under the cursor fixed during zoom
 let pivotScreen = cursorLocation  // screen space
 let pivotCanvas = transform.screenToCanvas(pivotScreen)  // convert to canvas
 
 // Apply new scale
 let newScale = clamp(oldScale * zoomFactor, min: minZoom, max: maxZoom)
 
 // Adjust offset so pivotCanvas stays under pivotScreen
 let newOffset = pivotScreen - (pivotCanvas * newScale)
 transform = FlowTransform(offset: newOffset, scale: newScale)
 ```
 
 ## Calculate Port Position
 
 ```swift
 // 1. Get port offset in node-local space (from PortLayout)
 let nodeLocalOffset = port.layout.position(nodeSize: node.size)
 
 // 2. Convert to canvas space
 let portCanvasPos = CGPoint(
     x: node.position.x + nodeLocalOffset.x,
     y: node.position.y + nodeLocalOffset.y
 )
 
 // 3. Render: canvas to screen (done automatically by SwiftUI transform)
 let portScreenPos = transform.canvasToScreen(portCanvasPos)
 ```
 
 ## Box Selection
 
 ```swift
 // 1. Selection rectangle drawn in screen space
 let selectionRectScreen = CGRect(from: startScreen, to: endScreen)
 
 // 2. Convert to canvas space for comparison
 let selectionRectCanvas = transform.screenToCanvas(selectionRectScreen)
 
 // 3. Check intersection with node bounds (canvas space)
 for node in nodes {
     if node.bounds.intersects(selectionRectCanvas) {
         selectNode(node)
     }
 }
 ```
 
 ---
 
 # Debugging Checklist
 
 When you encounter coordinate bugs, ask:
 
 - [ ] Is this CGPoint in canvas, screen, or node-local space?
 - [ ] Did I convert before using it in calculations?
 - [ ] Am I mixing spaces (e.g., adding canvas offset to screen position)?
 - [ ] Does this gesture use the correct coordinateSpace?
 - [ ] Am I modifying the model (canvas) or the view (screen)?
 - [ ] During zoom, am I maintaining the correct pivot point?
 - [ ] For node-local calculations, am I using node.position (top-left) as the base?
 
 ---
 
 # Migration from Center-Anchored to Top-Left
 
 If you have code that assumed node.position was the center:
 
 ```swift
 // OLD (center-anchored):
 let leftEdge = node.position.x - node.width / 2
 let topEdge = node.position.y - node.height / 2
 let center = node.position
 
 // NEW (top-left anchored):
 let leftEdge = node.position.x  // position IS the top-left
 let topEdge = node.position.y
 let center = node.center  // calculated property
 ```
 
 */

// MARK: - Coordinate Conversion Extensions

public extension FlowTransform {
    // MARK: Node-Local Conversions
    
    /// Convert a point from node-local coordinates to canvas coordinates.
    /// - Parameters:
    ///   - localPoint: Point relative to node's top-left corner
    ///   - nodeTopLeft: The node's position (top-left) in canvas coordinates
    /// - Returns: Point in canvas coordinates
    func nodeLocalToCanvas(_ localPoint: CGPoint, nodeTopLeft: CGPoint) -> CGPoint {
        return CGPoint(
            x: nodeTopLeft.x + localPoint.x,
            y: nodeTopLeft.y + localPoint.y
        )
    }
    
    /// Convert a point from canvas coordinates to node-local coordinates.
    /// - Parameters:
    ///   - canvasPoint: Point in canvas coordinates
    ///   - nodeTopLeft: The node's position (top-left) in canvas coordinates
    /// - Returns: Point relative to node's top-left corner
    func canvasToNodeLocal(_ canvasPoint: CGPoint, nodeTopLeft: CGPoint) -> CGPoint {
        return CGPoint(
            x: canvasPoint.x - nodeTopLeft.x,
            y: canvasPoint.y - nodeTopLeft.y
        )
    }
    
    // MARK: Convenience Conversions
    
    /// Convert a point from node-local coordinates all the way to screen coordinates.
    /// - Parameters:
    ///   - localPoint: Point relative to node's top-left corner
    ///   - nodeTopLeft: The node's position (top-left) in canvas coordinates
    /// - Returns: Point in screen coordinates
    func nodeLocalToScreen(_ localPoint: CGPoint, nodeTopLeft: CGPoint) -> CGPoint {
        let canvasPoint = nodeLocalToCanvas(localPoint, nodeTopLeft: nodeTopLeft)
        return canvasToScreen(canvasPoint)
    }
    
    /// Convert a point from screen coordinates all the way to node-local coordinates.
    /// - Parameters:
    ///   - screenPoint: Point in screen coordinates
    ///   - nodeTopLeft: The node's position (top-left) in canvas coordinates
    /// - Returns: Point relative to node's top-left corner
    func screenToNodeLocal(_ screenPoint: CGPoint, nodeTopLeft: CGPoint) -> CGPoint {
        let canvasPoint = screenToCanvas(screenPoint)
        return canvasToNodeLocal(canvasPoint, nodeTopLeft: nodeTopLeft)
    }
}

// MARK: - Type-Safe Coordinates
// Note: CanvasPoint, ScreenPoint, CanvasRect, CanvasSize are defined in Core/Types/CoordinateTypes.swift
// The types provide type-safe coordinate wrappers with full functionality.
// See Core/Types/CoordinateTypes.swift for the complete implementations.
