import SwiftUI

struct TournamentContainerView: View {
    @Bindable var viewModel: TournamentViewModel
    @State private var gameEngine = GameEngine(
        motionManager: MotionManager(),
        audioService: AudioService(),
        hapticService: HapticService()
    )
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            content
                .navigationBarHidden(true)
        }
    }
    
    @ViewBuilder
    var content: some View {
        if let state = viewModel.tournamentState, state.isTournamentActive {
            switch state.phase {
            case .setup:
                // Should not happen if isTournamentActive check passes, but fallback
                TournamentSetupView(viewModel: viewModel)
                
            case .interstitial:
                TournamentInterstitialView(viewModel: viewModel)
                
            case .playing:
                // Game Integration
                GameScreen(engine: gameEngine)
                    .onAppear {
                        // Start game with a random deck
                        // Ideally checking for "available" decks (unlocked)
                        let deckService = DeckService()
                        let decks = deckService.decks
                        if let randomDeck = decks.randomElement() {
                            gameEngine.startRound(with: randomDeck)
                            gameEngine.startGameLoop()
                        } else {
                            // Fallback if no decks? Should not happen.
                            print("Error: No decks found for tournament.")
                            viewModel.recordScore(0) // Skip turn
                        }
                        
                        // Set up completion callback
                        gameEngine.onGameComplete = { score in
                            viewModel.recordScore(score)
                        }
                    }
                
            case .finished:
                LeaderboardView(viewModel: viewModel)
            }
        } else {
            // No active tournament, show Setup
            TournamentSetupView(viewModel: viewModel)
        }
    }
}
