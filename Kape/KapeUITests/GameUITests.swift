import XCTest

final class GameUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testGameFlow() throws {
        // 1. Launch App
        let app = XCUIApplication()
        app.launch()

        // 2. Start Test Game via Verification Mode
        // CR-FIX: Updated ID from StartTestGameButton to StartGameButton matches implementation
        let startButton = app.buttons["StartGameButton"]
        XCTAssertTrue(startButton.exists, "Start Game button should exist")
        startButton.tap()

        // 3. Wait for game to transition to playing state
        // The card has accessibilityIdentifier "CurrentCard"
        // Note: Deck is shuffled, so we can't assume which card shows first
        
        let currentCard = app.staticTexts["CurrentCard"]
        let cardExists = currentCard.waitForExistence(timeout: 20.0)
        
        if !cardExists {
            // Debug: print hierarchy on failure
            print("DEBUG: Element hierarchy dump:")
            print(app.debugDescription)
        }
        
        XCTAssertTrue(cardExists, "Card should appear after game starts")
        
        // Verify the card has content (label should contain "Card word:")
        XCTAssertTrue(currentCard.label.contains("Card word:"), "Card should display text")
        
        // Verify Timer
        let timer = app.staticTexts["GameTimer"]
        XCTAssertTrue(timer.exists, "Timer should be visible")
        
        // Verify Score
        let score = app.staticTexts.matching(identifier: "GameScore").firstMatch
        XCTAssertTrue(score.exists, "Score should be visible")
    }
}
