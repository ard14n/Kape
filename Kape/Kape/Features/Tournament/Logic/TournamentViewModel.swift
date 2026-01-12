import Foundation
import Observation

/// ViewModel for tournament setup, managing players, rounds, and validation state.
/// Uses iOS 17+ @Observable macro for reactive state updates.
@Observable
final class TournamentViewModel {
    // MARK: - Published State
    
    /// Current tournament configuration
    var config: TournamentConfig = TournamentConfig()
    
    /// Whether the setup sheet is presented
    var isSetupSheetPresented: Bool = false
    
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
        config = TournamentConfig()
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
}
