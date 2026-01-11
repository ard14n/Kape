import Foundation

enum GameState: Equatable {
    case idle
    case buffer
    case playing
    case paused
    case finished
}

/// Represents a single game round with score, timer, and card progression.
/// Cards are shuffled on initialization to ensure randomness (FR8).
struct GameRound: Equatable {
    var score: Int = 0
    var passed: Int = 0
    var timeRemaining: TimeInterval = 60
    var currentCard: Card?
    
    var deck: Deck
    /// Shuffled cards remaining to be played. Uses Fisher-Yates shuffle via Swift stdlib.
    var remainingCards: [Card]
    
    /// Initializes a new game round with a shuffled deck.
    /// - Parameters:
    ///   - deck: The deck to play with. Cards are shuffled immediately.
    ///   - timeRemaining: Game duration in seconds (default: 60).
    /// - Note: Shuffle happens on every init, ensuring each session is unique (AC1, AC2).
    init(deck: Deck, timeRemaining: TimeInterval = 60) {
        self.deck = deck
        self.timeRemaining = timeRemaining
        self.remainingCards = deck.cards.shuffled()
        self.currentCard = self.remainingCards.popLast()
    }
    
    // Test helper
    init(score: Int, passed: Int = 0, timeRemaining: TimeInterval, currentCard: Card?) {
        self.score = score
        self.passed = passed
        self.timeRemaining = timeRemaining
        self.currentCard = currentCard
        self.deck = Deck(
            id: "test",
            title: "Test",
            description: "Test Deck",
            iconName: "star",
            difficulty: 1,
            isPro: false,
            cards: []
        )
        self.remainingCards = []
    }
}
