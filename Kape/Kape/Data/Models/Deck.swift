import Foundation

/// Represents a deck of cards for the Kape! game.
/// Decks can be free or premium (Pro) and contain cultural content.
struct Deck: Identifiable, Codable, Equatable {
    /// Unique identifier for the deck (e.g., "mix-shqip")
    let id: String
    
    /// Display title of the deck (e.g., "Mix Shqip")
    let title: String
    
    /// Description of the deck's content theme
    let description: String
    
    /// SF Symbol name for the deck icon (used with neonGlow)
    let iconName: String
    
    /// Difficulty level: 1 (easy) to 3 (hard)
    let difficulty: Int
    
    /// Whether this deck requires VIP purchase to unlock
    let isPro: Bool
    
    /// Cards contained in this deck
    let cards: [Card]
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, cards, difficulty
        case iconName = "icon_name"
        case isPro = "is_pro"
    }
}

/// Represents a single card with a word or phrase to guess.
struct Card: Identifiable, Codable, Equatable {
    /// Unique identifier for the card
    let id: String
    
    /// The word or phrase displayed on the card
    let text: String
}

/// Wrapper struct for decoding the JSON root object
struct DecksContainer: Codable {
    let decks: [Deck]
}
