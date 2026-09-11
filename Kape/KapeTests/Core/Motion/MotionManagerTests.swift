import XCTest
@testable import Kape

@MainActor
final class MotionManagerTests: XCTestCase {
    
    var manager: MotionManager!
    
    override func setUp() async throws {
        manager = MotionManager()
    }
    
    // MARK: - Calibration Tests
    
    func testCalibrationCapturesBaseline() async {
        let provider = TestMotionProvider()
        let motion = MotionManager(motionProvider: provider)
        motion.startMonitoring()
        provider.emit(0.15)
        XCTAssertTrue(motion.validatePosition())
        motion.calibrate()
        provider.emit(0.90) // Only 0.75 radians from baseline: no score.
        XCTAssertEqual(motion.state, .neutral)
        provider.emit(1.0)
        XCTAssertEqual(motion.state, .triggered(.correct))
        motion.stopMonitoring()
    }

    func testTriggerCorrectLowScreen() {
        // GIVEN: Baseline 0.0 (Vertical)
        // Threshold is 0.785 (approx 45 degrees)
        
        // WHEN: Roll delta goes to 0.9 (Tilt Down)
        var events: [MotionManager.GameInputEvent] = []
        let exp = expectation(description: "Event Received")
        
        Task {
            for await event in manager.eventStream {
                events.append(event)
                exp.fulfill()
                break
            }
        }
        
        // Simulate change
        manager.processGravityZ(0.9)
        
        // THEN: Trigger Correct
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(events.first, .correct)
        if case .triggered(.correct) = manager.state {
            XCTAssertTrue(true)
        } else {
            XCTFail("State should be triggered(.correct)")
        }
    }
    
    func testTriggerPassHighScreen() {
        // GIVEN: Baseline 0.0
        
        // WHEN: Roll delta goes to -0.9 (Tilt Up)
        var events: [MotionManager.GameInputEvent] = []
        let exp = expectation(description: "Event Received")
        
        Task {
            for await event in manager.eventStream {
                events.append(event)
                exp.fulfill()
                break
            }
        }
        
        manager.processGravityZ(-0.9)
        
        // THEN: Trigger Pass
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(events.first, .pass)
    }
    
    func testDebounceLogic() {
        // 1. Trigger with value above threshold (0.785)
        manager.processGravityZ(0.9)
        if case .triggered = manager.state {} else { XCTFail() }
        
        // 2. Move slightly back (0.15), which is below neutral threshold (0.20)
        // Delta = 0.15. Abs(0.15) < 0.20 -> It SHOULD return to neutral!
        
        manager.processGravityZ(0.15)
        XCTAssertEqual(manager.state, .neutral)
        
        // 3. Trigger again
        manager.processGravityZ(0.9)
        if case .triggered = manager.state {} else { XCTFail() }
        
        // 4. Move to 0.5 (Still triggered/debouncing range because not < 0.20)
        manager.processGravityZ(0.5)
        XCTAssertEqual(manager.state, .debouncing)
    }
    
    // MARK: - Calibration Validation Tests
    
    func testCalibrationState_InitiallyNotStarted() {
        // GIVEN: A fresh motion manager
        // THEN: Calibration state should be notStarted
        XCTAssertEqual(manager.calibrationState, .notStarted)
    }
    
    func testValidatePosition_WithoutMotion_ReturnsInvalid() {
        // GIVEN: MotionManager not monitoring (no motion data)
        // WHEN: Validating position
        let valid = manager.validatePosition()
        
        // THEN: Should return false and set invalid state
        XCTAssertFalse(valid)
        if case .invalid = manager.calibrationState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected calibrationState to be invalid")
        }
    }
    
    func testStopMonitoring_ResetsCalibrationState() {
        // GIVEN: Manager that has started monitoring
        manager.startMonitoring()
        
        // Simulate a calibration state change
        _ = manager.validatePosition()
        
        // WHEN: Stopping monitoring
        manager.stopMonitoring()
        
        // THEN: Calibration state should be reset to notStarted
        XCTAssertEqual(manager.calibrationState, .notStarted)
    }
}
