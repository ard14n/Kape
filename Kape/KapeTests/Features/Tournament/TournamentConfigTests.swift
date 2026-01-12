import XCTest
@testable import Kape

@MainActor final class TournamentConfigTests: XCTestCase {
    
    // MARK: - Default Configuration Tests
    
    func testDefaultConfigHasTwoPlayers() {
        let config = TournamentConfig()
        XCTAssertEqual(config.players.count, 2)
    }
    
    func testDefaultConfigHasDefaultRounds() {
        let config = TournamentConfig()
        XCTAssertEqual(config.roundsPerPlayer, 3)
    }
    
    func testDefaultConfigIsValid() {
        let config = TournamentConfig()
        XCTAssertTrue(config.isValid)
    }
    
    // MARK: - Validation Tests
    
    func testConfigWithOnePlayerIsInvalid() {
        var config = TournamentConfig()
        config.players = [Player.defaultPlayer(index: 1)]
        XCTAssertFalse(config.isValid)
    }
    
    func testConfigWithSixPlayersIsInvalid() {
        var config = TournamentConfig()
        config.players = (1...6).map { Player.defaultPlayer(index: $0) }
        XCTAssertFalse(config.isValid)
    }
    
    func testConfigWithFivePlayersIsValid() {
        var config = TournamentConfig()
        config.players = (1...5).map { Player.defaultPlayer(index: $0) }
        XCTAssertTrue(config.isValid)
    }
    
    func testConfigWithEmptyPlayerNameIsInvalid() {
        var config = TournamentConfig()
        config.players[0].name = ""
        XCTAssertFalse(config.isValid)
    }
    
    func testConfigWithSingleCharNameIsInvalid() {
        var config = TournamentConfig()
        config.players[0].name = "A"
        XCTAssertFalse(config.isValid)
    }
    
    func testConfigWithTwoCharNameIsValid() {
        var config = TournamentConfig()
        config.players[0].name = "AB"
        config.players[1].name = "CD"
        XCTAssertTrue(config.isValid)
    }
    
    func testConfigWithWhitespaceOnlyNameIsInvalid() {
        var config = TournamentConfig()
        config.players[0].name = "   "
        XCTAssertFalse(config.isValid)
    }
    
    func testConfigWithInvalidRoundsIsInvalid() {
        var config = TournamentConfig()
        config.roundsPerPlayer = 2 // Not 1, 3, or 5
        XCTAssertFalse(config.isValid)
    }
    
    func testConfigWithValidRoundsOptions() {
        for rounds in [1, 3, 5] {
            var config = TournamentConfig()
            config.roundsPerPlayer = rounds
            XCTAssertTrue(config.isValid, "Rounds \(rounds) should be valid")
        }
    }
    
    // MARK: - Add/Remove Player Tests
    
    func testCanAddPlayerWhenUnderMax() {
        var config = TournamentConfig()
        config.players = (1...4).map { Player.defaultPlayer(index: $0) }
        XCTAssertTrue(config.canAddPlayer)
    }
    
    func testCannotAddPlayerWhenAtMax() {
        var config = TournamentConfig()
        config.players = (1...5).map { Player.defaultPlayer(index: $0) }
        XCTAssertFalse(config.canAddPlayer)
    }
    
    func testCanRemovePlayerWhenAboveMin() {
        var config = TournamentConfig()
        config.players = (1...3).map { Player.defaultPlayer(index: $0) }
        XCTAssertTrue(config.canRemovePlayer)
    }
    
    func testCannotRemovePlayerWhenAtMin() {
        let config = TournamentConfig() // Default has 2 players
        XCTAssertFalse(config.canRemovePlayer)
    }
}
