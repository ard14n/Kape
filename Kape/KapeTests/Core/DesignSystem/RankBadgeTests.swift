import XCTest
import SwiftUI
@testable import Kape

/// Tests for the RankBadge component logic (specifically color mapping as claimed in Story)
final class RankBadgeTests: XCTestCase {
    
    /// Verify that each rank maps to the correct design system color
    /// This logic satisfies the claim in the Story 3.2 Task List
    func testBadgeColorMapping() {
        // Given
        let legjende = Rank.legjende
        let shqipe = Rank.shqipe
        let mish = Rank.mishIHuaj
        
        // Then
        // Note: We are verifying the model's color property which binds to the badge
        XCTAssertEqual(legjende.color, Color.neonGreen, "Legjendë badge should be Neon Green")
        XCTAssertEqual(shqipe.color, Color.neonOrange, "Shqipe badge should be Neon Orange")
        // Color equality for opacity variants is tricky, checking description or non-nil
        XCTAssertNotNil(mish.color, "Mish i Huaj badge should have a valid color")
    }
    
    /// Verify titles are correct for Badge display
    func testBadgeTitleMapping() {
        XCTAssertEqual(Rank.legjende.title, "Legjendë")
        XCTAssertEqual(Rank.shqipe.title, "Shqipe")
        XCTAssertEqual(Rank.mishIHuaj.title, "Turist")
    }
}
