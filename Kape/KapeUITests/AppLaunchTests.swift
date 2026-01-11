import XCTest

final class AppLaunchTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunchSmoke() throws {
        // Setup
        let app = XCUIApplication()
        app.launch()

        // Verify Title Exists
        // Note: The app displays "KAPE!" in large text.
        // In SwiftUI, this is a standard Text element.
        let title = app.staticTexts["KAPE!"]
        
        // Wait for it to appear (standard UI test practice)
        let exists = title.waitForExistence(timeout: 5)
        
        XCTAssertTrue(exists, "Main Entry Title 'KAPE!' should be visible on launch")
        
        // Verify Verification Mode text
        let subtitle = app.staticTexts["Verification Mode"]
        XCTAssertTrue(subtitle.exists, "Subtitle 'Verification Mode' should be visible")
    }
}
