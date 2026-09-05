import XCTest

/// UI sensor inputs are synthetic; these checks do not replace the physical-device checklist.
final class SmokeTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch(unavailableMotion: Bool = false, duration: String = "45") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--kape-ui-tests"]
        if unavailableMotion { app.launchArguments.append("--kape-ui-motion-unavailable") }
        app.launchEnvironment["KAPE_TEST_GAME_DURATION"] = duration
        app.launch()
        XCTAssertTrue(app.staticTexts["DeckBrowserHeader"].waitForExistence(timeout: 8))
        return app
    }

    private func start(_ app: XCUIApplication) {
        app.staticTexts["Mix Shqip"].tap()
        let start = app.buttons["StartGameButton"]
        XCTAssertTrue(start.isHittable)
        start.tap()
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testStandardGameLoop() {
        let app = launch()
        capture("01-kategorien")
        start(app)
        XCTAssertTrue(app.buttons["PauseButton"].waitForExistence(timeout: 8))
        capture("02-spiel")
        app.buttons["PauseButton"].tap()
        XCTAssertTrue(app.buttons["ResumeGameButton"].waitForExistence(timeout: 3))
        capture("03-pause")
        app.buttons["ResumeGameButton"].tap()
        XCTAssertTrue(app.buttons["PauseButton"].waitForExistence(timeout: 8))
        app.buttons["PauseButton"].tap()
        app.buttons["EndGameButton"].tap()
        XCTAssertTrue(app.buttons["HomeButton"].waitForExistence(timeout: 8))
        capture("04-ergebnis")
        app.buttons["HomeButton"].tap()
        XCTAssertTrue(app.staticTexts["DeckBrowserHeader"].waitForExistence(timeout: 5))
    }

    func testUnavailableSensorCanReturnToCategories() {
        let app = launch(unavailableMotion: true)
        start(app)
        let back = app.buttons["ExitCalibrationButton"]
        XCTAssertTrue(back.waitForExistence(timeout: 8))
        XCTAssertTrue(back.isHittable)
        let title = app.staticTexts["CalibrationTitle"]
        XCTAssertTrue(title.exists)
        XCTAssertLessThanOrEqual(back.frame.maxY, title.frame.minY, "Back control must not cover the calibration title")
        capture("05-kalibrierung-ohne-sensor")
        back.tap()
        XCTAssertTrue(app.staticTexts["DeckBrowserHeader"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["HomeButton"].exists)
    }

    func testCalibrationInstructionsCanBeScrolled() {
        let app = launch(unavailableMotion: true)
        start(app)
        XCTAssertTrue(app.buttons["ExitCalibrationButton"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["CalibrationTitle"].waitForExistence(timeout: 8))
        let hint = app.staticTexts["Mbaje ekranin nga miqtë dhe prit një çast."]
        let scroll = app.scrollViews.allElementsBoundByIndex.first { $0.isHittable }
        XCTAssertNotNil(scroll, app.debugDescription)
        scroll?.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.85))
            .press(forDuration: 0.05, thenDragTo: scroll!.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.25)))
        capture("06-kalibrierung-gescrollt")
        XCTAssertTrue(hint.isHittable, app.debugDescription)
        XCTAssertLessThanOrEqual(hint.frame.maxY, app.frame.maxY, "The final instruction must be fully reachable")
    }

    func testTimerFinishesAndSecondRoundStarts() {
        let app = launch(duration: "5")
        start(app)
        XCTAssertTrue(app.buttons["HomeButton"].waitForExistence(timeout: 15))
        app.buttons["PlayAgainButton"].tap()
        XCTAssertTrue(app.buttons["PauseButton"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["HomeButton"].waitForExistence(timeout: 15))
    }
}
