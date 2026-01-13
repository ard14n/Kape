import XCTest
@testable import Kape
import SwiftUI

/// Tests for Leaderboard Exit (Story 6.5)
final class LeaderboardExitTests: XCTestCase {
    
    // MARK: - Navigation Callback Tests
    
    /// Test that LeaderboardView accepts an onExit callback
    @MainActor
    func testLeaderboardView_AcceptsOnExitCallback() {
        // Given: A view model with mocked data
        let vm = TournamentViewModel()
        vm.config.players = [Player(name: "Test")]
        var didExit = false
        
        // When: Initialize LeaderboardView with onExit callback
        let view = LeaderboardView(
            viewModel: vm,
            onExit: { didExit = true }
        )
        view.onExit?()
        
        // Then: View should initialize and trigger callback
        XCTAssertNotNil(view, "LeaderboardView should initialize with onExit callback")
        XCTAssertTrue(didExit, "onExit should be invoked when triggered")
    }
}
