import XCTest
@testable import Kape

@MainActor
final class DeckBrowserViewModelTests: XCTestCase {
    
    var viewModel: DeckBrowserViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = DeckBrowserViewModel()
    }
    
    func testHandleDeckTap_WhenDeckIsFree_SelectsDeck() {
        // Given
        let freeDeck = DeckFactory.make(id: "free", isPro: false)
        let isVIPUnlocked = false // User is not VIP
        
        // When
        viewModel.handleDeckTap(freeDeck, isVIPUnlocked: isVIPUnlocked)
        
        // Then
        XCTAssertEqual(viewModel.selectedDeck?.id, freeDeck.id)
        XCTAssertFalse(viewModel.showPurchaseSheet)
    }
    
    func testHandleDeckTap_WhenDeckIsProAndLocked_ShowsPurchaseSheet() {
        // Given
        let proDeck = DeckFactory.make(id: "pro", isPro: true)
        let isVIPUnlocked = false // Locked
        
        // When
        viewModel.handleDeckTap(proDeck, isVIPUnlocked: isVIPUnlocked)
        
        // Then
        XCTAssertNil(viewModel.selectedDeck)
        XCTAssertTrue(viewModel.showPurchaseSheet)
    }
    
    func testHandleDeckTap_WhenDeckIsProAndUnlocked_SelectsDeck() {
        // Given
        let proDeck = DeckFactory.make(id: "pro_unlocked", isPro: true)
        let isVIPUnlocked = true // Entitled
        
        // When
        viewModel.handleDeckTap(proDeck, isVIPUnlocked: isVIPUnlocked)
        
        // Then
        XCTAssertEqual(viewModel.selectedDeck?.id, proDeck.id)
        XCTAssertFalse(viewModel.showPurchaseSheet)
    }
}
