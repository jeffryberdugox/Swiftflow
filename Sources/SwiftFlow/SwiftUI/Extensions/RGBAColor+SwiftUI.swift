//
//  RGBAColor+SwiftUI.swift
//  SwiftFlow
//
//  SwiftUI extensions for RGBAColor.
//  Provides seamless conversion between RGBAColor (Core) and Color (SwiftUI).
//

import SwiftUI

// MARK: - RGBAColor to SwiftUI Color

public extension RGBAColor {
    
    /// Converts this RGBAColor to a SwiftUI Color.
    ///
    /// # Usage
    /// ```swift
    /// let rgba = RGBAColor(red: 0.5, green: 0.7, blue: 0.9)
    /// let swiftUIColor = rgba.color
    ///
    /// // Use in SwiftUI views
    /// Rectangle().fill(rgba.color)
    /// ```
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
    
    /// Creates an RGBAColor from a SwiftUI Color.
    ///
    /// Note: This requires resolving the color in an environment, which may not
    /// always produce exact results for dynamic colors (like `.primary`).
    ///
    /// # Usage
    /// ```swift
    /// let swiftUIColor = Color.blue
    /// let rgba = RGBAColor(swiftUIColor)
    /// ```
    ///
    /// - Parameter color: The SwiftUI Color to convert
    init(_ color: Color) {
        #if os(macOS)
        // On macOS, convert via NSColor
        let nsColor = NSColor(color)
        if let rgbColor = nsColor.usingColorSpace(.deviceRGB) {
            self.init(
                red: rgbColor.redComponent,
                green: rgbColor.greenComponent,
                blue: rgbColor.blueComponent,
                alpha: rgbColor.alphaComponent
            )
        } else {
            // Fallback for colors that can't be converted
            self.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        }
        #else
        // On iOS/tvOS/watchOS, use UIColor
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            self.init(red: red, green: green, blue: blue, alpha: alpha)
        } else {
            // Fallback for colors that can't be converted
            self.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        }
        #endif
    }
}

// MARK: - SwiftUI Color from RGBAColor

public extension Color {
    
    /// Creates a SwiftUI Color from an RGBAColor.
    ///
    /// # Usage
    /// ```swift
    /// let rgba = RGBAColor.blue.withAlpha(0.5)
    /// let color = Color(rgba)
    /// ```
    init(_ rgba: RGBAColor) {
        self.init(red: rgba.red, green: rgba.green, blue: rgba.blue, opacity: rgba.alpha)
    }
}

// MARK: - ShapeStyle Conformance

extension RGBAColor: ShapeStyle {
    
    /// Allows RGBAColor to be used directly as a ShapeStyle in SwiftUI.
    ///
    /// # Usage
    /// ```swift
    /// let strokeColor = RGBAColor.blue
    /// Circle().stroke(strokeColor, lineWidth: 2)
    /// ```
    public func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        self.color
    }
}

// MARK: - View Extension

public extension View {
    
    /// Sets the foreground color using an RGBAColor.
    func foregroundColor(_ rgba: RGBAColor) -> some View {
        self.foregroundColor(rgba.color)
    }
    
    /// Sets the background using an RGBAColor.
    func background(_ rgba: RGBAColor) -> some View {
        self.background(rgba.color)
    }
}

// MARK: - Shape Extension

public extension Shape {
    
    /// Fills the shape with an RGBAColor.
    func fill(_ rgba: RGBAColor) -> some View {
        self.fill(rgba.color)
    }
    
    /// Strokes the shape with an RGBAColor.
    func stroke(_ rgba: RGBAColor, lineWidth: CGFloat = 1) -> some View {
        self.stroke(rgba.color, lineWidth: lineWidth)
    }
}
