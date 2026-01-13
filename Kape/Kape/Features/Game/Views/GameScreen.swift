import SwiftUI

/// Main gameplay screen displaying the card, timer, score, and handling all game states.
/// Per UX spec: Full-screen immersive experience with no navigation bars.
/// Observes GameEngine for state changes and displays appropriate UI.
struct GameScreen: View {
    /// The game engine managing game state (injected via init)
    @Bindable var engine: GameEngine
    
    /// Callback when game finishes (to navigate to results)
    var onFinished: ((GameRound) -> Void)?
    
    /// Accessibility preference for reduced motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    /// Handle exit navigation
    @Environment(\.dismiss) private var dismiss
    
    /// Track the previous action to detect changes for flash
    @State private var previousAction: GameEngine.ActionTrigger?
    
    /// Current flash action (triggers FlashOverlay)
    @State private var flashAction: GameEngine.ActionTrigger?
    
    /// Animation ID for card transitions
    @State private var cardId = UUID()
    
    /// Direction for card exit animation
    @State private var exitDirection: Edge = .bottom
    
    var body: some View {
        ZStack {
            // True Black background
            Color.trueBlack
                .ignoresSafeArea()
            
            // Warning state background glow (subtle red when <10s)
            if engine.isWarningActive && engine.gameState == .playing {
                warningGlow
            }
            
            // Flash overlay for feedback
            FlashOverlay(action: flashAction)
            
            // State-based content
            switch engine.gameState {
            case .idle:
                idleView
                
            case .buffer:
                BufferView(countdown: TimeInterval(engine.bufferCount))
                
            case .playing:
                gameplayView
                
            case .paused:
                pausedOverlay
                
            case .finished:
                finishedView
            }
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("GameScreen_\(engine.gameState)")
        .onChange(of: engine.lastAction) { oldValue, newValue in
            handleActionChange(newValue)
        }
        .onAppear {
            // Yield to let presentation settle before starting game loop
            Task { @MainActor in
                await Task.yield()
                engine.startGameLoop()
            }
        }
        .onChange(of: engine.gameState) { oldValue, newValue in
            if newValue == .finished, let round = engine.currentRound {
                onFinished?(round)
            }
        }
    }
    
    // MARK: - State Views
    
    private var idleView: some View {
        VStack(spacing: 20) {
            Text("Gati për Lojë")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            
            Text("Duke pritur...")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
    
    private var gameplayView: some View {
        VStack(spacing: 0) {
            // Top bar: Timer and Pause
            ZStack(alignment: .center) {
                // Centered Timer
                timerView
                
                // Leading/Trailing controls
                HStack {
                    pauseButton
                    Spacer()
                    scoreView
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            
            Spacer()
            
            // Center: Card
            if let card = engine.currentRound?.currentCard {
                KapeCard(text: card.text)
                    .id(cardId)
                    .transition(cardTransition)
                    .accessibilityIdentifier("CurrentCard")
            } else {
                KapeCard(text: "")
            }
            
            Spacer()
        }
    }
    
    private var timerView: some View {
        let time = engine.currentRound?.timeRemaining ?? 0
        let timeInt = max(0, Int(ceil(time)))
        
        return Text("\(timeInt)s")
            .font(.system(size: 48, weight: .heavy, design: .rounded))
            .foregroundStyle(engine.isWarningActive ? Color.neonRed : .white)
            .contentTransition(.numericText())
            .animation(.bouncy(duration: 0.2), value: timeInt)
            .opacity(engine.isWarningActive ? pulsingOpacity : 1.0)
            .animation(
                engine.isWarningActive 
                    ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true) 
                    : .default,
                value: engine.isWarningActive
            )
            .accessibilityIdentifier("GameTimer")
    }
    
    private var pulsingOpacity: Double {
        0.7 // Will alternate due to repeatForever animation
    }
    
    private var scoreView: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.neonGreen)
            Text("\(engine.currentRound?.score ?? 0)")
                .font(.system(size: 48, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
        }
        .accessibilityIdentifier("GameScore")
    }
    
    private var pauseButton: some View {
        Button(action: {
            withAnimation {
                engine.pause()
            }
        }) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.white.opacity(0.6))
                .padding(8)
                .background(Color.black.opacity(0.2))
                .clipShape(Circle())
        }
        .accessibilityIdentifier("PauseButton")
    }
    
    private var warningGlow: some View {
        RadialGradient(
            colors: [Color.neonRed.opacity(0.3), .clear],
            center: .center,
            startRadius: 50,
            endRadius: 400
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
    
    private var pausedOverlay: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Return to Game Button (Primary)
                Button(action: {
                    withAnimation {
                        engine.resume()
                    }
                }) {
                    VStack(spacing: 16) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(Color.neonGreen)
                            
                        Text("VAZHDO")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("ResumeGameButton")
                
                // End Game Button (Secondary)
                Button(action: {
                    handleExit()
                }) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Përfundo Lojën")
                    }
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
                }
                .accessibilityIdentifier("EndGameButton")
            }
        }
    }
    
    private var finishedView: some View {
        VStack(spacing: 20) {
            Text("Koha Mbaroi!")
                .font(.system(size: 48, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.neonRed)
            
            if let round = engine.currentRound {
                Text("Pikët: \(round.score)")
                    .font(.system(size: 80, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }
    
    // MARK: - Card Transition
    
    private var cardTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        
        return .asymmetric(
            insertion: .move(edge: exitDirection == .bottom ? .top : .bottom)
                .combined(with: .opacity),
            removal: .move(edge: exitDirection)
                .combined(with: .opacity)
        )
    }
    
    // MARK: - Action Handling
    
    private func handleActionChange(_ action: GameEngine.ActionTrigger?) {
        guard let action = action else { return }
        
        // Trigger flash
        flashAction = action
        
        // Set exit direction for card animation
        switch action.event {
        case .correct:
            exitDirection = .bottom // Tilt down = slide down
        case .pass:
            exitDirection = .top // Tilt up = slide up
        }
        
        // Update card ID to trigger transition
        withAnimation(.bouncy(duration: 0.25)) {
            cardId = UUID()
        }
        
        // Clear flash after longer delay (0.3s) to allow fade-out animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            flashAction = nil
        }
    }
    
    // MARK: - Navigation Actions
    
    private func handleExit() {
        // Stop engine updates
        engine.finishGame() 
        // Dismiss view to return to browser
        dismiss()
    }
}

// MARK: - Previews

#Preview("Idle State") {
    let engine = GameEngine(
        motionManager: MotionManager(),
        audioService: MockAudioService(),
        hapticService: MockHapticService()
    )
    GameScreen(engine: engine)
}

#Preview("Playing State") {
    let engine = GameEngine(
        motionManager: MotionManager(),
        audioService: MockAudioService(),
        hapticService: MockHapticService()
    )
    
    GameScreen(engine: engine)
        .onAppear {
            let deck = Deck(
                id: "test",
                title: "Test",
                description: "Test Deck",
                iconName: "star",
                difficulty: 1,
                isPro: false,
                cards: [
                    Card(id: "1", text: "Tavë Kosi"),
                    Card(id: "2", text: "Golf 4"),
                    Card(id: "3", text: "Pite")
                ]
            )
            engine.startRound(with: deck)
            // Fast-forward to playing state for preview
            engine.gameState = .playing
        }
}

// MARK: - Mock Services for Previews

private struct MockAudioService: AudioServiceProtocol {
    func playSound(_ name: String) {}
}

private struct MockHapticService: HapticServiceProtocol {
    func playFeedback(_ type: GameFeedbackType) {}
}
