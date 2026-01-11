import XCTest

final class DeckBrowserUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testHappyPath_SelectDeckAndStartGame() throws {
        // Given
        let app = XCUIApplication()
        app.launch()
        
        // When: User is on Deck Browser (Main Screen)
        // Verify Header exists
        let header = app.staticTexts["Choose Your Vibe"]
        XCTAssertTrue(header.waitForExistence(timeout: 5), "Deck Browser Header should be visible")
        
        // And: User selects the first deck
        // Updated to use Accessibility Identifier from Story 4.4
        // Assuming "Mix Shqip" has ID "1" or we just find the FIRST DeckRow available.
        // We look for elements starting with "DeckRow_"
        
        let deckRows = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'DeckRow_'"))
        let firstDeck = deckRows.firstMatch
        
        XCTAssertTrue(firstDeck.waitForExistence(timeout: 3), "At least one deck row should exist")
        firstDeck.tap()
        
        // And: User taps "START GAME"
        let startButton = app.buttons["START GAME"]
        XCTAssertTrue(startButton.exists, "Start button should be visible")
        // It might be disabled initially. After tap, it should be enabled.
        XCTAssertTrue(startButton.isEnabled, "Start button should be enabled after selection")
        
        startButton.tap()
        
        // Then: Navigate to Game Screen
        // GameScreen header is likely there, or "Verification Mode" text if that was the target.
        // In Story 2.2, GameScreen is presented.
        // GameScreen (from prev stories) might have a back button "xmark.circle.fill" or similar.
        
        let gameView = app.otherElements["GameScreen"] // If ID exists
        // Or look for game elements. Story 2.1 had "GameModelsTests".
        // Let's assume we check for absence of Browser Header.
        
        XCTAssertFalse(header.exists, "Should have navigated away from Deck Browser")
    }
}
