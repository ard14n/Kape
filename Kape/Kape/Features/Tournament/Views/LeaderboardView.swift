import SwiftUI

struct LeaderboardView: View {
    @Bindable var viewModel: TournamentViewModel
    var onExit: (() -> Void)?
    @State private var showShareSheet = false
    @State private var podiumImage: UIImage?
    
    var body: some View {
        ZStack {
            VibeBackground()
            
            VStack(spacing: 0) {
                // Header
                Text(String(localized: "Rezultatet Finale"))
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .subtleGlow(color: .white)
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Top 3 Podium
                        if !viewModel.rankedPlayers.isEmpty {
                            PodiumView(players: Array(viewModel.rankedPlayers.prefix(3)))
                        }
                        
                        // Remaining Players
                        if viewModel.rankedPlayers.count > 3 {
                            VStack(spacing: 12) {
                                ForEach(Array(viewModel.rankedPlayers.dropFirst(3).enumerated()), id: \.element.id) { index, player in
                                    PlayerRow(player: player, rank: index + 4)
                                }
                            }
                            .padding(.top, 20)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            
            // Bottom Actions
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    NeonButton(String(localized: "Ndaj Podin"), icon: "square.and.arrow.up", color: .neonBlue) {
                         Task {
                            if let image = await PodiumImageGenerator.generate(from: viewModel.rankedPlayers) {
                                podiumImage = image
                                showShareSheet = true
                            }
                         }
                    }
                    
                    Button(String(localized: "Turne i Ri")) {
                        viewModel.resetTournament(keepPlayers: true)
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
                    
                    Button(String(localized: "Mbyll")) {
                        onExit?()
                    }
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.textSecondary.opacity(0.8))
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .background(
                    LinearGradient(
                        colors: [.trueBlack.opacity(0), .trueBlack.opacity(0.8), .trueBlack],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: ["Shiko kush fitoi në Kape! 🏆", podiumImage ?? UIImage()])
        }
    }
}

// MARK: - Podium Components

struct PodiumView: View {
    let players: [Player]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Second Place
            if players.count >= 2 {
                PodiumColumn(player: players[1], rank: 2)
            }
            
            // First Place (Center, Largest)
            if let winner = players.first {
                PodiumColumn(player: winner, rank: 1)
                    .scaleEffect(1.1)
                    .zIndex(1)
            }
            
            // Third Place
            if players.count >= 3 {
                PodiumColumn(player: players[2], rank: 3)
            }
        }
        .padding(.vertical, 20)
    }
}

struct PodiumColumn: View {
    let player: Player
    let rank: Int
    
    var rankColor: Color {
        switch rank {
        case 1: return Color(hex: "#FFD700") // Gold
        case 2: return Color(hex: "#C0C0C0") // Silver
        case 3: return Color(hex: "#CD7F32") // Bronze
        default: return .gray
        }
    }
    
    var height: CGFloat {
        switch rank {
        case 1: return 180
        case 2: return 140
        case 3: return 120
        default: return 100
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Crown/Title for winner
            if rank == 1 {
                Text("🏆 Legjendë")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(rankColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(rankColor.opacity(0.2))
                    .clipShape(Capsule())
                    .offset(y: 10)
                    .zIndex(2)
            }
            
            // Score Bubble
            ZStack {
                Circle()
                    .fill(Color.trueBlack)
                    .stroke(rankColor, lineWidth: 2)
                    .frame(width: 60, height: 60)
                
                Text("\(player.score)")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
            .offset(y: 15)
            .zIndex(1)
            
            // Column
            VStack {
                Spacer()
                Text(player.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .lineLimit(1)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 8)
            }
            .frame(width: 80, height: height)
            .background(rankColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .neonGlow(color: rankColor, intensity: rank == 1 ? 0.8 : 0.4)
            
            // Rank Badge
            Text("#\(rank)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.textSecondary)
        }
    }
}

struct PlayerRow: View {
    let player: Player
    let rank: Int
    
    var body: some View {
        HStack {
            Text("#\(rank)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textSecondary)
                .frame(width: 40)
            
            Text(player.name)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            
            Spacer()
            
            Text("\(player.score) pikë")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Color.gray)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let vm = TournamentViewModel()
    // Setup mock data for preview
    vm.config.players = [
        Player(name: "Ardian"),
        Player(name: "Tea"),
        Player(name: "Bledi"),
        Player(name: "Genti")
    ]
    // Mock scores need vm running state or direct modification if possible
    // In preview we can just assume `rankedPlayers` works if data exists
    // In preview we can just assume `rankedPlayers` works if data exists
    return LeaderboardView(viewModel: vm, onExit: {})
}
