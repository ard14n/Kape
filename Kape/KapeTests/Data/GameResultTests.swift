import XCTest
@testable import Kape

/// Tests for the GameResult model
final class GameResultTests: XCTestCase {
    
    // MARK: - Computed Property Tests
    
    func testTotal_AddsScoreAndPassed() {
        // Given
        let result = GameResult(score: 10, passed: 5, date: Date())
        
        // When
        let total = result.total
        
        // Then
        XCTAssertEqual(total, 15, "Total should be score + passed")
    }
    
    func testAccuracy_WithValidTotal_ReturnsCorrectPercentage() {
        // Given
        let result = GameResult(score: 10, passed: 5, date: Date())
        
        // When
        let accuracy = result.accuracy
        
        // Then
        XCTAssertEqual(accuracy, 10.0 / 15.0, accuracy: 0.0001, "Accuracy should be score / total")
    }
    
    func testAccuracy_WithZeroTotal_ReturnsZero() {
        // Given: total = 0 (score=0, passed=0)
        let result = GameResult(score: 0, passed: 0, date: Date())
        
        // When
        let accuracy = result.accuracy
        
        // Then
        XCTAssertEqual(accuracy, 0.0, "Accuracy with total=0 should return 0.0 (no divide-by-zero crash)")
    }
    
    func testAccuracy_WithOnlyScore_ReturnsOne() {
        // Given
        let result = GameResult(score: 5, passed: 0, date: Date())
        
        // When
        let accuracy = result.accuracy
        
        // Then
        XCTAssertEqual(accuracy, 1.0, "Accuracy with all correct should be 100%")
    }
    
    func testAccuracy_WithOnlyPassed_ReturnsZero() {
        // Given
        let result = GameResult(score: 0, passed: 5, date: Date())
        
        // When
        let accuracy = result.accuracy
        
        // Then
        XCTAssertEqual(accuracy, 0.0, "Accuracy with no correct answers should be 0%")
    }
    
    // MARK: - Rank Property Tests
    
    func testRank_WithScore0_ReturnsMishIHuaj() {
        // Given
        let result = GameResult(score: 0, passed: 5, date: Date())
        
        // When
        let rank = result.rank
        
        // Then
        XCTAssertEqual(rank, .mishIHuaj)
    }
    
    func testRank_WithScore5_ReturnsShqipe() {
        // Given
        let result = GameResult(score: 5, passed: 5, date: Date())
        
        // When
        let rank = result.rank
        
        // Then
        XCTAssertEqual(rank, .shqipe)
    }
    
    func testRank_WithScore10_ReturnsLegjende() {
        // Given
        let result = GameResult(score: 10, passed: 5, date: Date())
        
        // When
        let rank = result.rank
        
        // Then
        XCTAssertEqual(rank, .legjende)
    }
    
    // MARK: - Factory Method Tests
    
    func testFrom_GameRound_MapsFieldsCorrectly() {
        // Given
        let round = GameRound(score: 8, passed: 3, timeRemaining: 30, currentCard: nil)
        
        // When
        let result = GameResult.from(round)
        
        // Then
        XCTAssertEqual(result.score, 8, "Score should be mapped from GameRound")
        XCTAssertEqual(result.passed, 3, "Passed should be mapped from GameRound")
        XCTAssertEqual(result.total, 11, "Total should be score + passed")
        // Date is current time, just verify it's set
        XCTAssertNotNil(result.date)
    }
    
    func testFrom_GameRound_WithPassedCards_MapsCorrectly() {
        // Given: GameRound with both score and passed
        let round = GameRound(score: 7, passed: 5, timeRemaining: 0, currentCard: nil)
        
        // When
        let result = GameResult.from(round)
        
        // Then
        XCTAssertEqual(result.score, 7, "Score should be mapped correctly")
        XCTAssertEqual(result.passed, 5, "Passed should be mapped correctly")
        XCTAssertEqual(result.total, 12, "Total should be score + passed")
        XCTAssertEqual(result.accuracy, 7.0/12.0, accuracy: 0.0001, "Accuracy should be calculated correctly")
    }
    
    func testEquality_SameValues_ReturnsTrue() {
        // Given
        let date = Date()
        let result1 = GameResult(score: 10, passed: 5, date: date)
        let result2 = GameResult(score: 10, passed: 5, date: date)
        
        // When/Then
        XCTAssertEqual(result1, result2, "GameResults with same values should be equal")
    }
    
    func testEquality_DifferentScores_ReturnsFalse() {
        // Given
        let date = Date()
        let result1 = GameResult(score: 10, passed: 5, date: date)
        let result2 = GameResult(score: 8, passed: 5, date: date)
        
        // When/Then
        XCTAssertNotEqual(result1, result2, "GameResults with different scores should not be equal")
    }
}
