import SwiftUI

struct VibeBackground: View {
    var body: some View {
        ZStack {
            Color.trueBlack.ignoresSafeArea()
            
            // Ambient gradient blob
            GeometryReader { proxy in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.neonPurple.opacity(0.15), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: proxy.size.width * 0.8
                        )
                    )
                    .frame(width: proxy.size.width * 1.5, height: proxy.size.width * 1.5)
                    .position(x: proxy.size.width * 0.8, y: proxy.size.height * 0.2)
                    .blur(radius: 60)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.neonBlue.opacity(0.1), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: proxy.size.width * 0.6
                        )
                    )
                    .frame(width: proxy.size.width, height: proxy.size.width)
                    .position(x: 0, y: proxy.size.height)
                    .blur(radius: 50)
            }
        }
    }
}

// Extension to add neonPurple if missing, or use fallback
extension Color {
    static let neonPurple = Color(hex: "#D000FF")
}

#Preview {
    VibeBackground()
}
