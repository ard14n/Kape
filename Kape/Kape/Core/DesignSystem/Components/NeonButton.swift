import SwiftUI

struct NeonButton: View {
    let title: String
    let icon: String?
    let color: Color
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, color: Color = .neonGreen, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                }
                Text(title)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color)
            .clipShape(Capsule())
            .neonGlow(color: color, intensity: 0.6)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            NeonButton("FILLO TURNEUN", icon: "play.fill", action: {})
            NeonButton("Turne i Ri", color: .neonBlue, action: {})
        }
        .padding()
    }
}
