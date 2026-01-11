import Foundation
import SwiftUI

@Observable
@MainActor
final class GameEngine: Identifiable {
    
    // MARK: - Properties
    
    var gameState: GameState = .idle
    var currentRound: GameRound?
    
    /// Computed game result (available after game finishes)
    var result: GameResult?
    
    /// Countdown for the buffer phase (3, 2, 1)
    var bufferCount: Int = 3
    
    /// Last input action for UI flash triggering (observed by View)
    var lastAction: MotionManager.GameInputEvent?
    
    /// Whether the 10-second warning is active (for UI urgency effects)
    var isWarningActive: Bool = false
    
    // Configuration
    struct Configuration {
        var bufferDuration: TimeInterval = 3.0
        var gameDuration: TimeInterval = 60.0
        var warningThreshold: TimeInterval = 10.0
    }
    
    // Dependencies
    private let motionManager: MotionManager
    private let audioService: AudioServiceProtocol
    private let hapticService: HapticServiceProtocol
    private let configuration: Configuration
    
    // Internal
    private var gameTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init(motionManager: MotionManager, 
         audioService: AudioServiceProtocol, 
         hapticService: HapticServiceProtocol,
         configuration: Configuration = Configuration()) {
        self.motionManager = motionManager
        self.audioService = audioService
        self.hapticService = hapticService
        self.configuration = configuration
    }
    
    // MARK: - Cleanup
    
    // Note: deinit cannot access MainActor-isolated properties.
    // Task auto-cancels when GameEngine is deallocated.
    // Call cleanup() explicitly before releasing if needed.
    
    // MARK: - Game Logic
    
    func startRound(with deck: Deck) {
        gameTask?.cancel()
        currentRound = GameRound(deck: deck, timeRemaining: configuration.gameDuration)
        gameState = .buffer
        bufferCount = Int(configuration.bufferDuration)
        lastAction = nil
        isWarningActive = false
        
        gameTask = nil // Ensure no task is running initially
    }
    
    /// Starts the active game loop (Buffer -> Playing).
    /// Call this when the UI is ready (e.g., onAppear).
    func startGameLoop() {
        guard gameTask == nil else { return } // Prevent double start
        
        gameTask = Task {
            await runGameLoop()
        }
    }
    
    private func runGameLoop() async {
        // Buffer Phase: Count down explicitly
        while bufferCount > 0 {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 sec
            guard !Task.isCancelled else { return }
            
            // Decrement (if >0)
            if bufferCount > 0 {
                bufferCount -= 1
            }
        }
        
        // Ensure we explicitly switch to playing if not cancelled
        guard !Task.isCancelled else { return }
        await startGameplay()
    }
    
    private func startGameplay() async {
        gameState = .playing
        motionManager.startMonitoring()
        
        // Give sensors a moment to warm up and capture baseline
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        motionManager.calibrate()
        
        await withTaskGroup(of: Void.self) { group in
            // 1. Input Listener Loop
            group.addTask { @MainActor in
                for await event in self.motionManager.eventStream {
                    guard !Task.isCancelled else { break }
                    self.handleInput(event)
                }
            }
            
            // 2. Timer Loop (Drift-Corrected)
            let tick: TimeInterval = 0.1
            var warningTriggered = false
            var lastTick = Date.now
            
            while await (currentRound?.timeRemaining ?? 0) > 0 {
                 try? await Task.sleep(nanoseconds: UInt64(tick * 1_000_000_000))
                 
                 let now = Date.now
                 
                 if Task.isCancelled { break }
                 
                 // Pause Check
                 if gameState == .paused { 
                     lastTick = now // Advance lastTick so we don't count paused time
                     continue 
                 }
                 
                 guard var round = currentRound else { break }
                 
                 // Calculate drift-corrected delta
                 let delta = now.timeIntervalSince(lastTick)
                 lastTick = now
                 
                 round.timeRemaining -= delta
                 
                 // Warning
                 if round.timeRemaining <= configuration.warningThreshold && !warningTriggered {
                     warningTriggered = true
                     isWarningActive = true
                     audioService.playSound("warning")
                     hapticService.playFeedback(.warning)
                 }
                 
                 currentRound = round
            }
            
            group.cancelAll()
        }
        
        finishGame()
    }
    
    private func handleInput(_ event: MotionManager.GameInputEvent) {
        guard gameState == .playing else { return }
        guard var round = currentRound else { return }
        
        // Guard: Cannot play if no card (unless we want to allow skipping empty? No, game ends)
        guard round.currentCard != nil else { return }
        
        switch event {
        case .correct:
            round.score += 1
            lastAction = .correct
            audioService.playSound("success")
            hapticService.playFeedback(.success)
            nextCard(in: &round)
            
        case .pass:
            round.passed += 1
            lastAction = .pass
            audioService.playSound("pass")
            hapticService.playFeedback(.pass)
            nextCard(in: &round)
        }
        
        currentRound = round
    }
    
    private func nextCard(in round: inout GameRound) {
        if let next = round.remainingCards.popLast() {
            round.currentCard = next
        } else {
            round.currentCard = nil
            // Deck empty -> Finish early?
            // User requirement: "follow a structured 60-second timer"
            // Usually in Charades, if deck ends, game ends.
            // We will trigger finish via task cancellation or checking in loop.
            // For now, setting currentCard nil stops input. The loop will process time or we can force finish.
            // Let's force finish to be responsive.
            Task { @MainActor in 
                self.finishGame() 
            }
        }
    }
    
    // MARK: - Lifecycle
    
    func pause() {
        guard gameState == .playing else { return }
        gameState = .paused
        motionManager.stopMonitoring()
    }
    
    func resume() {
        guard gameState == .paused else { return }
        gameState = .playing
        motionManager.startMonitoring()
        // Reset lastTick to avoid jumping time
        // Note: The loop updates lastTick in paused state, so it should be fine.
    }
    
    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .background, .inactive:
            if gameState == .playing {
                pause()
            }
        default:
            break
        }
    }
    
    func finishGame() {
        // Compute result before finishing
        if let round = currentRound {
            result = GameResult.from(round)
        }
        
        gameTask?.cancel() 
        motionManager.stopMonitoring()
        gameState = .finished
    }
}
