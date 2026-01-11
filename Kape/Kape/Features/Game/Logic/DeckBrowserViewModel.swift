import Foundation
import Combine

@MainActor
final class DeckBrowserViewModel: ObservableObject {
    @Published var selectedDeck: Deck?
    @Published var showPurchaseSheet = false
    
    /// Handles deck selection logic based on lock status.
    /// - Parameters:
    ///   - deck: The deck that was tapped.
    ///   - isVIPUnlocked: The current VIP entitlement status.
    func handleDeckTap(_ deck: Deck, isVIPUnlocked: Bool) {
        let isLocked = deck.isPro && !isVIPUnlocked
        
        if isLocked {
            showPurchaseSheet = true
        } else {
            // Selecting an already selected deck acts as a toggle in some UIs,
            // but here we just set it. If we want toggle behavior, we'd check ==.
            selectedDeck = deck
        }
    }
}
