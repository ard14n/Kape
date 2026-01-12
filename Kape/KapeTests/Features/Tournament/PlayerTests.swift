import XCTest
@testable import Kape

final class PlayerTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testPlayerInitializesWithCorrectDefaults() {
        let player = Player(name: "Test Player")
        
        XCTAssertEqual(player.name, "Test Player")
        XCTAssertEqual(player.score, 0)
        XCTAssertTrue(player.sessionHistory.isEmpty)
        XCTAssertNotNil(player.id)
    }
    
    func testDefaultPlayerCreatesCorrectName() {
        let player1 = Player.defaultPlayer(index: 1)
        let player2 = Player.defaultPlayer(index: 2)
        let player5 = Player.defaultPlayer(index: 5)
        
        XCTAssertEqual(player1.name, "Lojtari 1")
        XCTAssertEqual(player2.name, "Lojtari 2")
        XCTAssertEqual(player5.name, "Lojtari 5")
    }
    
    // MARK: - Equatable Tests
    
    func testPlayersWithSameIdAreEqual() {
        let id = UUID()
        let player1 = Player(id: id, name: "Player A")
        let player2 = Player(id: id, name: "Player A")
        
        XCTAssertEqual(player1, player2)
    }
    
    func testPlayersWithDifferentIdsAreNotEqual() {
        let player1 = Player(name: "Same Name")
        let player2 = Player(name: "Same Name")
        
        XCTAssertNotEqual(player1, player2)
    }
}

final class SessionResultTests: XCTestCase {
    
    func testSessionResultPoints() {
        // 5 correct - 2 incorrect = 3 points
        let result = SessionResult(correctCount: 5, passCount: 1, incorrectCount: 2)
        XCTAssertEqual(result.points, 3)
    }
    
    func testSessionResultNegativePoints() {
        // 1 correct - 3 incorrect = -2 points
        let result = SessionResult(correctCount: 1, passCount: 2, incorrectCount: 3)
        XCTAssertEqual(result.points, -2)
    }
    
    func testSessionResultZeroPoints() {
        let result = SessionResult(correctCount: 2, passCount: 0, incorrectCount: 2)
        XCTAssertEqual(result.points, 0)
    }
}
