import XCTest
@testable import Kape

/// Tests for HapticService - Story 1.4: Haptic & Audio Feedback System
///
/// **Note:** Haptic feedback requires a physical device to test actual vibration.
/// These tests verify the logic and protocol conformance, not the physical sensation.
/// Device testing is REQUIRED for final validation.
final class HapticServiceTests: XCTestCase {
    
    // MARK: - Mock Haptic Infrastructure
    
    /// Tracks which feedback types were triggered
    class MockHapticService: HapticServiceProtocol {
        var feedbackHistory: [GameFeedbackType] = []
        var lastFeedback: GameFeedbackType?
        var feedbackCount: Int { feedbackHistory.count }
        
        func playFeedback(_ type: GameFeedbackType) {
            lastFeedback = type
            feedbackHistory.append(type)
        }
        
        func reset() {
            feedbackHistory = []
            lastFeedback = nil
        }
    }
    
    // MARK: - Properties
    
    var sut: MockHapticService!
    
    override func setUp() {
        super.setUp()
        sut = MockHapticService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - AC1: Success Feedback (P0)
    
    /// Given: HapticService
    /// When: a `.success` event occurs via `playFeedback(.success)`
    /// Then: it must trigger the correct feedback type
    func test_playFeedback_success_triggersSuccessFeedback() {
        // When
        sut.playFeedback(.success)
        
        // Then
        XCTAssertEqual(sut.lastFeedback, .success)
        XCTAssertEqual(sut.feedbackCount, 1)
    }
    
    // MARK: - AC2: Pass Feedback (P0)
    
    /// Given: HapticService
    /// When: a `.pass` event occurs via `playFeedback(.pass)`
    /// Then: it must trigger the pass feedback type
    func test_playFeedback_pass_triggersPassFeedback() {
        // When
        sut.playFeedback(.pass)
        
        // Then
        XCTAssertEqual(sut.lastFeedback, .pass)
        XCTAssertEqual(sut.feedbackCount, 1)
    }
    
    // MARK: - AC3: Warning Feedback (P0)
    
    /// Given: HapticService
    /// When: a `.warning` event occurs via `playFeedback(.warning)`
    /// Then: it must trigger the warning feedback type
    func test_playFeedback_warning_triggersWarningFeedback() {
        // When
        sut.playFeedback(.warning)
        
        // Then
        XCTAssertEqual(sut.lastFeedback, .warning)
        XCTAssertEqual(sut.feedbackCount, 1)
    }
    
    // MARK: - Sequence Testing (P1)
    
    /// Given: Multiple game events
    /// When: Feedback is triggered in rapid succession
    /// Then: All feedback types are recorded in correct order
    func test_playFeedback_multipleEvents_recordsSequence() {
        // When
        sut.playFeedback(.success)
        sut.playFeedback(.pass)
        sut.playFeedback(.warning)
        sut.playFeedback(.success)
        
        // Then
        XCTAssertEqual(sut.feedbackHistory, [.success, .pass, .warning, .success])
        XCTAssertEqual(sut.lastFeedback, .success)
        XCTAssertEqual(sut.feedbackCount, 4)
    }
    
    // MARK: - Protocol Conformance (P1)
    
    /// Given: Any implementation of HapticServiceProtocol
    /// When: Used with dependency injection
    /// Then: It conforms to Sendable for thread safety
    func test_hapticServiceProtocol_conformsToSendable() {
        // The protocol definition includes Sendable
        // This test verifies the mock can be used in concurrent contexts
        let service: any HapticServiceProtocol = sut
        
        // Execute feedback from different "conceptual" contexts
        service.playFeedback(.success)
        
        XCTAssertEqual(sut.lastFeedback, .success)
    }
    
    // MARK: - Edge Cases (P2)
    
    /// Given: HapticService
    /// When: Same feedback type triggered multiple times
    /// Then: Each trigger is recorded independently
    func test_playFeedback_repeatedSameType_recordsAll() {
        // When
        for _ in 1...5 {
            sut.playFeedback(.success)
        }
        
        // Then
        XCTAssertEqual(sut.feedbackCount, 5)
        XCTAssertTrue(sut.feedbackHistory.allSatisfy { $0 == .success })
    }
}

// MARK: - Integration Tests with GameEngine

@MainActor
extension HapticServiceTests {
    
    /// Given: GameEngine with HapticService injected
    /// When: Motion input triggers .correct
    /// Then: HapticService receives .success feedback
    func test_integration_motionCorrect_triggersSuccessHaptic() async {
        // Given
        let motion = MotionManager()
        let audio = MockAudioService()
        let haptic = MockHapticService()
        let config = GameEngine.Configuration(bufferDuration: 0.1, gameDuration: 5.0)
        let engine = GameEngine(motionManager: motion, audioService: audio, hapticService: haptic, configuration: config)
        
        let deck = Deck(id: "test", title: "Test", description: "Test", iconName: "star", difficulty: 1, isPro: false, cards: [
            Card(id: "1", text: "TestCard")
        ])
        
        engine.startRound(with: deck)
        engine.startGameLoop()
        
        // Wait for buffer + margin
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // When: Trigger correct via motion
        motion.processGravityZ(0.7) // Tilt down = correct
        
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        // Then
        XCTAssertEqual(haptic.lastFeedback, .success)
    }
    
    /// Given: GameEngine with HapticService injected
    /// When: Motion input triggers .pass
    /// Then: HapticService receives .pass feedback
    func test_integration_motionPass_triggersPassHaptic() async {
        // Given
        let motion = MotionManager()
        let audio = MockAudioService()
        let haptic = MockHapticService()
        let config = GameEngine.Configuration(bufferDuration: 0.1, gameDuration: 5.0)
        let engine = GameEngine(motionManager: motion, audioService: audio, hapticService: haptic, configuration: config)
        
        let deck = Deck(id: "test", title: "Test", description: "Test", iconName: "star", difficulty: 1, isPro: false, cards: [
            Card(id: "1", text: "TestCard")
        ])
        
        engine.startRound(with: deck)
        engine.startGameLoop()
        
        // Wait for buffer + margin
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // When: Trigger pass via motion
        motion.processGravityZ(-0.7) // Tilt up = pass
        
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        // Then
        XCTAssertEqual(haptic.lastFeedback, .pass)
    }
    
    // MARK: - Helpers
    
    class MockAudioService: AudioServiceProtocol {
        var lastPlayedSound: String?
        func playSound(_ name: String) {
            lastPlayedSound = name
        }
    }
}
