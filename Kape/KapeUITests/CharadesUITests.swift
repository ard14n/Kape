import XCTest

/// Public UI only. Store service and shortened timer are DEBUG fixtures; no real purchase.
final class CharadesUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    private func launch(intro: Bool = false, duration: String = "60") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--kape-ui-tests"]
        if intro { app.launchArguments.append("--kape-show-intro") }
        app.launchEnvironment["KAPE_TEST_GAME_DURATION"] = duration
        app.launch()
        XCTAssertTrue(app.buttons[intro ? "DismissHelp" : "StartTogether"].waitForExistence(timeout: 10))
        return app
    }
    private func tap(_ app: XCUIApplication, _ id: String, file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[id]
        XCTAssertTrue(button.waitForExistence(timeout: 5), id, file: file, line: line)
        for _ in 0..<10 {
            if button.isHittable && button.frame.maxY <= app.frame.maxY { break }
            scroll(app)
        }
        XCTAssertTrue(button.isHittable, id, file: file, line: line)
        button.tap()
    }
    private func scroll(_ app: XCUIApplication) {
        let scroll = app.scrollViews.allElementsBoundByIndex.first { $0.isHittable }
        scroll?.swipeUp()
    }
    private func capture(_ name: String, _ app: XCUIApplication) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name; shot.lifetime = .keepAlways; add(shot)
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = name + "-accessibility"; tree.lifetime = .keepAlways; add(tree)
    }
    private func start(_ app: XCUIApplication) {
        tap(app, "StartTogether")
        XCTAssertTrue(app.buttons["RevealWord"].waitForExistence(timeout: 5))
    }
    private func revealAndAct(_ app: XCUIApplication) -> String {
        tap(app, "RevealWord")
        let word = app.staticTexts["SecretWord"]
        XCTAssertTrue(word.waitForExistence(timeout: 5))
        let value = word.label
        tap(app, "HideWord")
        XCTAssertFalse(app.staticTexts["SecretWord"].exists)
        XCTAssertFalse(app.staticTexts[value].exists)
        XCTAssertTrue(app.buttons["Guessed"].waitForExistence(timeout: 5))
        return value
    }

    func testPrivateLoopCorrectionAndNextPerson() {
        let app = launch()
        capture("01-home", app)
        start(app)
        capture("02-handoff", app)
        tap(app, "RevealWord")
        XCTAssertTrue(app.staticTexts["SecretWord"].waitForExistence(timeout: 5))
        capture("03-private-word", app)
        let first = app.staticTexts["SecretWord"].label
        tap(app, "AnotherWord")
        XCTAssertNotEqual(app.staticTexts["SecretWord"].label, first)
        tap(app, "HideWord")
        XCTAssertFalse(app.staticTexts["SecretWord"].exists)
        XCTAssertTrue(app.buttons["Guessed"].waitForExistence(timeout: 5))
        capture("04-acting", app)
        let timer = app.staticTexts["CharadesTimer"]
        XCTAssertTrue(timer.isHittable)
        XCTAssertLessThanOrEqual(timer.frame.maxY, app.buttons["Guessed"].frame.minY, "The timer must be fully visible above the actions, including at maximum type size.")
        tap(app, "Guessed")
        capture("05-result", app)
        tap(app, "CorrectResult")
        XCTAssertEqual(app.buttons["CorrectResult"].value as? String, "Nuk u gjet")
        tap(app, "NextTurn")
        XCTAssertTrue(app.buttons["RevealWord"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["SecretWord"].exists)
        tap(app, "FinishTogether")
        capture("06-group-finish", app)
        tap(app, "ReturnHome")
        XCTAssertTrue(app.buttons["StartTogether"].waitForExistence(timeout: 5))
    }

    func testIntroductionIsScrollableAndHelpCanBeReopened() {
        let app = launch(intro: true)
        capture("07-introduction", app)
        tap(app, "CloseInstructions")
        tap(app, "HelpButton")
        XCTAssertTrue(app.buttons["DismissHelp"].waitForExistence(timeout: 5))
        capture("08-help", app)
        tap(app, "CloseInstructions")
        XCTAssertTrue(app.buttons["StartTogether"].waitForExistence(timeout: 5))
    }

    func testPauseBackgroundAndRelaunchKeepWordPrivate() {
        let app = launch()
        start(app); tap(app, "RevealWord")
        let word = app.staticTexts["SecretWord"].label
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.buttons["ResumeGame"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["SecretWord"].exists)
        XCTAssertFalse(app.staticTexts[word].exists)
        capture("09-paused-private", app)
        tap(app, "ExitGame"); tap(app, "Ruaje dhe dil")
        XCTAssertTrue(app.buttons["ResumeSavedGame"].waitForExistence(timeout: 5))
        app.terminate()
        app.launchArguments = ["--kape-ui-tests", "--kape-keep-state"]
        app.launch()
        tap(app, "ResumeSavedGame")
        XCTAssertFalse(app.staticTexts["SecretWord"].exists)
        tap(app, "ResumeGame")
        XCTAssertEqual(app.staticTexts["SecretWord"].label, word)
        tap(app, "HideWord")
        XCTAssertTrue(app.buttons["PauseGame"].waitForExistence(timeout: 5))
        tap(app, "PauseGame")
        capture("10-paused-timer", app)
        let frozen = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'sekonda të mbetura'")).firstMatch.label
        tap(app, "ResumeGame")
        XCTAssertTrue(app.buttons["Guessed"].waitForExistence(timeout: 5))
        tap(app, "PauseGame")
        XCTAssertFalse(frozen.isEmpty)
        XCTAssertFalse(app.staticTexts["SecretWord"].exists)
    }

    func testTimeLimitRequiresJudgment() {
        let app = launch(duration: "2")
        start(app); _ = revealAndAct(app)
        XCTAssertTrue(app.staticTexts["KOHA MBAROI"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.staticTexts["SecretWord"].exists)
        capture("11-time-up", app)
        tap(app, "NotGuessed")
        tap(app, "FinishTogether")
        XCTAssertTrue(app.staticTexts["0 fjalë\ntë gjetura."].exists)
    }

    func testTournamentCompletesEqualTurnsAndSharesTie() {
        let app = launch()
        tap(app, "StartTournament")
        let picker = app.segmentedControls["RoundsPicker"]
        for _ in 0..<8 { if picker.isHittable { break }; scroll(app) }
        XCTAssertTrue(picker.buttons["1"].exists)
        picker.buttons["1"].tap()
        capture("12-tournament-setup", app)
        tap(app, "ConfirmTournament")
        capture("13-tournament-handoff", app)
        for index in 0..<2 {
            _ = revealAndAct(app)
            tap(app, "Guessed")
            if index == 0 { capture("14-tournament-score", app) }
            tap(app, "NextTurn")
        }
        XCTAssertTrue(app.buttons["ReturnHome"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Pikë të barabarta!"].exists)
        capture("15-tournament-finish", app)
        let standings = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'Standing-'"))
        // Accessibility may expose combined rows as static text or otherElements.
        for index in 0..<2 {
            let row = app.descendants(matching: .any)["Standing-\(index)"].firstMatch
            XCTAssertTrue(row.exists)
            XCTAssertTrue(row.label.contains("1 pikë"))
            XCTAssertTrue(row.label.contains("1 nga 1 radhë"))
            XCTAssertTrue(row.label.contains("vendi 1"))
        }
        _ = standings
        tap(app, "ReturnHome")
    }

    func testSettingsAppearanceAndLockedCategoryOffer() {
        let app = launch()
        tap(app, "SettingsButton")
        capture("16-settings", app)
        tap(app, "AppearancePicker")
        tap(app, "E errët")
        capture("17-settings-dark", app)
        tap(app, "CloseSettings")
        capture("18-home-dark", app)
        tap(app, "ChooseCategory")
        capture("19-categories-dark", app)
        // First existing paid category is the music set.
        let locked = app.buttons.matching(NSPredicate(format: "label CONTAINS 'e kyçur'")).firstMatch
        for _ in 0..<12 { if locked.exists && locked.isHittable { break }; scroll(app) }
        XCTAssertTrue(locked.exists && locked.isHittable)
        locked.tap()
        XCTAssertTrue(app.buttons["ClosePurchase"].waitForExistence(timeout: 5))
        capture("20-vip-offer-dark", app)
        tap(app, "RestoreInOffer")
        tap(app, "ClosePurchase")
    }

    func testVIPMockPurchaseUnlocksCategoryForTournament() {
        let app = launch()
        tap(app, "ChooseCategory")
        tap(app, "Category-muzike")
        tap(app, "PurchaseVIP")
        XCTAssertTrue(app.staticTexts["VIP është i hapur"].waitForExistence(timeout: 5))
        tap(app, "ClosePurchase")
        tap(app, "Category-muzike")
        tap(app, "StartTournament")
        tap(app, "ConfirmTournament")
        tap(app, "RevealWord")
        XCTAssertTrue(app.staticTexts["SecretWord"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["AccessDenied"].exists)
    }

    func testTournamentSupportsFivePeopleAndRemoval() {
        let app = launch()
        tap(app, "StartTournament")
        for _ in 0..<3 { tap(app, "AddPlayer") }
        XCTAssertTrue(app.textFields["PlayerName-4"].exists)
        XCTAssertFalse(app.buttons["AddPlayer"].exists)
        tap(app, "Hiq lojtarin 5")
        XCTAssertFalse(app.textFields["PlayerName-4"].exists)
        tap(app, "AddPlayer")
        tap(app, "ConfirmTournament")
        XCTAssertTrue(app.buttons["RevealWord"].waitForExistence(timeout: 5))
        capture("21-five-person-handoff", app)
    }
}
