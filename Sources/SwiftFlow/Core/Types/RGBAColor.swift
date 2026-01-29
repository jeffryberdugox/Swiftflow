//
//  RGBAColor.swift
//  SwiftFlow
//
//  Color representation for Core layer (no SwiftUI dependency).
//  This allows the Core layer to remain pure Swift without UI framework imports.
//

import Foundation
import CoreGraphics

/// Platform-independent color representation using RGBA components.
/// Used in Core layer to avoid SwiftUI dependency while maintaining color information.
///
/// # Usage
/// ```swift
/// let color = RGBAColor(red: 0.5, green: 0.7, blue: 0.9, alpha: 1.0)
/// let grayWithAlpha = RGBAColor.gray.withAlpha(0.5)
/// ```
///
/// # SwiftUI Integration
/// Convert to SwiftUI Color using the extension in `RGBAColor+SwiftUI.swift`:
/// ```swift
/// let swiftUIColor = rgbaColor.color
/// ```
public struct RGBAColor: Equatable, Sendable, Codable, Hashable {
    
    // MARK: - Properties
    
    /// Red component (0.0 - 1.0)
    public var red: CGFloat
    
    /// Green component (0.0 - 1.0)
    public var green: CGFloat
    
    /// Blue component (0.0 - 1.0)
    public var blue: CGFloat
    
    /// Alpha component (0.0 = transparent, 1.0 = opaque)
    public var alpha: CGFloat
    
    // MARK: - Initialization
    
    /// Creates a color with the specified RGBA components.
    /// - Parameters:
    ///   - red: Red component (0.0 - 1.0)
    ///   - green: Green component (0.0 - 1.0)
    ///   - blue: Blue component (0.0 - 1.0)
    ///   - alpha: Alpha component (0.0 - 1.0), defaults to 1.0 (fully opaque)
    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1.0) {
        self.red = red.clamped(to: 0...1)
        self.green = green.clamped(to: 0...1)
        self.blue = blue.clamped(to: 0...1)
        self.alpha = alpha.clamped(to: 0...1)
    }
    
    /// Creates a grayscale color.
    /// - Parameters:
    ///   - white: Grayscale value (0.0 = black, 1.0 = white)
    ///   - alpha: Alpha component, defaults to 1.0
    public init(white: CGFloat, alpha: CGFloat = 1.0) {
        self.init(red: white, green: white, blue: white, alpha: alpha)
    }
    
    /// Creates a color from a hex string.
    /// - Parameter hex: Hex color string (e.g., "#FF5733" or "FF5733")
    public init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let length = hexSanitized.count
        
        switch length {
        case 6: // RGB
            self.init(
                red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat(rgb & 0x0000FF) / 255.0,
                alpha: 1.0
            )
        case 8: // RGBA
            self.init(
                red: CGFloat((rgb & 0xFF000000) >> 24) / 255.0,
                green: CGFloat((rgb & 0x00FF0000) >> 16) / 255.0,
                blue: CGFloat((rgb & 0x0000FF00) >> 8) / 255.0,
                alpha: CGFloat(rgb & 0x000000FF) / 255.0
            )
        default:
            return nil
        }
    }
    
    // MARK: - Preset Colors
    
    /// Fully transparent color
    public static let clear = RGBAColor(red: 0, green: 0, blue: 0, alpha: 0)
    
    /// Black color
    public static let black = RGBAColor(red: 0, green: 0, blue: 0)
    
    /// White color
    public static let white = RGBAColor(red: 1, green: 1, blue: 1)
    
    /// Medium gray color (50% white)
    public static let gray = RGBAColor(red: 0.5, green: 0.5, blue: 0.5)
    
    /// Light gray color (75% white)
    public static let lightGray = RGBAColor(red: 0.75, green: 0.75, blue: 0.75)
    
    /// Dark gray color (25% white)
    public static let darkGray = RGBAColor(red: 0.25, green: 0.25, blue: 0.25)
    
    /// Red color
    public static let red = RGBAColor(red: 1, green: 0, blue: 0)
    
    /// Green color
    public static let green = RGBAColor(red: 0, green: 1, blue: 0)
    
    /// Blue color
    public static let blue = RGBAColor(red: 0, green: 0, blue: 1)
    
    /// Yellow color
    public static let yellow = RGBAColor(red: 1, green: 1, blue: 0)
    
    /// Cyan color
    public static let cyan = RGBAColor(red: 0, green: 1, blue: 1)
    
    /// Magenta color
    public static let magenta = RGBAColor(red: 1, green: 0, blue: 1)
    
    /// Orange color
    public static let orange = RGBAColor(red: 1, green: 0.5, blue: 0)
    
    // MARK: - Transformations
    
    /// Returns a new color with the specified alpha value.
    /// - Parameter alpha: New alpha value (0.0 - 1.0)
    /// - Returns: New color with modified alpha
    public func withAlpha(_ alpha: CGFloat) -> RGBAColor {
        RGBAColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /// Returns a lighter version of the color.
    /// - Parameter amount: Amount to lighten (0.0 - 1.0), defaults to 0.2
    /// - Returns: Lighter color
    public func lightened(by amount: CGFloat = 0.2) -> RGBAColor {
        RGBAColor(
            red: min(red + amount, 1.0),
            green: min(green + amount, 1.0),
            blue: min(blue + amount, 1.0),
            alpha: alpha
        )
    }
    
    /// Returns a darker version of the color.
    /// - Parameter amount: Amount to darken (0.0 - 1.0), defaults to 0.2
    /// - Returns: Darker color
    public func darkened(by amount: CGFloat = 0.2) -> RGBAColor {
        RGBAColor(
            red: max(red - amount, 0.0),
            green: max(green - amount, 0.0),
            blue: max(blue - amount, 0.0),
            alpha: alpha
        )
    }
    
    // MARK: - Hex Conversion
    
    /// Returns the color as a hex string (without alpha).
    public var hexString: String {
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    
    /// Returns the color as a hex string with alpha.
    public var hexStringWithAlpha: String {
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        let a = Int(alpha * 255)
        return String(format: "#%02X%02X%02X%02X", r, g, b, a)
    }
}

// MARK: - CGFloat Extension

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - CustomStringConvertible

extension RGBAColor: CustomStringConvertible {
    public var description: String {
        "RGBAColor(r: \(String(format: "%.2f", red)), g: \(String(format: "%.2f", green)), b: \(String(format: "%.2f", blue)), a: \(String(format: "%.2f", alpha)))"
    }
}
