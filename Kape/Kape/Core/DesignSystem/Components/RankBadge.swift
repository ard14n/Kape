import SwiftUI

/// Brutalist-styled rank badge with neon glow and optional bounce animation
/// Architecture: Core/DesignSystem/Components/RankBadge.swift
/// Reusable for ResultScreen and ShareImage (Story 3.3)
struct RankBadge: View {
    let rank: Rank
    
    /// Optional rotation angle in degrees (per UX spec brutalist styling)
    var rotation: Double = -3
    
    var body: some View {
        Text(rank.title)
            .font(.system(size: 34, weight: .heavy, design: .rounded))
            .foregroundColor(rank.color)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(rank.color, lineWidth: 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.trueBlack.opacity(0.8))
                    )
            )
            .rotationEffect(.degrees(rotation))
            .neonGlow(color: rank.color, radius: 15)
    }
}

#Preview("Legjendë") {
    ZStack {
        Color.trueBlack.ignoresSafeArea()
        RankBadge(rank: .legjende)
    }
}

#Preview("Shqipe") {
    ZStack {
        Color.trueBlack.ignoresSafeArea()
        RankBadge(rank: .shqipe)
    }
}

#Preview("Turist") {
    ZStack {
        Color.trueBlack.ignoresSafeArea()
        RankBadge(rank: .mishIHuaj)
    }
}
