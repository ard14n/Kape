import XCTest
@testable import Kape

/// UI Tests for Story 5.3: Albanian Localization Verification
/// Verifies Albanian text appears correctly in the rendered UI
final class LocalizationUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    // MARK: - Deck Browser Screen
    
    func testDeckBrowser_HeaderIsAlbanian() {
        // GIVEN: App is launched to Deck Browser
        // THEN: Header should display "Zgjidh Viben"
        let header = app.staticTexts["DeckBrowserHeader"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))
        XCTAssertEqual(header.label, "Zgjidh Kategorinë")
    }
    
    func testDeckBrowser_StartButtonIsAlbanian() {
        // GIVEN: A deck is selected
        let firstDeck = app.buttons.matching(identifier: "DeckRow_mix-shqip").firstMatch
        if firstDeck.waitForExistence(timeout: 5) {
            firstDeck.tap()
        }
        
        // THEN: Start button should display "FILLO LOJËN"
        let startButton = app.buttons["StartGameButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        XCTAssertTrue(startButton.label.contains("FILLO LOJËN"))
    }
    
    func testDeckBrowser_VIPHeaderIsAlbanian() {
        // GIVEN: App is on Deck Browser
        // THEN: VIP section should display "Decks VIP"
        let vipHeader = app.staticTexts["VIPDecksHeader"]
        if vipHeader.waitForExistence(timeout: 3) {
            XCTAssertEqual(vipHeader.label, "Decks VIP")
        }
        // Note: VIP header may not exist if no pro decks
    }
    
    // MARK: - Settings Screen
    
    func testSettings_TitleIsAlbanian() {
        // GIVEN: Navigate to Settings
        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()
        
        // THEN: Navigation title should be "Cilësimet"
        let navTitle = app.navigationBars["Cilësimet"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 3))
    }
    
    func testSettings_SectionsAreAlbanian() {
        // GIVEN: Navigate to Settings
        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()
        
        // THEN: Sections should be in Albanian
        XCTAssertTrue(app.staticTexts["Blerjet"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Rreth"].waitForExistence(timeout: 3))
    }
    
    func testSettings_RestoreButtonIsAlbanian() {
        // GIVEN: Navigate to Settings
        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()
        
        // THEN: Restore button should be "Rikthe Blerjet"
        let restoreButton = app.buttons["restorePurchasesButton"]
        XCTAssertTrue(restoreButton.waitForExistence(timeout: 3))
        XCTAssertTrue(restoreButton.label.contains("Rikthe Blerjet"))
    }
    
    func testSettings_DoneButtonIsAlbanian() {
        // GIVEN: Navigate to Settings
        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()
        
        // THEN: Done button should be "Mbyll"
        let doneButton = app.buttons["settingsDoneButton"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 3))
        XCTAssertEqual(doneButton.label, "Mbyll")
    }
}
