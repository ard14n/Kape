import Foundation

/// Represents a player in a tournament.
/// Each player has a unique ID, name, score, and session history.
struct Player: Identifiable, Equatable, Hashable {
    let id: UUID
    var name: String
    var score: Int
    var sessionHistory: [SessionResult]
    
    /// Creates a new player with the given name.
    /// - Parameter name: The player's display name
    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
        self.score = 0
        self.sessionHistory = []
    }
    
    /// Returns a player with a default name based on index.
    /// - Parameter index: 1-based player index (e.g., 1 for "Lojtari 1")
    static func defaultPlayer(index: Int) -> Player {
        Player(name: "Lojtari \(index)")
    }
}

/// Represents the result of a single game session for a player.
struct SessionResult: Identifiable, Equatable, Hashable {
    let id: UUID
    let correctCount: Int
    let passCount: Int
    let incorrectCount: Int
    let timestamp: Date
    
    init(
        id: UUID = UUID(),
        correctCount: Int,
        passCount: Int,
        incorrectCount: Int,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.correctCount = correctCount
        self.passCount = passCount
        self.incorrectCount = incorrectCount
        self.timestamp = timestamp
    }
    
    /// Total points earned in this session
    var points: Int {
        correctCount - incorrectCount
    }
}
