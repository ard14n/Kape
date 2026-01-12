import Foundation
import Observation

/// ViewModel for tournament setup, managing players, rounds, and validation state.
/// Uses iOS 17+ @Observable macro for reactive state updates.
@Observable
@MainActor
final class TournamentViewModel {
    private let persistenceService = TournamentPersistenceService.shared
    // MARK: - Published State
    
    /// Current tournament configuration
    var config: TournamentConfig = TournamentConfig()
    
    /// Whether the setup sheet is presented
    var isSetupSheetPresented: Bool = false
    
    /// Current active tournament state
    var tournamentState: TournamentState?
    
    // MARK: - Computed Properties
    
    /// Whether the tournament can be started (valid configuration)
    var canStartTournament: Bool {
        config.isValid
    }
    
    /// Whether a new player can be added
    var canAddPlayer: Bool {
        config.canAddPlayer
    }
    
    /// Whether a player can be removed
    var canRemovePlayer: Bool {
        config.canRemovePlayer
    }
    
    /// Array of players for binding
    var players: [Player] {
        get { config.players }
        set { config.players = newValue }
    }
    
    /// Rounds per player for binding
    var roundsPerPlayer: Int {
        get { config.roundsPerPlayer }
        set { config.roundsPerPlayer = newValue }
    }
    
    /// Current active player
    var currentPlayer: Player {
        guard let state = tournamentState,
              state.players.indices.contains(state.currentPlayerIndex) else {
            return config.players.first ?? Player.defaultPlayer(index: 1)
        }
        return state.players[state.currentPlayerIndex]
    }
    
    // MARK: - Actions
    
    /// Add a new player with default name
    func addPlayer() {
        guard canAddPlayer else { return }
        let nextIndex = config.players.count + 1
        config.players.append(Player.defaultPlayer(index: nextIndex))
    }
    
    /// Remove a player at the specified index
    /// - Parameter index: The index of the player to remove
    func removePlayer(at index: Int) {
        guard canRemovePlayer else { return }
        guard config.players.indices.contains(index) else { return }
        config.players.remove(at: index)
    }
    
    /// Update a player's name at the specified index
    /// - Parameters:
    ///   - index: The index of the player
    ///   - name: The new name for the player
    func updatePlayerName(at index: Int, name: String) {
        guard config.players.indices.contains(index) else { return }
        config.players[index].name = name
    }
    
    /// Reset configuration to defaults
    func resetToDefaults() {
        players = [
            .defaultPlayer(index: 1),
            .defaultPlayer(index: 2)
        ]
        roundsPerPlayer = 3
    }
    
    /// Validates a player name
    /// - Parameter name: The name to validate
    /// - Returns: True if name is valid (at least 2 chars when trimmed)
    func isValidPlayerName(_ name: String) -> Bool {
        name.trimmingCharacters(in: .whitespaces).count >= 2
    }
    
    /// Show the tournament setup sheet
    func showSetup() {
        isSetupSheetPresented = true
    }
    
    /// Hide the setup sheet and reset if needed
    func dismissSetup() {
        isSetupSheetPresented = false
    }
    
    // MARK: - Tournament Flow
    
    /// Starts the tournament with current configuration
    func startTournament() {
        guard canStartTournament else { return }
        let config = TournamentConfig(players: players, roundsPerPlayer: roundsPerPlayer)
        tournamentState = TournamentState(from: config)
        persistCurrentState()
    }
    
    /// Transitions from interstitial to playing phase
    func startPlayerTurn() {
        guard var state = tournamentState, state.phase == .interstitial else { return }
        state.phase = .playing
        tournamentState = state
        persistCurrentState()
    }
    
    /// Records the score for the current player and advances turn
    /// - Parameter score: The score achieved in the round
    func recordScore(_ score: Int) {
        guard var state = tournamentState, state.phase == .playing else { return }
        
        // Update player score and history
        state.players[state.currentPlayerIndex].score += score
        
        // Note: For now we're just recording simple score. 
        // Real session result will be handled when GameEngine is integrated.
        let result = SessionResult(correctCount: score, passCount: 0, incorrectCount: 0)
        state.players[state.currentPlayerIndex].sessionHistory.append(result)
        
        nextTurn(in: &state)
        tournamentState = state
        persistCurrentState()
    }
    
    /// Advances to the next player or round
    /// - Parameter state: The current tournament state to modify
    private func nextTurn(in state: inout TournamentState) {
        let playercount = state.players.count
        
        // Increment player index
        state.currentPlayerIndex += 1
        
        // Check if round is finished
        if state.currentPlayerIndex >= playercount {
            state.currentPlayerIndex = 0
            state.currentRound += 1
        }
        
        // Check if tournament is finished
        if state.currentRound > state.roundsPerPlayer {
            state.phase = .finished
        } else {
            state.phase = .interstitial
        }
    }
    
    /// Attempts to resume a previous tournament from disk
    @discardableResult
    func resumeTournament() -> Bool {
        guard let snapshot = persistenceService.loadSnapshot() else { return false }
        let restoredState = snapshot.toState()

        // If a finished state is persisted, treat it as stale and clear.
        guard !restoredState.isComplete else {
            persistenceService.clear()
            return false
        }

        applyRestoredState(restoredState)
        return true
    }
    
    // MARK: - Leaderboard Logic

    /// Players sorted by score (descending)
    var rankedPlayers: [Player] {
        (tournamentState?.players ?? players).sorted { $0.score > $1.score }
    }
    
    /// Transitions to finished state
    func finishTournament() {
        guard var state = tournamentState else { return }
        state.phase = .finished
        tournamentState = state
        persistCurrentState()
    }
    
    /// Resets the tournament state but optionally keeps players
    /// - Parameter keepPlayers: Whether to keep the current player list (default: true)
    func resetTournament(keepPlayers: Bool = true) {
        // Clear active state
        tournamentState = nil
        persistenceService.clear()
        
        // Reset config if needed
        if !keepPlayers {
            resetToDefaults()
        } else {
            // Reset player scores for next time?
            // Actually, `players` in config are different from `state.players`.
            // `config.players` are just the setup definitions.
            // So we don't need to zero out scores in `config.players` because `Player` struct might have score=0 by default?
            // Let's check Player struct definition.
        }
        
        // Go back to setup
        isSetupSheetPresented = true 
        // Note: Logic for navigation depends on ContainerView. 
        // If state is nil, ContainerView shows SetupView.
    }
    
    /// Persist current state or clear when finished/absent.
    private func persistCurrentState() {
        guard let state = tournamentState else {
            persistenceService.clear()
            return
        }

        if state.isComplete {
            persistenceService.clear()
        } else {
            persistenceService.save(state: state)
        }
    }

    func applyRestoredState(_ state: TournamentState) {
        tournamentState = state
        players = state.players
        roundsPerPlayer = state.roundsPerPlayer
        isSetupSheetPresented = false
    }
}
