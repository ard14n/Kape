import XCTest
@testable import Kape

final class TournamentSetupViewTests: XCTestCase {
    
    var viewModel: TournamentViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = TournamentViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - AC1: Tournament Entry (Turne button presents sheet)
    
    func testShowSetupPresentsSheet() {
        XCTAssertFalse(viewModel.isSetupSheetPresented)
        viewModel.showSetup()
        XCTAssertTrue(viewModel.isSetupSheetPresented)
    }
    
    // MARK: - AC2: Player Configuration (2-5 players)
    
    func testMinimumTwoPlayers() {
        XCTAssertEqual(viewModel.players.count, 2)
        XCTAssertFalse(viewModel.canRemovePlayer)
    }
    
    func testMaximumFivePlayers() {
        viewModel.addPlayer()
        viewModel.addPlayer()
        viewModel.addPlayer() // Now at 5
        
        XCTAssertEqual(viewModel.players.count, 5)
        XCTAssertFalse(viewModel.canAddPlayer)
    }
    
    // MARK: - AC3: Default Names
    
    func testDefaultNamesProvidedForQuickStart() {
        XCTAssertEqual(viewModel.players[0].name, "Lojtari 1")
        XCTAssertEqual(viewModel.players[1].name, "Lojtari 2")
    }
    
    func testNewPlayerGetsDefaultName() {
        viewModel.addPlayer()
        XCTAssertEqual(viewModel.players[2].name, "Lojtari 3")
    }
    
    // MARK: - AC4: Custom Names (Min 2 chars)
    
    func testCustomNameCanBeSet() {
        viewModel.updatePlayerName(at: 0, name: "Ardi")
        XCTAssertEqual(viewModel.players[0].name, "Ardi")
    }
    
    func testNameWithOneCharIsInvalid() {
        viewModel.updatePlayerName(at: 0, name: "A")
        XCTAssertFalse(viewModel.canStartTournament)
    }
    
    func testNameWithTwoCharsIsValid() {
        viewModel.updatePlayerName(at: 0, name: "AB")
        viewModel.updatePlayerName(at: 1, name: "CD")
        XCTAssertTrue(viewModel.canStartTournament)
    }
    
    // MARK: - AC5: Round Configuration (1, 3, 5 - default 3)
    
    func testDefaultRoundsIsThree() {
        XCTAssertEqual(viewModel.roundsPerPlayer, 3)
    }
    
    func testCanSetRoundsToOne() {
        viewModel.roundsPerPlayer = 1
        XCTAssertEqual(viewModel.config.roundsPerPlayer, 1)
        XCTAssertTrue(viewModel.canStartTournament)
    }
    
    func testCanSetRoundsToFive() {
        viewModel.roundsPerPlayer = 5
        XCTAssertEqual(viewModel.config.roundsPerPlayer, 5)
        XCTAssertTrue(viewModel.canStartTournament)
    }
    
    // MARK: - AC6: Validation (Start button disabled until valid)
    
    func testCanStartTournamentWithValidConfig() {
        // Default config is valid
        XCTAssertTrue(viewModel.canStartTournament)
    }
    
    func testCannotStartTournamentWithEmptyName() {
        viewModel.updatePlayerName(at: 0, name: "")
        XCTAssertFalse(viewModel.canStartTournament)
    }
    
    func testCannotStartTournamentWithWhitespaceName() {
        viewModel.updatePlayerName(at: 0, name: "   ")
        XCTAssertFalse(viewModel.canStartTournament)
    }
    
    func testCannotStartTournamentWithDuplicateNames() {
        viewModel.updatePlayerName(at: 0, name: "Ardi")
        viewModel.updatePlayerName(at: 1, name: "Ardi")
        XCTAssertFalse(viewModel.canStartTournament)
    }
    
    func testCannotStartTournamentWithDuplicateNamesCaseInsensitive() {
        viewModel.updatePlayerName(at: 0, name: "Ardi")
        viewModel.updatePlayerName(at: 1, name: "ARDI")
        XCTAssertFalse(viewModel.canStartTournament)
    }
}
