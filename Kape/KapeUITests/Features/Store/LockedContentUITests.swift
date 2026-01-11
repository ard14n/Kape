import XCTest

class LockedContentUITests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
    }
    
    func testLockedDeckInteraction_TriggersPurchaseSheet() {
        let app = XCUIApplication()
        
        // 1. Verify we are on Deck Browser
        XCTAssertTrue(app.staticTexts["Choose Your Vibe"].exists, "Should be on Deck Browser screen")
        
        // 2. Find VIP Decks section
        let vipHeader = app.staticTexts["VIP Decks"]
        
        // Scroll until VIP Decks are visible (if offscreen)
        // Note: Simple scroll action; robust implementation requires checking visibility loop
        if !vipHeader.exists {
            app.swipeUp() 
        }
        
        // Wait for header
        let exists = vipHeader.waitForExistence(timeout: 5)
        XCTAssertTrue(exists, "VIP Decks section should be visible")
        
        // 3. Find a locked deck (assuming at least one VIP deck exists)
        // We look for cells under the VIP header.
        // Since we can't easily query "isLocked" via standard attributes without custom accessiblity values,
        // we'll tap the first cell following the VIP header.
        // Better: We assigned identifiers "DeckRow_{id}".
        // We will tap the FIRST element that is a DeckRow which is likely in the VIP section.
        // To be safe, we swipe up to ensure we are at the bottom.
        app.swipeUp()
        
        // Tap a deck. In a real scenario we'd target a specific ID from the JSON.
        // Here we rely on the fact that tapping a LOCKED deck shows the sheet.
        // We look for elements via a generalized query if ID is unknown, or hit a known one.
        // Let's assume there is at least one VIP deck.
        
        // Strategy: Use the Screen Coordinate or Hierarchy if we don't know the ID.
        // But we DO assign "DeckRow_\(deck.id)".
        // Let's try to tap the *last* deck row available, as free decks are usually top.
        let deckRows = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'DeckRow_'"))
        let lastDeck = deckRows.element(boundBy: deckRows.count - 1)
        
        XCTAssertTrue(lastDeck.exists)
        lastDeck.tap()
        
        // 4. Verify Purchase Sheet appears
        let purchaseSheetTitle = app.staticTexts["Unlock VIP Content"]
        XCTAssertTrue(purchaseSheetTitle.waitForExistence(timeout: 3), "Purchase sheet should appear after tapping locked deck")
        
        // 5. Verify Sheet Elements
        XCTAssertTrue(app.buttons["PurchaseButton"].exists)
        XCTAssertTrue(app.buttons["DismissButton"].exists)
        
        // 6. Dismiss
        app.buttons["DismissButton"].tap()
        
        // 7. Verify Sheet Dismissed
        XCTAssertFalse(purchaseSheetTitle.exists, "Purchase sheet should be dismissed")
    }
    
    func testPurchaseFlow_Success() {
        let app = XCUIApplication()
        
        // 1. Navigate to locked content
        app.swipeUp()
        let deckRows = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'DeckRow_'"))
        let lockedDeck = deckRows.element(boundBy: deckRows.count - 1)
        
        XCTAssertTrue(lockedDeck.exists)
        lockedDeck.tap()
        
        // 2. Verified Sheet Appears
        let purchaseSheetTitle = app.staticTexts["Unlock VIP Content"]
        XCTAssertTrue(purchaseSheetTitle.waitForExistence(timeout: 3))
        
        // 3. Purchase
        let purchaseButton = app.buttons["PurchaseButton"]
        XCTAssertTrue(purchaseButton.exists)
        purchaseButton.tap()
        
        // 4. Verify Dismissal (Success should auto-dismiss)
        let sheetDismissed = purchaseSheetTitle.waitForNonExistence(timeout: 5)
        XCTAssertTrue(sheetDismissed, "Sheet should dismiss on successful purchase")
        
        // 5. Verify Unlocked State
        // Tapping the same deck should now NOT show the sheet (or start game)
        lockedDeck.tap()
        // If it starts game, "Start Game" button/Header might not be visible, or we see GameScreen elements.
        // Assuming GameScreen launch or just NO sheet.
        XCTAssertFalse(purchaseSheetTitle.exists, "Tapping unlocked deck should not show purchase sheet")
    }
    
    func testPurchaseFlow_Cancel() {
        let app = XCUIApplication()
        
        // 1. Navigate to locked content
        app.swipeUp()
        let deckRows = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'DeckRow_'"))
        let lockedDeck = deckRows.element(boundBy: deckRows.count - 1)
        
        XCTAssertTrue(lockedDeck.exists)
        lockedDeck.tap()
        
        // 2. Verify Sheet
        let purchaseSheetTitle = app.staticTexts["Unlock VIP Content"]
        XCTAssertTrue(purchaseSheetTitle.waitForExistence(timeout: 3))
        
        // 3. Cancel
        app.buttons["DismissButton"].tap()
        
        // 4. Verify Dismissal
        XCTAssertTrue(purchaseSheetTitle.waitForNonExistence(timeout: 3))
        
        // 5. Verify Still Locked
        lockedDeck.tap()
        XCTAssertTrue(purchaseSheetTitle.waitForExistence(timeout: 3), "Deck should remain locked after cancel")
    }
    
    // MARK: - Story 4.4: Restore Purchases Tests
    
    func testRestorePurchases_FromSettings() {
        let app = XCUIApplication()
        
        // 1. Verify we are on Deck Browser
        XCTAssertTrue(app.staticTexts["Choose Your Vibe"].exists, "Should be on Deck Browser screen")
        
        // 2. Tap Settings button
        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 3), "Settings button should exist")
        settingsButton.tap()
        
        // 3. Verify Settings sheet appears
        let settingsTitle = app.navigationBars["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3), "Settings sheet should appear")
        
        // 4. Tap Restore Purchases button
        let restoreButton = app.buttons["restorePurchasesButton"]
        XCTAssertTrue(restoreButton.exists, "Restore Purchases button should exist")
        restoreButton.tap()
        
        // 5. Verify success alert appears (MockStoreService defaults to success)
        // CR4.4-L2 FIX: Assert on alert message text for robustness
        let successAlert = app.alerts.firstMatch
        XCTAssertTrue(successAlert.waitForExistence(timeout: 5), "Success alert should appear")
        XCTAssertTrue(successAlert.staticTexts["Purchases restored successfully!"].exists, "Alert should show success message")
        
        // 6. Dismiss alert
        successAlert.buttons["OK"].tap()
        
        // 7. Close settings
        let doneButton = app.buttons["settingsDoneButton"]
        if doneButton.exists {
            doneButton.tap()
        }
    }
}
