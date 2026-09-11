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
    
    /// Wrapper for game input events to ensure uniqueness (for SwiftUI updates)
    struct ActionTrigger: Equatable {
        let event: MotionManager.GameInputEvent
        let id = UUID()
    }
    
    /// Last input action for UI flash triggering (observed by View)
    var lastAction: ActionTrigger?
    
    /// Whether the 10-second warning is active (for UI urgency effects)
    var isWarningActive: Bool = false
    
    /// Callback for tournament mode or external handlers when game completes
    var onGameComplete: ((Int) -> Void)?
    
    // Configuration
    struct Configuration {
        var bufferDuration: TimeInterval = 3.0
        var gameDuration: TimeInterval = 60.0
        var warningThreshold: TimeInterval = 10.0
    }
    
    // Dependencies
    private let audioService: AudioServiceProtocol
    private let hapticService: HapticServiceProtocol
    private let configuration: Configuration
    
    // Expose motionManager for calibration view
    let motionManager: MotionManager
    
    // Internal
    private var gameTask: Task<Void, Never>?
    private var roundHasStarted = false
    
    // MARK: - Initialization
    
    init(motionManager: MotionManager, 
         audioService: AudioServiceProtocol, 
         hapticService: HapticServiceProtocol,
         configuration: Configuration? = nil) {
        self.motionManager = motionManager
        self.audioService = audioService
        self.hapticService = hapticService
        self.configuration = configuration ?? Configuration()
    }
    
    // MARK: - Game Logic
    
    func startRound(with deck: Deck) {
        gameTask?.cancel()
        motionManager.prepareForNewRound()
        result = nil
        roundHasStarted = false
        currentRound = GameRound(deck: deck, timeRemaining: configuration.gameDuration)
        gameState = .calibrating // Start with calibration instead of buffer
        bufferCount = Int(configuration.bufferDuration)
        lastAction = nil
        isWarningActive = false
        
        gameTask = nil // Ensure no task is running initially
    }
    
    /// Called when calibration is complete and device is properly positioned
    func onCalibrationComplete() {
        guard gameState == .calibrating else { return }
        gameState = roundHasStarted ? .playing : .buffer
    }
    
    /// Starts the active game loop (Buffer -> Playing).
    /// Call this when the UI is ready (e.g., onAppear).
    func startGameLoop() {
        guard gameTask == nil else { return } // Prevent double start
        guard gameState == .buffer else { return } // Only start from buffer state (after calibration)
        
        gameTask = Task {
            await runGameLoop()
        }
    }
    
    private func runGameLoop() async {
        // Buffer Phase: Count down explicitly
        while bufferCount > 0 || gameState != .buffer {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 sec
            guard !Task.isCancelled else { return }
            
            // Decrement (if >0)
            if gameState == .buffer && bufferCount > 0 {
                bufferCount -= 1
            }
        }
        
        // Ensure we explicitly switch to playing if not cancelled
        guard !Task.isCancelled else { return }
        await startGameplay()
    }
    
    private func startGameplay() async {
        let events = motionManager.beginInputStream()
        roundHasStarted = true
        gameState = .playing
        motionManager.startMonitoring()
        
        // Calibration is already done in CalibrationView, so we can start immediately
        
        await withTaskGroup(of: Void.self) { group in
            // 1. Input Listener Loop
            group.addTask { @MainActor in
                for await event in events {
                    guard !Task.isCancelled else { break }
                    self.handleInput(event)
                }
            }
            
            // 2. Timer Loop (Drift-Corrected)
            let tick: TimeInterval = 0.1
            var warningTriggered = false
            var lastTick = Date.now
            
            while (currentRound?.timeRemaining ?? 0) > 0 {
                 try? await Task.sleep(nanoseconds: UInt64(tick * 1_000_000_000))
                 
                 let now = Date.now
                 
                 if Task.isCancelled { break }
                 
                 // Pause Check
                 if gameState != .playing {
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
        
        guard !Task.isCancelled else { return }
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
            lastAction = ActionTrigger(event: .correct)
            audioService.playSound("success")
            hapticService.playFeedback(.success)
            nextCard(in: &round)
            
        case .pass:
            round.passed += 1
            lastAction = ActionTrigger(event: .pass)
            audioService.playSound("pass")
            hapticService.playFeedback(.pass)
            nextCard(in: &round)
        }
        
        currentRound = round
        if round.currentCard == nil { finishGame() }
    }
    
    private func nextCard(in round: inout GameRound) {
        if let next = round.remainingCards.popLast() {
            round.currentCard = next
        } else {
            round.currentCard = nil

        }
    }
    
    // MARK: - Lifecycle
    
    func pause() {
        guard gameState == .playing || gameState == .buffer || gameState == .calibrating else { return }
        gameState = .paused
        motionManager.stopMonitoring()
    }
    
    func resume() {
        guard gameState == .paused else { return }
        // The phone may have moved during the interruption. Capture a fresh neutral position.
        gameState = .calibrating
        motionManager.startMonitoring()
    }

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .background, .inactive:
            pause()
        default:
            break
        }
    }
    
    func finishGame() {
        guard gameState != .finished && gameState != .idle else { return }
        // Compute result before finishing
        if let round = currentRound {
            result = GameResult.from(round)
        }
        
        gameTask?.cancel()
        gameTask = nil
        motionManager.stopMonitoring()
        gameState = .finished
        
        if let score = result?.score {
            onGameComplete?(score)
        }
    }

    /// Ends a dismissed view's work without publishing a result or a tournament callback.
    func stop() {
        gameTask?.cancel()
        gameTask = nil
        motionManager.stopMonitoring()
        if gameState != .finished { gameState = .idle }
    }

}
