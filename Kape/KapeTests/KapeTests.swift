import XCTest
@testable import Kape

@MainActor
final class KapeTests: XCTestCase {
    
    var viewModel: TournamentViewModel!
    
    override func setUp() async throws {
        viewModel = TournamentViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
    }
    
    func testInitialState() {
        XCTAssertNil(viewModel.tournamentState)
        XCTAssertFalse(viewModel.isSetupSheetPresented)
    }
    
    func testStartTournament() {
        // Given
        viewModel.players = [
            Player(name: "Ana"),
            Player(name: "Beni")
        ]
        
        // When
        viewModel.startTournament()
        
        // Then
        guard let state = viewModel.tournamentState else {
            XCTFail("Tournament state should be active")
            return
        }
        
        XCTAssertEqual(state.phase, .interstitial, "Should move to interstitial to announce first player")
        XCTAssertEqual(state.currentPlayerIndex, 0, "Should start with first player")
        XCTAssertEqual(viewModel.currentPlayer.name, "Ana")
    }
    
    func testStartPlayerTurn() {
        // Given
        viewModel.players = [Player(name: "Ana"), Player(name: "Beni")]
        viewModel.startTournament() 
        // -> Interstitial (Ana)
        
        // When
        viewModel.startPlayerTurn()
        
        // Then
        XCTAssertEqual(viewModel.tournamentState?.phase, .playing, "Should move to playing phase")
    }
    
    func testRecordScoreAndNextTurn() {
        // Given
        viewModel.players = [Player(name: "Ana"), Player(name: "Beni")]
        viewModel.roundsPerPlayer = 1
        viewModel.startTournament() 
        // startTournament -> Interstitial (Ana)
        
        viewModel.startPlayerTurn() 
        // -> Playing (Ana)
        
        // When
        viewModel.recordScore(100)
        
        // Then
        // Expect: Ana score 100, Next Player: Beni (Interstitial)
        XCTAssertEqual(viewModel.tournamentState?.players[0].score, 100, "Should record score for Ana")
        XCTAssertEqual(viewModel.tournamentState?.phase, .interstitial, "Should go back to interstitial for next player")
        XCTAssertEqual(viewModel.tournamentState?.currentPlayerIndex, 1, "Should advance to Beni")
        XCTAssertEqual(viewModel.currentPlayer.name, "Beni")
    }
    
    func testTournamentCompletion() {
        // Given
        viewModel.players = [Player(name: "Ana"), Player(name: "Beni")]
        viewModel.roundsPerPlayer = 1
        viewModel.startTournament()
        // P1 Turn
        viewModel.startPlayerTurn()
        viewModel.recordScore(50)
        // -> Interstitial (P2)
        
        // P2 Turn
        viewModel.startPlayerTurn()
        
        // When
        viewModel.recordScore(50)
        
        // Then
        XCTAssertEqual(viewModel.tournamentState?.phase, .finished, "Should finish after last player of last round")
    }
    
    func testPersistence() {
        // Given
        let config = TournamentConfig(players: [
            Player(name: "Test1"),
            Player(name: "Test2")
        ])
        var state = TournamentState(from: config)
        state.currentRound = 2
        
        // When
        TournamentPersistenceService.shared.save(state: state)
        let loaded = TournamentPersistenceService.shared.loadState()
        
        // Then
        XCTAssertEqual(loaded?.players.first?.name, "Test1")
        XCTAssertEqual(loaded?.currentRound, 2)
    }
}
