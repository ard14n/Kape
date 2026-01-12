import SwiftUI
import UIKit

/// Generates a shareable image of the tournament podium
@MainActor
final class PodiumImageGenerator {
    
    /// Generates a UIImage from the given players list (top 3)
    /// - Parameter players: List of players (expected to be sorted)
    /// - Returns: Rendered UIImage or nil if failed
    static func generate(from players: [Player]) async -> UIImage? {
        let exportView = PodiumExportView(players: Array(players.prefix(3)))
        
        // Use MainActor isolation to safely access UI properties
        let renderer = ImageRenderer(content: exportView)
        
        // Fix for deprecated UIScreen.main.scale
        // Fallback to 3.0 (high res) if no window scene found, typical for background generation
        let scale = await UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.scale ?? 3.0
            
        renderer.scale = scale
        
        return renderer.uiImage
    }
}

/// A specialized view for the social export image
/// Simplified version of LeaderboardView optimized for static image
struct PodiumExportView: View {
    let players: [Player]
    
    var body: some View {
        ZStack {
            // Background
            Color.trueBlack.ignoresSafeArea()
            
            // Decorative Blobs
            Circle()
                .fill(Color.neonPurple.opacity(0.3))
                .frame(width: 400, height: 400)
                .blur(radius: 60)
                .offset(y: -100)
            
            VStack(spacing: 30) {
                // Logo / Title
                VStack(spacing: 8) {
                    Text("KAPE!")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .neonGlow(color: .neonPurple, radius: 10)
                    
                    Text(String(localized: "PARTI TURNE"))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.neonGreen)
                        .tracking(4)
                }
                .padding(.top, 40)
                
                // Podium
                HStack(alignment: .bottom, spacing: 20) {
                    // 2nd Place
                    if players.count >= 2 {
                        ExportPodiumColumn(player: players[1], rank: 2)
                    }
                    
                    // 1st Place
                    if let winner = players.first {
                        ExportPodiumColumn(player: winner, rank: 1)
                            .scaleEffect(1.1)
                            .zIndex(1)
                    }
                    
                    // 3rd Place
                    if players.count >= 3 {
                        ExportPodiumColumn(player: players[2], rank: 3)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Footer
                Text(String(localized: "App Store: Kape! Parti"))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.gray)
                    .padding(.bottom, 30)
            }
        }
        .frame(width: 600, height: 800) // Fixed size for export
        .background(Color.trueBlack)
    }
}

struct ExportPodiumColumn: View {
    let player: Player
    let rank: Int
    
    var rankColor: Color {
        switch rank {
        case 1: return Color(hex: "#FFD700")
        case 2: return Color(hex: "#C0C0C0")
        case 3: return Color(hex: "#CD7F32")
        default: return .gray
        }
    }
    
    var height: CGFloat {
        switch rank {
        case 1: return 240
        case 2: return 180
        case 3: return 140
        default: return 120
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Crown for #1
            if rank == 1 {
                Text("👑")
                    .font(.system(size: 40))
                    .shadow(color: rankColor, radius: 10)
            }
            
            // Score
            Text("\(player.score)")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            
            // Bar
            VStack {
                Spacer()
                Text(player.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .lineLimit(1)
                    .padding(.bottom, 12)
            }
            .frame(width: 100, height: height)
            .background(rankColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
            )
        }
    }
}
