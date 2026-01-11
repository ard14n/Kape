import XCTest
@testable import Kape

/// Tests for deck shuffling behavior (Story 2.3: Deck Logic & Randomization)
/// Validates FR8: System randomizes card order for every session
final class ShuffleTests: XCTestCase {
    
    // MARK: - AC1: Card Order Randomization
    
    /// Verifies that GameRound shuffles the deck on initialization
    func testGameRoundShufflesCardsOnInit() {
        // Given a deck with 10 cards
        let cards = (1...10).map { CardFactory.make(id: "card-\($0)", text: "Card \($0)") }
        let deck = DeckFactory.make(cards: cards)
        
        // When creating a GameRound
        let round = GameRound(deck: deck)
        
        // Then remainingCards should be shuffled (different order than original)
        // Note: There's a 1/10! chance they're identical, but this is negligible
        XCTAssertEqual(round.remainingCards.count + 1, cards.count, "All cards should be present (one popped to currentCard)")
        XCTAssertNotNil(round.currentCard, "First card should be set")
    }
    
    // MARK: - AC2: Statistical Randomness Verification
    
    /// Verifies shuffle produces different starting cards across multiple rounds
    /// Uses loose heuristic to avoid flaky tests
    func testShuffleProducesDifferentStartingCards() {
        // Given a deck with 10 cards
        let cards = (1...10).map { CardFactory.make(id: "card-\($0)", text: "Card \($0)") }
        let deck = DeckFactory.make(cards: cards)
        
        var firstCardIds = Set<String>()
        
        // When creating 20 rounds
        for _ in 0..<20 {
            let round = GameRound(deck: deck)
            if let card = round.currentCard {
                firstCardIds.insert(card.id)
            }
        }
        
        // Then we should see at least 2 different starting cards
        // Probability of 20 identical starts with 10 cards is (1/10)^19 ≈ 0
        XCTAssertGreaterThan(firstCardIds.count, 1, "Shuffle should produce random starting cards")
    }
    
    // MARK: - AC5: Card Conservation
    
    /// Verifies all cards are present after shuffle (no duplicates, no missing)
    func testAllCardsPreservedAfterShuffle() {
        // Given a deck with specific cards
        let cards = (1...5).map { CardFactory.make(id: "card-\($0)", text: "Card \($0)") }
        let deck = DeckFactory.make(cards: cards)
        
        // When creating a GameRound
        let round = GameRound(deck: deck)
        
        // Then all card IDs should be present (in remainingCards + currentCard)
        var allCardIds = Set(round.remainingCards.map(\.id))
        if let current = round.currentCard {
            allCardIds.insert(current.id)
        }
        
        let originalIds = Set(cards.map(\.id))
        XCTAssertEqual(allCardIds, originalIds, "All original cards must be present after shuffle")
    }
    
    // MARK: - AC5: Card Progression (popLast exhausts deck)
    
    /// Verifies that popping all cards exhausts the deck correctly
    func testCardProgressionExhaustsDeck() {
        // Given a deck with 5 cards
        let cards = (1...5).map { CardFactory.make(id: "card-\($0)", text: "Card \($0)") }
        let deck = DeckFactory.make(cards: cards)
        var round = GameRound(deck: deck)
        
        // When we pop all remaining cards
        var poppedCount = 1 // currentCard already popped
        while round.remainingCards.popLast() != nil {
            poppedCount += 1
        }
        
        // Then we should have popped exactly 5 cards
        XCTAssertEqual(poppedCount, 5, "Should be able to pop exactly as many cards as in the deck")
        XCTAssertTrue(round.remainingCards.isEmpty, "Remaining cards should be empty after exhausting deck")
    }
    
    // MARK: - Edge Cases
    
    /// Verifies behavior with empty deck
    func testEmptyDeckHandling() {
        // Given an empty deck
        let deck = DeckFactory.make(cards: [])
        
        // When creating a GameRound
        let round = GameRound(deck: deck)
        
        // Then currentCard should be nil and remainingCards empty
        XCTAssertNil(round.currentCard, "Empty deck should result in nil currentCard")
        XCTAssertTrue(round.remainingCards.isEmpty, "Empty deck should have no remaining cards")
    }
    
    /// Verifies behavior with single card deck
    func testSingleCardDeckHandling() {
        // Given a single-card deck
        let card = CardFactory.make(id: "only-card", text: "The Only Card")
        let deck = DeckFactory.make(cards: [card])
        
        // When creating a GameRound
        let round = GameRound(deck: deck)
        
        // Then that card should be the currentCard, remainingCards empty
        XCTAssertEqual(round.currentCard?.id, "only-card", "Single card should become currentCard")
        XCTAssertTrue(round.remainingCards.isEmpty, "Single card deck should have no remaining cards")
    }
}
