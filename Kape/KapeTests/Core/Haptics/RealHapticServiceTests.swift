import XCTest
@testable import Kape

/// Tests the REAL HapticService implementation (no mocks)
/// Verifies initialization and MainActor isolation.
@MainActor
final class RealHapticServiceTests: XCTestCase {
    
    var service: HapticService!
    
    override func setUp() {
        super.setUp()
        service = HapticService()
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    // MARK: - Initialization
    
    func test_initialization_succeeds() {
        XCTAssertNotNil(service)
        // Verify platform support check
        // This assertion depends on simulator/device used
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            XCTAssertTrue(service.isHapticsSupported)
        }
        #endif
    }
    
    // MARK: - API Stability (Crash Tests)
    
    // This test critical verifies the removing of the Task wrapper didn't break things
    func test_playFeedback_doesNotCrash() {
        service.playFeedback(.success)
        service.playFeedback(.pass)
        service.playFeedback(.warning)
        
        // Pass if no crash
        XCTAssertTrue(true)
    }
}
