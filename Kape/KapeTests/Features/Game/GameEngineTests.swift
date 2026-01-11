import XCTest
import SwiftUI
@testable import Kape

@MainActor
final class GameEngineTests: XCTestCase {
    
    // Mocks
    class MockAudioService: AudioServiceProtocol {
        var lastPlayedSound: String?
        func playSound(_ name: String) {
            lastPlayedSound = name
        }
    }
    
    class MockHapticService: HapticServiceProtocol {
        var lastFeedback: GameFeedbackType?
        func playFeedback(_ type: GameFeedbackType) {
            lastFeedback = type
        }
    }
    
    func testInitialization() async {
        let motion = MotionManager()
        let audio = MockAudioService()
        let haptic = MockHapticService()
        
        // This should fail to compile if GameEngine doesn't exist
        let engine = GameEngine(motionManager: motion, audioService: audio, hapticService: haptic)
        
        XCTAssertNotNil(engine)
        XCTAssertEqual(engine.gameState, .idle) // Verify it starts at idle
        
        // Keep references alive briefly to let CMMotionManager cleanup gracefully
        _ = motion
        _ = engine
        try? await Task.sleep(nanoseconds: 50_000_000)
    }
    
    func testStartRound() async {
        let motion = MotionManager()
        let audio = MockAudioService()
        let haptic = MockHapticService()
        let engine = GameEngine(motionManager: motion, audioService: audio, hapticService: haptic)
        let deck = DeckFactory.make()
        
        engine.startRound(with: deck)
        engine.startGameLoop()
        
        // Immediate state should be buffer
        XCTAssertEqual(engine.gameState, .buffer)
        XCTAssertEqual(engine.bufferCount, 3) // Default config
        XCTAssertNotNil(engine.currentRound)
    }
    
    func testInputHandling() async {
        let motion = MotionManager()
        let audio = MockAudioService()
        let haptic = MockHapticService()
        // Fast config
        let config = GameEngine.Configuration(bufferDuration: 0.1, gameDuration: 5.0, warningThreshold: 2.0)
        let engine = GameEngine(motionManager: motion, audioService: audio, hapticService: haptic, configuration: config)
        
        let deck = DeckFactory.make(cards: [
            CardFactory.make(text: "A"),
            CardFactory.make(text: "B")
        ])
        
        engine.startRound(with: deck)
        engine.startGameLoop()
        
        // Wait for buffer (0.1s) + margin
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        XCTAssertEqual(engine.gameState, .playing)
        
        XCTAssertEqual(engine.gameState, .playing)
        
        // 1. Trigger Correct (Tilt Down -> Gravity Z increases)
        // Simulate calibrating at 0, moving to 0.7
        motion.processGravityZ(0.7)
        
        // Give run loop time to process
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Verify Score
        XCTAssertEqual(engine.currentRound?.score, 1)
        XCTAssertEqual(haptic.lastFeedback, .success)
        
        // 2. Reset to Neutral (Debounce)
        motion.processGravityZ(0.0)
        
        // 3. Trigger Pass (Tilt Up -> Gravity Z decreases)
        // Simulate moving to -0.7
        motion.processGravityZ(-0.7)
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertEqual(engine.currentRound?.passed, 1)
        XCTAssertEqual(haptic.lastFeedback, .pass)
    }
    
    func testPauseResume() async {
        let motion = MotionManager()
        let audio = MockAudioService()
        let haptic = MockHapticService()
        // Fast config
        let config = GameEngine.Configuration(bufferDuration: 0.1, gameDuration: 10.0, warningThreshold: 2.0)
        let engine = GameEngine(motionManager: motion, audioService: audio, hapticService: haptic, configuration: config)
        let deck = DeckFactory.make()
        
        engine.startRound(with: deck)
        engine.startGameLoop()
        
        // Wait for playing (0.1s buffer)
        try? await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(engine.gameState, .playing)
        
        let timeAtStart = engine.currentRound!.timeRemaining
        
        // Pause
        engine.pause()
        XCTAssertEqual(engine.gameState, .paused)
        
        // Wait 0.5s
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Verify time hasn't changed (allow small delta for loop tick)
        XCTAssertEqual(engine.currentRound!.timeRemaining, timeAtStart, accuracy: 0.15)
        
        // Resume
        engine.resume()
        XCTAssertEqual(engine.gameState, .playing)
        
        // Wait 0.5s
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Verify time decreased
        XCTAssertLessThan(engine.currentRound!.timeRemaining, timeAtStart - 0.4)
    }
    
    func testGameTimerExpires() async {
        let motion = MotionManager()
        let audio = MockAudioService()
        let haptic = MockHapticService()
        // Super fast game (1s)
        let config = GameEngine.Configuration(bufferDuration: 0.05, gameDuration: 1.0, warningThreshold: 0.5)
        let engine = GameEngine(motionManager: motion, audioService: audio, hapticService: haptic, configuration: config)
        let deck = DeckFactory.make()
        
        engine.startRound(with: deck)
        engine.startGameLoop()
        
        // Wait for Buffer (0.05) + Game (1.0) + Margin (0.2)
        try? await Task.sleep(nanoseconds: 1_250_000_000)
        
        XCTAssertEqual(engine.gameState, .finished)
        XCTAssertEqual(engine.currentRound?.timeRemaining ?? 0, 0, accuracy: 0.2)
    }
    
    func testWarningSignals() async {
        let motion = MotionManager()
        let audio = MockAudioService()
        let haptic = MockHapticService()
        // Game 2.0s, Warning at 1.0s
        let config = GameEngine.Configuration(bufferDuration: 0.0, gameDuration: 2.0, warningThreshold: 1.0)
        let engine = GameEngine(motionManager: motion, audioService: audio, hapticService: haptic, configuration: config)
        let deck = DeckFactory.make()
        
        engine.startRound(with: deck)
        engine.startGameLoop()
        
        // Wait 0.5s (Time ~1.5) -> No warning yet
        try? await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertNil(audio.lastPlayedSound)
        
        // Wait another 0.8s (Total ~1.3s, Time Remaining ~0.7) -> Warning should definitely trigger
        try? await Task.sleep(nanoseconds: 800_000_000)
        XCTAssertEqual(audio.lastPlayedSound, "warning")
        XCTAssertEqual(haptic.lastFeedback, .warning)
    }
    
    func testScenePhaseHandling() async {
        let motion = MotionManager()
        let audio = MockAudioService()
        let haptic = MockHapticService()
        let config = GameEngine.Configuration(bufferDuration: 0.1, gameDuration: 60.0)
        let engine = GameEngine(motionManager: motion, audioService: audio, hapticService: haptic, configuration: config)
        let deck = DeckFactory.make()
        
        engine.startRound(with: deck)
        engine.startGameLoop()
        
        // Wait for playing
        try? await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(engine.gameState, .playing)
        
        // Minimize App
        engine.handleScenePhase(.background)
        XCTAssertEqual(engine.gameState, .paused)
        
        // Foreground App (User must manually resume usually, let's check)
        // Note: Logic says handleScenePhase doesn't auto-resume on .active, 
        // usually resuming is a manual user action or explicit onActive handler.
        // Let's verify it STAYS paused or if we need to call resume()
        
        engine.handleScenePhase(.active)
        // If logic doesn't auto-resume:
        XCTAssertEqual(engine.gameState, .paused)
        
        // Manual resume
        engine.resume()
        XCTAssertEqual(engine.gameState, .playing)
    }
    func testGameCompletion_GeneratesResult() async {
        let motion = MotionManager()
        let audio = MockAudioService()
        let haptic = MockHapticService()
        // Fast game (0.1s)
        let config = GameEngine.Configuration(bufferDuration: 0.0, gameDuration: 0.1)
        let engine = GameEngine(motionManager: motion, audioService: audio, hapticService: haptic, configuration: config)
        let deck = DeckFactory.make()
        
        engine.startRound(with: deck)
        engine.startGameLoop()
        
        // Simulate score
        engine.currentRound?.score = 5
        engine.currentRound?.passed = 2
        
        // Wait for game to finish (0.1s + margin)
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        XCTAssertEqual(engine.gameState, .finished)
        XCTAssertNotNil(engine.result, "GameResult should be generated when game finishes")
        XCTAssertEqual(engine.result?.score, 5)
        XCTAssertEqual(engine.result?.passed, 2)
        XCTAssertEqual(engine.result?.total, 7)
    }
}

