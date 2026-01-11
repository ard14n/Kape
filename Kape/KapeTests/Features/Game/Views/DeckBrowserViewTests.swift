import XCTest
import SwiftUI
@testable import Kape

/// Tests for DeckBrowserView and DeckService integration.
/// Note: SwiftUI views cannot be easily unit-tested for rendering.
/// These tests focus on DeckService logic that DeckBrowserView depends on.
@MainActor
final class DeckBrowserViewTests: XCTestCase {
    
    func testDeckBrowserView_WithNoDecks_InitializesCorrectly() {
        // Given: An empty deck service
        let deckService = DeckService(decks: [])
        
        // Then: Service properties are correct (what DeckBrowserView would see)
        XCTAssertTrue(deckService.decks.isEmpty, "Empty service should have no decks")
        XCTAssertTrue(deckService.freeDecks.isEmpty, "Empty service should have no free decks")
        XCTAssertTrue(deckService.proDecks.isEmpty, "Empty service should have no pro decks")
    }

    func testDeckBrowserView_WithDecks_InitializesCorrectly() {
        // Given: A deck service with multiple free decks
        let decks = [
            DeckFactory.make(id: "1", title: "Deck 1", isPro: false),
            DeckFactory.make(id: "2", title: "Deck 2", isPro: false)
        ]
        let deckService = DeckService(decks: decks)
        
        // Then: Service properties reflect the correct state for DeckBrowserView
        XCTAssertEqual(deckService.decks.count, 2, "Service should have 2 decks")
        XCTAssertEqual(deckService.freeDecks.count, 2, "Service should have 2 free decks")
        XCTAssertEqual(deckService.freeDecks[0].title, "Deck 1")
        XCTAssertEqual(deckService.freeDecks[1].title, "Deck 2")
    }
    
    func testDeckService_FreeDecksFiltersProDecks() {
        // Given: A mixed deck service
        let decks = [
            DeckFactory.make(id: "1", title: "Free Deck", isPro: false),
            DeckFactory.make(id: "2", title: "Pro Deck", isPro: true)
        ]
        let deckService = DeckService(decks: decks)
        
        // Then: freeDecks only contains non-pro decks
        XCTAssertEqual(deckService.freeDecks.count, 1)
        XCTAssertEqual(deckService.freeDecks[0].title, "Free Deck")
        XCTAssertEqual(deckService.proDecks.count, 1)
        XCTAssertEqual(deckService.proDecks[0].title, "Pro Deck")
    }
}

