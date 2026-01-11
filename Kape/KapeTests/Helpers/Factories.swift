import Foundation
@testable import Kape

/// Thread-safe test factories for creating test data.
/// Uses atomic counters instead of UUID() to prevent malloc crashes in parallel tests.

// MARK: - Card Factory

struct CardFactory {
    /// Thread-safe counter for generating unique card IDs
    private static let queue = DispatchQueue(label: "CardFactory.counter")
    private static var _counter: Int = 0
    
    private static var nextId: String {
        queue.sync {
            _counter += 1
            return "test-card-\(_counter)"
        }
    }
    
    /// Creates a test Card with optional overrides.
    /// - Parameters:
    ///   - id: Card identifier (auto-generated if nil)
    ///   - text: Card text content
    /// - Returns: A new Card instance
    static func make(
        id: String? = nil,
        text: String = "Test Card"
    ) -> Card {
        return Card(id: id ?? nextId, text: text)
    }
    
    /// Resets the counter (call in setUp if needed for deterministic tests)
    static func resetCounter() {
        queue.sync { _counter = 0 }
    }
}

// MARK: - Deck Factory

struct DeckFactory {
    /// Thread-safe counter for generating unique deck IDs
    private static let queue = DispatchQueue(label: "DeckFactory.counter")
    private static var _counter: Int = 0
    
    private static var nextId: String {
        queue.sync {
            _counter += 1
            return "test-deck-\(_counter)"
        }
    }
    
    /// Creates a test Deck with optional overrides.
    /// - Parameters:
    ///   - id: Deck identifier (auto-generated if nil)
    ///   - title: Deck title
    ///   - description: Deck description
    ///   - iconName: SF Symbol name
    ///   - difficulty: Difficulty level (1-3)
    ///   - isPro: Whether deck requires VIP
    ///   - cards: Optional card array (generates 3 default cards if nil)
    /// - Returns: A new Deck instance
    static func make(
        id: String? = nil,
        title: String = "Test Deck",
        description: String = "A test deck",
        iconName: String = "star.fill",
        difficulty: Int = 1,
        isPro: Bool = false,
        cards: [Card]? = nil
    ) -> Deck {
        let defaultCards = [
            CardFactory.make(text: "Card 1"),
            CardFactory.make(text: "Card 2"),
            CardFactory.make(text: "Card 3")
        ]
        return Deck(
            id: id ?? nextId,
            title: title,
            description: description,
            iconName: iconName,
            difficulty: difficulty,
            isPro: isPro,
            cards: cards ?? defaultCards
        )
    }
    
    /// Resets the counter (call in setUp if needed for deterministic tests)
    static func resetCounter() {
        queue.sync { _counter = 0 }
    }
}

// MARK: - GameResult Factory (TEA Recommendation)

struct GameResultFactory {
    /// Creates a test GameResult with optional overrides.
    /// - Parameters:
    ///   - score: Number of correct answers (default: 10)
    ///   - passed: Number of passed cards (default: 2)
    ///   - date: Result date (default: now)
    /// - Returns: A new GameResult instance
    static func make(
        score: Int = 10,
        passed: Int = 2,
        date: Date = Date()
    ) -> GameResult {
        return GameResult(score: score, passed: passed, date: date)
    }
    
    /// Creates a GameResult for a specific rank
    /// - Parameter rank: Target rank (.legjende, .shqipe, .mishIHuaj)
    /// - Returns: GameResult with appropriate score for that rank
    static func make(forRank rank: Rank) -> GameResult {
        switch rank {
        case .legjende:
            return make(score: 10, passed: 0)
        case .shqipe:
            return make(score: 7, passed: 3)
        case .mishIHuaj:
            return make(score: 3, passed: 5)
        }
    }
}

// MARK: - KapeProduct Factory

struct KapeProductFactory {
    /// Creates a test KapeProduct with optional overrides.
    static func make(
        id: String = "test.product.vip",
        displayName: String = "VIP Deck",
        displayPrice: String = "$2.99",
        productType: KapeProduct.ProductType = .nonConsumable
    ) -> KapeProduct {
        return KapeProduct(
            id: id,
            displayName: displayName,
            displayPrice: displayPrice,
            productType: productType
        )
    }
}
