import Foundation

/// A separate, free starter set; original decks and purchase identifiers are preserved.
enum CharadesCatalog {
    static let mixedID = "all-categories"

    /// Keep Albanian letters distinct, but treat typography, case and spacing as the same word.
    static func wordKey(_ text: String) -> String {
        text.precomposedStringWithCanonicalMapping
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "‘", with: "'")
            .lowercased(with: Locale(identifier: "sq"))
            .split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    static func uniqueCards(_ cards: [Card]) -> [Card] {
        var words = Set<String>()
        var ids = Set<String>()
        return cards.filter {
            let key = wordKey($0.text)
            guard !key.isEmpty, !words.contains(key), !ids.contains($0.id) else { return false }
            words.insert(key)
            ids.insert($0.id)
            return true
        }
    }

    static func mixedDeck(from decks: [Deck]) -> Deck {
        var categories = Set<String>()
        let source = (decks + [starter]).filter { $0.id != mixedID && categories.insert($0.id).inserted }
        let cards = source.flatMap { deck in
            deck.cards.map { card in
                // Prefix with the category so locally reused card IDs cannot collide.
                Card(id: "\(deck.id.count):\(deck.id):\(card.id)", text: card.text,
                     category: Card.Category(id: deck.id, title: deck.title, iconName: deck.iconName))
            }
        }
        return Deck(id: mixedID, title: "Krejt kategoritë",
                    description: "Kategoria ndërron vetë. Fjalët s’përsëriten në këtë lojë.",
                    iconName: "shuffle", difficulty: 1, isPro: false,
                    cards: uniqueCards(cards), isNew: true)
    }

    static let starter = Deck(
        id: "pantomime", title: "Sa për fillim", description: "Fjalë të lehta për me hy n’lojë.",
        iconName: "theatermasks", difficulty: 1, isPro: false,
        // Explicit IDs keep the remaining cards stable when earlier entries are removed.
        cards: [
            (1, "Me notu"),
            (2, "Boks"),
            (3, "Me vrapu"),
            (4, "Me lujt valle"),
            (5, "Me zanë peshk"),
            (6, "Me gatu"),
            (7, "Me këndu"),
            (8, "Futboll"),
            (9, "Basketboll"),
            (10, "Tenis"),
            (11, "Me bo ski"),
            (14, "Me kalëru"),
            (15, "Me u ngjit n’mal"),
            (16, "Me i la dhambët"),
            (17, "Me i kreh flokët"),
            (18, "Me i lidh patikat"),
            (19, "Me hap ombrellën"),
            (20, "Me i la duart"),
            (21, "Me pi ujë"),
            (22, "Me hangër bananë"),
            (23, "Me pre bukë"),
            (26, "Me i hekurosë teshat"),
            (27, "Me mbjellë një dru"),
            (28, "Me ngas veturën"),
            (29, "Me bo foto"),
            (30, "Me lexu libër"),
            (31, "Me shkru letër"),
            (32, "Me i ra kitarës"),
            (33, "Me i ra pianos"),
            (34, "Me i ra lodrës"),
            (35, "Me hap dhuratën"),
            (36, "Me fry balonin"),
            (37, "Me mbajt bebën"),
            (38, "Me ec n’litar"),
            (39, "Me ngrit pesha"),
            (40, "Me kërcy me litar"),
            (41, "Qeni"),
            (42, "Macja"),
            (43, "Luani"),
            (44, "Elefanti"),
            (45, "Majmuni"),
            (46, "Lepuri"),
            (47, "Gjarpni"),
            (48, "Bretkosa"),
            (49, "Pinguini"),
            (50, "Pula"),
            (51, "Kali"),
            (52, "Ariu"),
            (53, "Flutura"),
            (54, "Zogu"),
            (55, "Roboti"),
            (56, "Kamarieri"),
            (57, "Berberi"),
            (58, "Dirigjenti"),
            (59, "Me fjetë"),
            (60, "Teshtima"),
            (61, "Selfie")
        ].map { Card(id: "pantomime-\($0.0)", text: $0.1) }
    )
}
