import SwiftUI

public struct NeonGlow: ViewModifier {
    let color: Color
    let radius: CGFloat
    let intensity: Double
    
    public func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(intensity), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(intensity * 0.4), radius: radius * 1.5, x: 0, y: 0)
    }
}

public extension View {
    /// Standard neon glow effect.
    /// - Parameters:
    ///   - color: The glow color.
    ///   - radius: The blur radius. Default is 8 (reduced from 10 for subtlety).
    ///   - intensity: Opacity multiplier (0.0-1.0). Default is 0.8.
    func neonGlow(color: Color, radius: CGFloat = 8, intensity: Double = 0.8) -> some View {
        modifier(NeonGlow(color: color, radius: radius, intensity: intensity))
    }
    
    /// A subtle neon glow for text headers (reduced bloom).
    func subtleGlow(color: Color) -> some View {
        modifier(NeonGlow(color: color, radius: 4, intensity: 0.5))
    }
    
    /// Standard primary neon style (white text with slight glow on dark background context)
    func electricStyle() -> some View {
        self
            .foregroundStyle(.white)
            .font(.system(.body, design: .rounded).weight(.bold))
    }
}
