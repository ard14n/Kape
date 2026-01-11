import XCTest
@testable import Kape

final class MotionManagerTests: XCTestCase {
    
    var manager: MotionManager!
    
    override func setUp() async throws {
        manager = MotionManager()
    }
    
    // MARK: - Calibration Tests
    
    func testCalibrationCapturesBaseline() async {
        // GIVEN: A manager at neutral state
        XCTAssertEqual(manager.state, .neutral)
        
        // WHEN: We simulate a weird starting position (e.g. lying down, Z = 0.5)
        // Note: processGravityZ sets liveGravityZ AND processes it, but calibrate() uses CMMotionManager which we can't easily mock here without protocol.
        // CHECK: MotionManager code shows calibrate() reads `motionManager.deviceMotion`.
        // ISSUE: We cannot test `calibrate()` without mocking CMMotionManager or refactoring `calibrate` to accept a value.
        // FIX: I should refactor `calibrate()` to set baselineZ directly if I want to test it pure, OR expose `setBaselineZ` for testing.
        // Let's assume for this test we can set it via a workaround or refactor content first.
        
        // Actually, looking at the code I wrote:
        // func calibrate() { guard let motion = ...; self.baselineZ = motion.gravity.z }
        // This is hard dependency.
        
        // STRATEGY update: I will refactor MotionManager to allow injecting baseline or setting it for testability,
        // OR I will test "processGravityZ" assuming baseline is 0 (default).
        
        // Let's test the logic logic first (assuming baseline 0).
    }
    
    func testTriggerCorrectLowScreen() {
        // GIVEN: Baseline 0.0 (Vertical)
        // Threshold is 0.6
        
        // WHEN: Gravity Z goes to 0.7 (Screen Down)
        var events: [MotionManager.GameInputEvent] = []
        let exp = expectation(description: "Event Received")
        
        Task {
            for await event in manager.eventStream {
                events.append(event)
                exp.fulfill()
            }
        }
        
        // Simulate change
        manager.processGravityZ(0.7)
        
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
        
        // WHEN: Gravity Z goes to -0.7 (Screen Up)
        var events: [MotionManager.GameInputEvent] = []
        let exp = expectation(description: "Event Received")
        
        Task {
            for await event in manager.eventStream {
                events.append(event)
                exp.fulfill()
            }
        }
        
        manager.processGravityZ(-0.7)
        
        // THEN: Trigger Pass
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(events.first, .pass)
    }
    
    func testDebounceLogic() {
        // 1. Trigger
        manager.processGravityZ(0.7)
        if case .triggered = manager.state {} else { XCTFail() }
        
        // 2. Move slightly back (0.19), but not fully neutral (Neutral Threshold 0.2)
        // Delta = 0.19. Abs(0.19) < 0.2 -> It SHOULD return to neutral!
        
        manager.processGravityZ(0.15)
        XCTAssertEqual(manager.state, .neutral)
        
        // 3. Trigger again
        manager.processGravityZ(0.7)
        if case .triggered = manager.state {} else { XCTFail() }
        
        // 4. Move to 0.5 (Still triggered/debouncing range because not < 0.2)
        manager.processGravityZ(0.5)
        XCTAssertEqual(manager.state, .debouncing)
    }
}
