import XCTest
import AVFoundation
@testable import Kape

/// Tests the REAL AudioService implementation (no mocks)
/// Verifies it initializes correctly, handles AVFoundation calls without crashing,
/// and respects mute toggle.
final class RealAudioServiceTests: XCTestCase {
    
    var service: AudioService!
    
    override func setUp() {
        super.setUp()
        // Note: This relies on sound files being in the bundle.
        // If running in logic test bundle, might fail to find resources unless added to Test Target.
        // AudioService fails gracefully (prints error) so initialization should still succeed.
        service = AudioService()
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    // MARK: - Initialization & Config
    
    func test_initialization_succeeds() {
        XCTAssertNotNil(service)
        XCTAssertTrue(service.isSoundEnabled) // Default true
    }
    
    // MARK: - API Stability (Crash Tests)
    
    func test_playSound_doesNotCrash() {
        // Even if files are missing, this should not crash
        service.playSound("success")
        service.playSound("pass")
        service.playSound("warning")
        
        // Pass if we get here
        XCTAssertTrue(true)
    }
    
    func test_playSound_missingSound_doesNotCrash() {
        service.playSound("non_existent_sound_12345")
        XCTAssertTrue(true)
    }
    
    // MARK: - Logic
    
    func test_toggleMute_updatesProperty() {
        // Given
        service.isSoundEnabled = true
        
        // When
        service.isSoundEnabled = false
        
        // Then
        XCTAssertFalse(service.isSoundEnabled)
        
        // Does playSound crash when muted?
        service.playSound("success")
        XCTAssertTrue(true)
    }
}
