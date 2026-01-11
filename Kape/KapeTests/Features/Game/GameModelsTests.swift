import XCTest
@testable import Kape

final class GameModelsTests: XCTestCase {
    func testGameStateEnum() {
        // Verify GameState cases
        XCTAssertEqual(GameState.idle, GameState.idle)
        XCTAssertEqual(GameState.buffer, GameState.buffer)
        XCTAssertEqual(GameState.playing, GameState.playing)
        XCTAssertEqual(GameState.paused, GameState.paused)
        XCTAssertEqual(GameState.finished, GameState.finished)
    }

    func testGameRoundStruct() {
        // Verify GameRound initialization
        let card = Card(id: "1", text: "Test")
        let round = GameRound(score: 0, timeRemaining: 60, currentCard: card)
        
        XCTAssertEqual(round.score, 0)
        XCTAssertEqual(round.timeRemaining, 60)
        XCTAssertEqual(round.currentCard?.text, "Test")
    }
}
