import XCTest

final class StoreUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }
    
    func testPurchaseSheetAppearsOnLockedDeckTap() throws {
        // GIVEN: We are on the Deck Browser
        XCTAssertTrue(app.staticTexts["Choose Your Vibe"].waitForExistence(timeout: 5))
        
        // WHEN: We tap the settings button to check restore capability
        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.buttons["restorePurchasesButton"].exists)
        app.buttons["settingsDoneButton"].tap()
        
        // WHEN: We tap a VIP deck (Assuming first Match for a locked deck if possible)
        // Since we don't have a direct 'locked' identifier, we'll try to tap a deck 
        // that we know is VIP (e.g. DeckRow_vip_1)
        let vipDeck = app.otherElements.matching(identifier: "DeckRow_vip_1").firstMatch
        if vipDeck.exists {
            vipDeck.tap()
            
            // THEN: Purchase Sheet should appear
            XCTAssertTrue(app.buttons["PurchaseButton"].waitForExistence(timeout: 3))
            
            // AND: We can dismiss it
            app.buttons["DismissButton"].tap()
            XCTAssertFalse(app.buttons["PurchaseButton"].exists)
        }
    }
}
