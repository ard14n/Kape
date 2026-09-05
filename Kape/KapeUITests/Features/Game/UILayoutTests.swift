import XCTest

final class UILayoutTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--kape-ui-tests"]
        app.launch()
    }

    // MARK: - AC-03: Layout & Spacing
    
    func testDeckBrowser_HeaderDoesNotOverlapFirstItem() {
        let app = XCUIApplication()
        
        let header = app.staticTexts["DeckBrowserHeader"]
        XCTAssertTrue(header.waitForExistence(timeout: 5), "Header should exist")
        
        // Wait for first deck row text (more stable than otherElements)
        let firstRowText = app.staticTexts["Mix Shqip"]
        if !firstRowText.waitForExistence(timeout: 5) {
            XCTFail("First deck row text 'Mix Shqip' not found. Available elements: \(app.staticTexts.allElementsBoundByIndex.map { $0.label })")
            return
        }
        
        // Check structural overlap: Header bottom should be less than or equal to firstRow top
        XCTAssertLessThanOrEqual(header.frame.maxY, firstRowText.frame.minY, "Header (maxY: \(header.frame.maxY)) should be above the first deck item (minY: \(firstRowText.frame.minY)) to prevent clipping")
    }
    
    // MARK: - AC-04: VIP Decks Visibility
    
    func testDeckBrowser_VIPHeaderIsVisible() {
        let app = XCUIApplication()
        
        // This test assumed there are VIP decks. In a production test, 
        // we might need to mock DeckService or ensure a test deck exists.
        // For now, we check the identifier we just added.
        let vipHeader = app.staticTexts["VIPDecksHeader"]
        
        // Note: If no VIP decks, this will exist but not be visible/exist in hierarchy if logic holds.
        // Assuming current mock data has VIP decks.
        // Very large type makes each full description taller; the list must remain scrollable.
        for _ in 0..<12 {
            if vipHeader.exists && vipHeader.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(vipHeader.exists && vipHeader.isHittable, "VIP section must be reachable by scrolling")
    }
    
    // MARK: - AC-02: Start Button Refinement
    
    func testDeckBrowser_StartButtonIsPresent() {
        let app = XCUIApplication()
        
        let startButton = app.buttons["StartGameButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5), "Start button should be present")
        
        XCTAssertLessThanOrEqual(app.scrollViews.firstMatch.frame.maxY, startButton.frame.minY, "Start control must not cover category rows")

        // Initially it might be disabled if no deck is selected
        // We can select a deck and check if it becomes hittable
        let firstRow = app.staticTexts["Mix Shqip"]
        if firstRow.exists {
            firstRow.tap()
            XCTAssertTrue(startButton.isHittable, "Start button should be hittable after deck selection")
        }
    }
}
