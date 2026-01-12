import Foundation

/// Represents the current phase of a tournament.
/// Used by TournamentViewModel to manage state transitions.
enum TournamentPhase: String, Equatable, Codable {
    /// Initial setup phase - players and rounds being configured
    case setup
    
    /// Interstitial phase - showing "Pass the Device" screen before a player's turn
    case interstitial
    
    /// Playing phase - a player is actively playing their round
    case playing
    
    /// Tournament is complete - showing final leaderboard
    case finished
}

/// Represents the complete state of an active tournament.
/// This struct is persisted to JSON for crash recovery.
struct TournamentState: Equatable, Codable {
    /// All players in the tournament with their scores
    var players: [Player]
    
    /// Tournament configuration (rounds per player)
    let roundsPerPlayer: Int
    
    /// Current round number (1-indexed, up to roundsPerPlayer)
    var currentRound: Int
    
    /// Index of the current player in the players array
    var currentPlayerIndex: Int
    
    /// Current phase of the tournament
    var phase: TournamentPhase
    
    /// Creates initial tournament state from setup configuration
    /// - Parameter config: The validated tournament configuration
    init(from config: TournamentConfig) {
        self.players = config.players
        self.roundsPerPlayer = config.roundsPerPlayer
        self.currentRound = 1
        self.currentPlayerIndex = 0
        self.phase = .interstitial
    }
    
    /// Creates state from persistence (for crash recovery)
    init(
        players: [Player],
        roundsPerPlayer: Int,
        currentRound: Int,
        currentPlayerIndex: Int,
        phase: TournamentPhase
    ) {
        self.players = players
        self.roundsPerPlayer = roundsPerPlayer
        self.currentRound = currentRound
        self.currentPlayerIndex = currentPlayerIndex
        self.phase = phase
    }
    
    /// The currently active player
    var currentPlayer: Player {
        players[currentPlayerIndex]
    }
    
    /// Total number of individual turns in the tournament
    var totalTurns: Int {
        players.count * roundsPerPlayer
    }
    
    /// Current turn number (1-indexed, for display)
    var currentTurnNumber: Int {
        (currentRound - 1) * players.count + currentPlayerIndex + 1
    }
    
    /// Whether the tournament is complete
    var isComplete: Bool {
        phase == .finished
    }
    
    /// Whether the tournament is active (not setup or finished)
    var isTournamentActive: Bool {
        phase != .setup && phase != .finished
    }
}

