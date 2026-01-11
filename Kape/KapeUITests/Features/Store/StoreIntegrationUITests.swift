import XCTest

/// Monetization Integration Tests
/// Goal: Verify the purchase flow and content unlocking
final class StoreIntegrationUITests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
    }
    
    func testPurchaseFlow_UnlockAndPlay() {
        let app = XCUIApplication()
        
        // 1. Find a Locked Deck (VIP)
        // Story 4.4 introducted "VIP Decks" header.
        // We look for a cell with a lock icon or known VIP ID.
        // Assuming "VIP Deck" (ID: com.kape.vip) is present from MockStoreService
        
        app.staticTexts["VIP Decks"].waitForExistence(timeout: 5)
        
        // Find the VIP deck row. Assuming it has identifier "DeckRow_com.kape.vip"
        // If not found by ID, we fall back to finding the text "VIP Deck"
        var vipDeck = app.otherElements["DeckRow_com.kape.vip"]
        if !vipDeck.exists {
            vipDeck = app.staticTexts["VIP Deck"]
        }
        
        // Scroll if needed (basic swipe)
        if !vipDeck.exists {
            app.swipeUp()
        }
        
        XCTAssertTrue(vipDeck.waitForExistence(timeout: 3), "VIP Deck should be visible")
        vipDeck.tap()
        
        // 2. Verify Purchase Sheet
        let sheetTitle = app.staticTexts["Unlock VIP Content"]
        XCTAssertTrue(sheetTitle.waitForExistence(timeout: 3), "Purchase sheet should appear")
        
        // 3. Simulate Purchase
        let purchaseButton = app.buttons["PurchaseButton"]
        XCTAssertTrue(purchaseButton.exists)
        purchaseButton.tap()
        
        // 4. Verify Unlock
        // Sheet should dismiss
        XCTAssertTrue(sheetTitle.waitForNonExistence(timeout: 5), "Sheet should dismiss after purchase")
        
        // Deck should now be unlocked. Tapping it again should SELECT it (show Start Button) or Start Game?
        // Logic: Tapping an unlocked deck selects it. Tapping Start Button starts game.
        vipDeck.tap()
        
        let startButton = app.buttons["StartGameButton"]
        XCTAssertTrue(startButton.exists && startButton.isEnabled, "Start button should be active for unlocked deck")
        
        // 5. Start Game with Premium Content
        startButton.tap()
        
        // Verify Game Starts
        XCTAssertTrue(app.staticTexts["GameScore"].waitForExistence(timeout: 5), "Game should start with VIP deck")
    }
}
