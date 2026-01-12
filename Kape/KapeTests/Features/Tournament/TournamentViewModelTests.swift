import XCTest
@testable import Kape

final class TournamentViewModelTests: XCTestCase {
    
    var viewModel: TournamentViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = TournamentViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialStateHasTwoPlayers() {
        XCTAssertEqual(viewModel.players.count, 2)
    }
    
    func testInitialStateHasDefaultRounds() {
        XCTAssertEqual(viewModel.roundsPerPlayer, 3)
    }
    
    func testInitialStateCanStartTournament() {
        XCTAssertTrue(viewModel.canStartTournament)
    }
    
    func testInitialStateCanAddPlayer() {
        XCTAssertTrue(viewModel.canAddPlayer)
    }
    
    func testInitialStateCannotRemovePlayer() {
        XCTAssertFalse(viewModel.canRemovePlayer)
    }
    
    // MARK: - Add Player Tests
    
    func testAddPlayerIncreasesCount() {
        viewModel.addPlayer()
        XCTAssertEqual(viewModel.players.count, 3)
    }
    
    func testAddPlayerCreatesDefaultName() {
        viewModel.addPlayer()
        XCTAssertEqual(viewModel.players.last?.name, "Lojtari 3")
    }
    
    func testCannotAddPlayerBeyondMax() {
        viewModel.addPlayer() // 3
        viewModel.addPlayer() // 4
        viewModel.addPlayer() // 5
        viewModel.addPlayer() // Should not add 6th
        
        XCTAssertEqual(viewModel.players.count, 5)
        XCTAssertFalse(viewModel.canAddPlayer)
    }
    
    // MARK: - Remove Player Tests
    
    func testRemovePlayerDecreasesCount() {
        viewModel.addPlayer() // Now 3 players
        viewModel.removePlayer(at: 2)
        XCTAssertEqual(viewModel.players.count, 2)
    }
    
    func testCannotRemovePlayerBelowMin() {
        // Default is 2 players, min is 2
        viewModel.removePlayer(at: 0) // Should not remove
        XCTAssertEqual(viewModel.players.count, 2)
    }
    
    func testRemovePlayerAtInvalidIndexDoesNothing() {
        viewModel.addPlayer() // 3 players
        viewModel.removePlayer(at: 10) // Invalid index
        XCTAssertEqual(viewModel.players.count, 3)
    }
    
    // MARK: - Update Name Tests
    
    func testUpdatePlayerNameChangesName() {
        viewModel.updatePlayerName(at: 0, name: "Ardi")
        XCTAssertEqual(viewModel.players[0].name, "Ardi")
    }
    
    func testUpdatePlayerNameAtInvalidIndexDoesNothing() {
        viewModel.updatePlayerName(at: 10, name: "Test")
        // No crash, players unchanged
        XCTAssertEqual(viewModel.players.count, 2)
    }
    
    // MARK: - Validation Tests
    
    func testIsValidPlayerNameWithTwoChars() {
        XCTAssertTrue(viewModel.isValidPlayerName("AB"))
    }
    
    func testIsValidPlayerNameWithOneChar() {
        XCTAssertFalse(viewModel.isValidPlayerName("A"))
    }
    
    func testIsValidPlayerNameWithEmpty() {
        XCTAssertFalse(viewModel.isValidPlayerName(""))
    }
    
    func testIsValidPlayerNameWithWhitespace() {
        XCTAssertFalse(viewModel.isValidPlayerName("   "))
    }
    
    func testCanStartTournamentWithInvalidName() {
        viewModel.updatePlayerName(at: 0, name: "A")
        XCTAssertFalse(viewModel.canStartTournament)
    }
    
    // MARK: - Rounds Tests
    
    func testSetRoundsPerPlayer() {
        viewModel.roundsPerPlayer = 5
        XCTAssertEqual(viewModel.config.roundsPerPlayer, 5)
    }
    
    // MARK: - Reset Tests
    
    func testResetToDefaults() {
        viewModel.addPlayer()
        viewModel.updatePlayerName(at: 0, name: "Custom")
        viewModel.roundsPerPlayer = 5
        
        viewModel.resetToDefaults()
        
        XCTAssertEqual(viewModel.players.count, 2)
        XCTAssertEqual(viewModel.roundsPerPlayer, 3)
        XCTAssertEqual(viewModel.players[0].name, "Lojtari 1")
    }
    
    // MARK: - Sheet Presentation Tests
    
    func testShowSetupSetsPresented() {
        viewModel.showSetup()
        XCTAssertTrue(viewModel.isSetupSheetPresented)
    }
    
    func testDismissSetupClearsPresented() {
        viewModel.isSetupSheetPresented = true
        viewModel.dismissSetup()
        XCTAssertFalse(viewModel.isSetupSheetPresented)
    }
}
