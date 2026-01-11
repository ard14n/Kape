import SwiftUI

public struct NeonGlow: ViewModifier {
    let color: Color
    let radius: CGFloat
    
    public func body(content: Content) -> some View {
        content
            .shadow(color: color, radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.5), radius: radius * 2, x: 0, y: 0)
    }
}

public extension View {
    func neonGlow(color: Color, radius: CGFloat = 10) -> some View {
        modifier(NeonGlow(color: color, radius: radius))
    }
    
    /// Standard primary neon style (white text with slight glow on dark background context)
    func electricStyle() -> some View {
        self
            .foregroundStyle(.white)
            .font(.system(.body, design: .rounded).weight(.bold))
    }
}
