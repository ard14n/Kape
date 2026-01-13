import XCTest
@testable import Kape
import SwiftUI

/// Tests for ResultScreen Navigation (Story 3.5)
final class ResultScreenNavigationTests: XCTestCase {
    
    // MARK: - Navigation Callback Tests
    
    /// Test that ResultScreen accepts an onHome callback
    func testResultScreen_AcceptsOnHomeCallback() {
        // Given: A game result and an expectation
        let result = GameResult(score: 10, passed: 5, date: Date())
        var didNavigateHome = false
        
        // When: Initialize ResultScreen with onHome callback
        let screen = ResultScreen(
            result: result,
            onPlayAgain: {},
            onShare: {},
            onHome: { didNavigateHome = true }
        )
        screen.onHome?()
        
        // Then: Screen should initialize successfully and trigger callback
        XCTAssertNotNil(screen, "ResultScreen should initialize with onHome callback")
        XCTAssertTrue(didNavigateHome, "onHome should be invoked when triggered")
    }
}
