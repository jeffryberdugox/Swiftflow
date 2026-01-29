import SwiftUI
import Combine

public struct CanvasGridView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let transform: FlowTransform
    var gridSize: CGFloat
    var lineWidth: CGFloat
    var pattern: GridPattern
    var gridStyle: GridStyle
    
    // MARK: - Constants
    private let minDesiredSize: CGFloat = 16
    private let maxDesiredSize: CGFloat = 32
    private let minOpacity: Double = 0.8
    private let maxOpacity: Double = 1.0
    
    // MARK: - State
    @State private var revealProgress: Double = 0
    
    public init(transform: FlowTransform, config: GridConfig) {
        self.transform = transform
        self.gridSize = config.size
        self.lineWidth = config.style.lineWidth
        self.pattern = config.pattern
        self.gridStyle = config.style
    }
    
    // MARK: - Color Resolution
    
    /// Resolves an adaptive color mode to a concrete SwiftUI Color based on current color scheme
    private func resolveColor(from mode: GridColorMode) -> Color {
        switch mode {
        case .adaptive:
            // Adaptive defaults based on current color scheme
            if colorScheme == .dark {
                return Color.white.opacity(0.1)
            } else {
                return Color.gray.opacity(0.2)
            }
            
        case .fixed(let light, let dark):
            // User-defined light/dark colors
            return colorScheme == .dark ? dark.color : light.color
            
        case .staticColor(let rgba):
            // Static color (same in both themes)
            return rgba.color
        }
    }
    
    /// Resolves background color from mode
    private func resolveBackgroundColor(from mode: GridColorMode) -> Color {
        switch mode {
        case .adaptive:
            // Use system semantic colors for true adaptive behavior
            if colorScheme == .dark {
                return Color(nsColor: .init(white: 0.15, alpha: 1.0))
            } else {
                return Color(nsColor: .controlBackgroundColor)
            }
            
        case .fixed(let light, let dark):
            return colorScheme == .dark ? dark.color : light.color
            
        case .staticColor(let rgba):
            return rgba.color
        }
    }
    
    public var body: some View {
        Canvas { context, size in
            drawGrid(context: context, size: size)
        }
        .opacity(revealProgress)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                revealProgress = 1.0
            }
        }
    }
    
    // MARK: - Adaptive Grid Size
    
    private func calculateAdaptiveGridSize(baseGridSize: CGFloat, scale: CGFloat) -> CGFloat {
        if scale >= 0.9 { return baseGridSize }
        if scale >= 0.4 { return baseGridSize * 2 }
        if scale >= 0.2 { return baseGridSize * 4 }
        if scale >= 0.1 { return baseGridSize * 8 }
        return baseGridSize * 16
    }
    
    // MARK: - Density Compensated Opacity
    
    private func calculateDensityOpacity(adaptiveGridSize: CGFloat, scale: CGFloat) -> Double {
        let currentVisualSize = adaptiveGridSize * scale
        
        if currentVisualSize >= maxDesiredSize { return maxOpacity }
        if currentVisualSize <= minDesiredSize { return minOpacity }
        
        let ratio = (currentVisualSize - minDesiredSize) / (maxDesiredSize - minDesiredSize)
        return minOpacity + ratio * (maxOpacity - minOpacity)
    }
    
    // MARK: - Positive Modulo
    
    private func positiveModulo(_ value: CGFloat, _ divisor: CGFloat) -> CGFloat {
        guard divisor != 0 && divisor.isFinite else { return 0 }
        return ((value.truncatingRemainder(dividingBy: divisor)) + divisor)
            .truncatingRemainder(dividingBy: divisor)
    }
    
    // MARK: - Grid Drawing
    
    private func drawGrid(context: GraphicsContext, size: CGSize) {
        guard pattern != .none else { return }
        
        // Step 1: Calculate adaptive grid size
        let adaptiveGridSize = calculateAdaptiveGridSize(
            baseGridSize: gridSize,
            scale: transform.scale
        )
        let scaledGridSize = adaptiveGridSize * transform.scale
        
        // Step 2: Early exit if too small
        guard scaledGridSize >= 5 else { return }
        
        // Step 3: Calculate density-compensated opacity
        let densityOpacity = calculateDensityOpacity(
            adaptiveGridSize: adaptiveGridSize,
            scale: transform.scale
        )
        
        guard densityOpacity > 0.01 else { return }
        
        // Step 4: Calculate offsets with positive modulo
        let offsetX = positiveModulo(transform.offset.x, scaledGridSize)
        let offsetY = positiveModulo(transform.offset.y, scaledGridSize)
        
        // Step 5: Resolve grid color and apply fade
        let resolvedGridColor = resolveColor(from: gridStyle.lineColorMode)
        let fadedColor = resolvedGridColor.opacity(densityOpacity)
        
        // Step 6: Draw pattern
        switch pattern {
        case .dots:
            drawDotsPattern(
                context: context,
                size: size,
                scaledGridSize: scaledGridSize,
                offsetX: offsetX,
                offsetY: offsetY,
                color: fadedColor
            )
        case .lines:
            drawLinesPattern(
                context: context,
                size: size,
                scaledGridSize: scaledGridSize,
                offsetX: offsetX,
                offsetY: offsetY,
                color: fadedColor
            )
        case .minimalist:
            drawMinimalistPattern(
                context: context,
                size: size,
                scaledGridSize: scaledGridSize,
                offsetX: offsetX,
                offsetY: offsetY,
                color: fadedColor
            )
        case .none:
            break
        }
    }
    
    // MARK: - Pattern Implementations
    
    private func drawDotsPattern(
        context: GraphicsContext,
        size: CGSize,
        scaledGridSize: CGFloat,
        offsetX: CGFloat,
        offsetY: CGFloat,
        color: Color
    ) {
        let dotRadius = max(1.5, lineWidth * 1.5)
        
        var x = offsetX
        while x < size.width + dotRadius {
            var y = offsetY
            while y < size.height + dotRadius {
                let rect = CGRect(
                    x: x - dotRadius,
                    y: y - dotRadius,
                    width: dotRadius * 2,
                    height: dotRadius * 2
                )
                context.fill(Path(ellipseIn: rect), with: .color(color))
                y += scaledGridSize
            }
            x += scaledGridSize
        }
        
        // Draw major dots if zoomed in enough
        if scaledGridSize >= 10 {
            drawMajorDots(
                context: context,
                size: size,
                scaledGridSize: scaledGridSize,
                color: color
            )
        }
    }
    
    private func drawMajorDots(
        context: GraphicsContext,
        size: CGSize,
        scaledGridSize: CGFloat,
        color: Color
    ) {
        let majorGridSize = scaledGridSize * 5
        let majorOffsetX = positiveModulo(transform.offset.x, majorGridSize)
        let majorOffsetY = positiveModulo(transform.offset.y, majorGridSize)
        let majorDotRadius = max(1.5, lineWidth * 1.5) * 1.5
        let majorColor = color.opacity(1.5)
        
        var x = majorOffsetX
        while x < size.width {
            var y = majorOffsetY
            while y < size.height {
                let rect = CGRect(
                    x: x - majorDotRadius,
                    y: y - majorDotRadius,
                    width: majorDotRadius * 2,
                    height: majorDotRadius * 2
                )
                context.fill(Path(ellipseIn: rect), with: .color(majorColor))
                y += majorGridSize
            }
            x += majorGridSize
        }
    }
    
    private func drawLinesPattern(
        context: GraphicsContext,
        size: CGSize,
        scaledGridSize: CGFloat,
        offsetX: CGFloat,
        offsetY: CGFloat,
        color: Color
    ) {
        // Vertical lines
        var x = offsetX
        while x < size.width {
            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(path, with: .color(color), lineWidth: lineWidth)
            x += scaledGridSize
        }
        
        // Horizontal lines
        var y = offsetY
        while y < size.height {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(path, with: .color(color), lineWidth: lineWidth)
            y += scaledGridSize
        }
      
    }
    
    private func drawMinimalistPattern(
        context: GraphicsContext,
        size: CGSize,
        scaledGridSize: CGFloat,
        offsetX: CGFloat,
        offsetY: CGFloat,
        color: Color
    ) {
        let majorGridSize = scaledGridSize * 5
        let majorOffsetX = positiveModulo(transform.offset.x, majorGridSize)
        let majorOffsetY = positiveModulo(transform.offset.y, majorGridSize)
        let subtleColor = color.opacity(0.5)
        let subtleLineWidth = lineWidth * 0.75
        
        var x = majorOffsetX
        while x < size.width {
            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(path, with: .color(subtleColor), lineWidth: subtleLineWidth)
            x += majorGridSize
        }
        
        var y = majorOffsetY
        while y < size.height {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(path, with: .color(subtleColor), lineWidth: subtleLineWidth)
            y += majorGridSize
        }
    }
}

// MARK: - Preview

#Preview("Dots Pattern") {
    CanvasGridView(
        transform: FlowTransform(),
        config: GridConfig(pattern: .dots)
    )
    .frame(width: 400, height: 300)
}

#Preview("Lines Pattern") {
    CanvasGridView(
        transform: FlowTransform(),
        config: GridConfig(pattern: .lines)
    )
    .frame(width: 400, height: 300)
}

#Preview("Minimalist Pattern") {
    CanvasGridView(
        transform: FlowTransform(),
        config: GridConfig(pattern: .minimalist)
    )
    .frame(width: 400, height: 300)
}
