import XCTest
@testable import Kape

@MainActor
final class TournamentViewModelTests: XCTestCase {
    
    var viewModel: TournamentViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        TournamentPersistenceService.shared.clear()
        viewModel = await TournamentViewModel()
    }
    
    override func tearDown() async throws {
        viewModel = nil
        TournamentPersistenceService.shared.clear()
        try await super.tearDown()
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
        XCTAssertEqual(viewModel.roundsPerPlayer, 5)
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
    
    // MARK: - Tournament State Machine Tests
    
    func testStartTournamentInitializesState() {
        viewModel.startTournament()
        
        XCTAssertNotNil(viewModel.tournamentState)
        XCTAssertEqual(viewModel.tournamentState?.phase, .interstitial)
        XCTAssertEqual(viewModel.tournamentState?.currentPlayerIndex, 0)
        XCTAssertEqual(viewModel.tournamentState?.currentRound, 1)
    }
    
    func testStartPlayerTurnChangesPhaseToPlaying() {
        viewModel.startTournament()
        viewModel.startPlayerTurn()
        
        XCTAssertEqual(viewModel.tournamentState?.phase, .playing)
    }
    
    func testRecordScoreAdvancesToNextPlayer() {
        viewModel.startTournament()
        viewModel.startPlayerTurn()
        
        // Initial state: Player 0, Round 1
        viewModel.recordScore(10)
        
        XCTAssertEqual(viewModel.tournamentState?.currentPlayerIndex, 1)
        XCTAssertEqual(viewModel.tournamentState?.phase, .interstitial)
    }
    
    func testRecordScoreAtEndOfRoundAdvancesToNextRound() {
        // Assume 2 players (default)
        viewModel.startTournament()
        
        // Player 0 turn
        viewModel.startPlayerTurn()
        viewModel.recordScore(5)
        
        // Player 1 turn
        viewModel.startPlayerTurn()
        viewModel.recordScore(8)
        
        XCTAssertEqual(viewModel.tournamentState?.currentPlayerIndex, 0)
        XCTAssertEqual(viewModel.tournamentState?.currentRound, 2)
        XCTAssertEqual(viewModel.tournamentState?.phase, .interstitial)
    }
    
    func testTournamentFinishesAfterAllRounds() {
        // Setup with 2 players and 1 round for quick test
        viewModel.roundsPerPlayer = 1
        viewModel.startTournament()
        
        // Player 0
        viewModel.startPlayerTurn()
        viewModel.recordScore(10)
        
        // Player 1
        viewModel.startPlayerTurn()
        viewModel.recordScore(10)
        
        XCTAssertEqual(viewModel.tournamentState?.phase, .finished)
        XCTAssertTrue(viewModel.tournamentState?.isComplete ?? false)
    }
    
    func testResumeTournamentReloadsFromDisk() {
        // 1. Setup initial condition
        viewModel.updatePlayerName(at: 0, name: "PersistedPlayer")
        viewModel.roundsPerPlayer = 5
        
        // 2. Start tournament (triggers save)
        viewModel.startTournament() 
        
        // 3. Modifiy state more (triggers save)
        viewModel.startPlayerTurn()
        viewModel.recordScore(12) 
        
        // 4. Create new VM and resume
        let newViewModel = TournamentViewModel()
        newViewModel.resumeTournament()
        
        // 5. Verify
        XCTAssertNotNil(newViewModel.tournamentState, "Tournament state should have been reloaded from disk")
        XCTAssertEqual(newViewModel.tournamentState?.players[0].score, 12, "Reloaded score should match persisted one")
        XCTAssertEqual(newViewModel.players[0].name, "PersistedPlayer", "ViewModel configuration should be updated from reloaded state")
        XCTAssertEqual(newViewModel.roundsPerPlayer, 5, "Rounds per player should be reloaded")
    }

    func testFinishedTournamentClearsPersistence() {
        viewModel.roundsPerPlayer = 1
        viewModel.startTournament()

        viewModel.startPlayerTurn()
        viewModel.recordScore(5)
        viewModel.startPlayerTurn()
        viewModel.recordScore(6) // finishes tournament

        XCTAssertFalse(TournamentPersistenceService.shared.hasPersistedState)
    }

    func testResumeIgnoresFinishedSnapshots() {
        viewModel.roundsPerPlayer = 1
        viewModel.startTournament()
        viewModel.startPlayerTurn()
        viewModel.recordScore(5)
        viewModel.startPlayerTurn()
        viewModel.recordScore(6)

        // Manually persist a finished state for safety check
        if let finishedState = viewModel.tournamentState {
            TournamentPersistenceService.shared.save(state: finishedState)
        }

        let newViewModel = TournamentViewModel()
        newViewModel.resumeTournament()

        XCTAssertNil(newViewModel.tournamentState)
        XCTAssertFalse(TournamentPersistenceService.shared.hasPersistedState)
    }
    // MARK: - Leaderboard Logic Tests
    
    func testRankedPlayersReturnsSortedList() {
        // Setup
        viewModel.roundsPerPlayer = 1
        viewModel.startTournament()
        
        // P1 Score: 10
        viewModel.startPlayerTurn()
        viewModel.recordScore(10)
        
        // P2 Score: 20
        viewModel.startPlayerTurn()
        viewModel.recordScore(20)
        
        // Verify P2 is first (20 > 10)
        let ranked = viewModel.rankedPlayers
        XCTAssertEqual(ranked.count, 2)
        XCTAssertEqual(ranked[0].name, "Lojtari 2")
        XCTAssertEqual(ranked[0].score, 20)
        XCTAssertEqual(ranked[1].name, "Lojtari 1")
        XCTAssertEqual(ranked[1].score, 10)
    }
    
    func testFinishTournamentTransitionsToFinished() {
        viewModel.startTournament()
        viewModel.finishTournament()
        
        XCTAssertNotNil(viewModel.tournamentState)
        XCTAssertEqual(viewModel.tournamentState?.phase, .finished)
    }
    
    func testResetTournamentClearsState() {
        viewModel.startTournament()
        
        viewModel.resetTournament(keepPlayers: true)
        
        XCTAssertNil(viewModel.tournamentState)
        XCTAssertTrue(viewModel.isSetupSheetPresented)
    }
    
    func testResetTournamentKeepsPlayersInConfig() {
        viewModel.addPlayer() // 3 total
        viewModel.updatePlayerName(at: 0, name: "Winner")
        
        viewModel.startTournament()
        viewModel.resetTournament(keepPlayers: true)
        
        // Verify config is preserved
        XCTAssertEqual(viewModel.players.count, 3)
        XCTAssertEqual(viewModel.players[0].name, "Winner")
    }
    
    func testResetTournamentWithoutKeepingPlayersResetsConfig() {
        viewModel.addPlayer() // 3 total
        viewModel.updatePlayerName(at: 0, name: "Winner")
        
        viewModel.startTournament()
        viewModel.resetTournament(keepPlayers: false)
        
        // Verify config is reset (default 2 players)
        XCTAssertEqual(viewModel.players.count, 2)
        XCTAssertEqual(viewModel.players[0].name, "Lojtari 1")
    }
}
