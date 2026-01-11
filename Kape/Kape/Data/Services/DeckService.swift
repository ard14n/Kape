import Foundation
import Combine

/// Service responsible for loading and providing access to game decks.
/// Uses `ObservableObject` for SwiftUI state management (replaced @Observable to fix physical device crash).
final class DeckService: ObservableObject {
    /// All available decks loaded from the bundle
    @Published private(set) var decks: [Deck] = []
    
    /// Error encountered during loading (if any)
    @Published private(set) var loadingError: Error?
    
    /// Free decks available to all users
    var freeDecks: [Deck] {
        decks.filter { !$0.isPro }
    }
    
    /// Premium decks requiring VIP purchase
    var proDecks: [Deck] {
        decks.filter { $0.isPro }
    }
    
    /// Initializes the service and loads decks from the bundle.
    /// - Parameter bundle: The bundle containing decks.json (defaults to .main)
    init(bundle: Bundle = .main) {
        loadDecks(from: bundle)
    }
    
    /// Internal initializer for testing with pre-loaded decks
    /// - Parameter decks: Array of decks to inject directly
    init(decks: [Deck]) {
        self.decks = decks
    }
    
    /// Loads decks synchronously from the specified bundle.
    /// Synchronous loading is acceptable for local JSON resources.
    private func loadDecks(from bundle: Bundle) {
        guard let url = bundle.url(forResource: "decks", withExtension: "json") else {
            loadingError = DeckServiceError.fileNotFound
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let container = try JSONDecoder().decode(DecksContainer.self, from: data)
            self.decks = container.decks
        } catch let decodingError as DecodingError {
            loadingError = DeckServiceError.decodingFailed(decodingError)
        } catch {
            loadingError = DeckServiceError.loadFailed(error)
        }
    }
    
    /// Returns a deck by its ID, if it exists.
    func deck(withId id: String) -> Deck? {
        decks.first { $0.id == id }
    }
}

/// Errors that can occur when loading decks
enum DeckServiceError: Error, LocalizedError {
    case fileNotFound
    case decodingFailed(DecodingError)
    case loadFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "decks.json not found in bundle"
        case .decodingFailed(let error):
            return "Failed to decode decks.json: \(error.localizedDescription)"
        case .loadFailed(let error):
            return "Failed to load decks: \(error.localizedDescription)"
        }
    }
}
