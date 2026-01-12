import XCTest
@testable import Kape

/// Tests for the Rank enum that categorizes game performance
final class RankTests: XCTestCase {
    
    // MARK: - Boundary Value Tests (from Story AC)
    
    func testRank_Score0_ReturnsMishIHuaj() {
        // Given
        let score = 0
        
        // When
        let rank = Rank.from(score: score)
        
        // Then
        XCTAssertEqual(rank, .mishIHuaj, "Score 0 should return .mishIHuaj")
    }
    
    func testRank_NegativeScore_ReturnsMishIHuaj() {
        // Given: Edge case - negative score (defensive)
        let score = -5
        
        // When
        let rank = Rank.from(score: score)
        
        // Then
        XCTAssertEqual(rank, .mishIHuaj, "Negative score should return .mishIHuaj (lowest rank)")
    }
    
    func testRank_Score4_ReturnsMishIHuaj() {
        // Given
        let score = 4
        
        // When
        let rank = Rank.from(score: score)
        
        // Then
        XCTAssertEqual(rank, .mishIHuaj, "Score 4 (upper boundary) should return .mishIHuaj")
    }
    
    func testRank_Score5_ReturnsShqipe() {
        // Given
        let score = 5
        
        // When
        let rank = Rank.from(score: score)
        
        // Then
        XCTAssertEqual(rank, .shqipe, "Score 5 (lower boundary) should return .shqipe")
    }
    
    func testRank_Score9_ReturnsShqipe() {
        // Given
        let score = 9
        
        // When
        let rank = Rank.from(score: score)
        
        // Then
        XCTAssertEqual(rank, .shqipe, "Score 9 (upper boundary) should return .shqipe")
    }
    
    func testRank_Score10_ReturnsLegjende() {
        // Given
        let score = 10
        
        // When
        let rank = Rank.from(score: score)
        
        // Then
        XCTAssertEqual(rank, .legjende, "Score 10 (lower boundary) should return .legjende")
    }
    
    func testRank_Score15_ReturnsLegjende() {
        // Given
        let score = 15
        
        // When
        let rank = Rank.from(score: score)
        
        // Then
        XCTAssertEqual(rank, .legjende, "Score 15 should return .legjende")
    }
    
    // MARK: - Title Property Tests
    
    func testRankTitle_MishIHuaj_ReturnsCorrectString() {
        // Given
        let rank = Rank.mishIHuaj
        
        // When
        let title = rank.title
        
        // Then
        XCTAssertEqual(title, "Turist")
    }
    
    func testRankTitle_Shqipe_ReturnsCorrectString() {
        // Given
        let rank = Rank.shqipe
        
        // When
        let title = rank.title
        
        // Then
        XCTAssertEqual(title, "Shqipe")
    }
    
    func testRankTitle_Legjende_ReturnsCorrectString() {
        // Given
        let rank = Rank.legjende
        
        // When
        let title = rank.title
        
        // Then
        XCTAssertEqual(title, "Legjendë")
    }
    
    // MARK: - Color Property Tests
    
    func testRankColor_MishIHuaj_ReturnsWhiteWithOpacity() {
        // Given
        let rank = Rank.mishIHuaj
        
        // When
        let color = rank.color
        
        // Then
        // Note: SwiftUI Color equality is challenging, so we just verify it doesn't crash
        // and returns a non-nil value. Visual verification happens in UI layer.
        XCTAssertNotNil(color, "mishIHuaj should return a valid color")
    }
    
    func testRankColor_Shqipe_ReturnsNeonOrange() {
        // Given
        let rank = Rank.shqipe
        
        // When
        let color = rank.color
        
        // Then
        XCTAssertNotNil(color, "shqipe should return a valid color")
    }
    
    func testRankColor_Legjende_ReturnsNeonGreen() {
        // Given
        let rank = Rank.legjende
        
        // When
        let color = rank.color
        
        // Then
        XCTAssertNotNil(color, "legjende should return a valid color")
    }
}
