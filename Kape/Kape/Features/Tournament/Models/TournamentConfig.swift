import Foundation

/// Configuration for a tournament game session.
/// Contains players and rounds per player settings.
struct TournamentConfig: Equatable, Codable {
    /// Players participating in the tournament (2-5)
    var players: [Player]
    
    /// Number of rounds each player plays (1, 3, or 5)
    var roundsPerPlayer: Int
    
    /// Minimum players allowed
    static let minPlayers = 2
    
    /// Maximum players allowed
    static let maxPlayers = 5
    
    /// Available rounds per player options
    static let roundOptions = [1, 3, 5]
    
    /// Default rounds per player
    static let defaultRounds = 3
    
    /// Creates a default tournament configuration with 2 players
    init(
        players: [Player] = [
            Player.defaultPlayer(index: 1),
            Player.defaultPlayer(index: 2)
        ],
        roundsPerPlayer: Int = TournamentConfig.defaultRounds
    ) {
        self.players = players
        self.roundsPerPlayer = roundsPerPlayer
    }
    
    /// Whether the current configuration is valid for starting a tournament
    var isValid: Bool {
        // Must have 2-5 players
        guard players.count >= Self.minPlayers && players.count <= Self.maxPlayers else {
            return false
        }
        
        // All names must be at least 2 characters
        guard players.allSatisfy({ $0.name.trimmingCharacters(in: .whitespaces).count >= 2 }) else {
            return false
        }
        
        // Names must be unique
        let names = players.map { $0.name.trimmingCharacters(in: .whitespaces).lowercased() }
        let uniqueNames = Set(names)
        guard uniqueNames.count == names.count else {
            return false
        }
        
        // Rounds must be valid option
        guard Self.roundOptions.contains(roundsPerPlayer) else {
            return false
        }
        
        return true
    }
    
    /// Whether a new player can be added
    var canAddPlayer: Bool {
        players.count < Self.maxPlayers
    }
    
    /// Whether a player can be removed
    var canRemovePlayer: Bool {
        players.count > Self.minPlayers
    }
}
