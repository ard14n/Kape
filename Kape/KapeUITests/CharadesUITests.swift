import XCTest

/// Public UI only. State reset and shortened timers are DEBUG fixtures; gameplay has no store dependency.
final class CharadesUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    private func launch(intro: Bool = false, duration: String = "60") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--kape-ui-tests"]
        if intro { app.launchArguments.append("--kape-show-intro") }
        app.launchEnvironment["KAPE_TEST_GAME_DURATION"] = duration
        app.launch()
        // Release builds ignore DEBUG reset arguments; reopen the real help on subsequent launches.
        if intro && !app.buttons["DismissHelp"].waitForExistence(timeout: 5),
           app.buttons["StartTogether"].waitForExistence(timeout: 5) {
            tap(app, "HelpButton")
        }
        XCTAssertTrue(app.buttons[intro ? "DismissHelp" : "StartTogether"].waitForExistence(timeout: 10))
        return app
    }
    private func tap(_ app: XCUIApplication, _ id: String, file: StaticString = #filePath, line: UInt = #line) {
        var button = app.buttons[id]
        if !button.waitForExistence(timeout: 2) {
            for _ in 0..<5 {
                scroll(app)
                button = app.buttons[id]
                if button.exists { break }
            }
        }
        XCTAssertTrue(button.waitForExistence(timeout: 5), id, file: file, line: line)
        for _ in 0..<10 {
            let footer: String? = ["ChooseCategory", "ChoosePlayStyle"].contains(id) ? "StartTogether"
                : id == "CorrectResult" ? "NextTurn" : nil
            let visibleBottom = min(footer.map { app.buttons[$0].frame.minY - 14 } ?? app.frame.maxY, app.frame.maxY)
            if button.isHittable && button.frame.maxY <= visibleBottom { break }
            scroll(app)
        }
        XCTAssertTrue(button.isHittable, id, file: file, line: line)
        if ["ChooseCategory", "ChoosePlayStyle", "CorrectResult"].contains(id) {
            let footer = id == "CorrectResult" ? "NextTurn" : "StartTogether"
            XCTAssertLessThanOrEqual(button.frame.maxY, min(app.buttons[footer].frame.minY - 14, app.frame.maxY), id + " must be visibly above the actions", file: file, line: line)
        }
        button.tap()
    }
    private func scroll(_ app: XCUIApplication) {
        let scroll = app.scrollViews.allElementsBoundByIndex.first { $0.isHittable }
        // Begin inside the reading area, above fixed bottom actions.
        if let scroll {
            let footerIDs = ["NextTurn", "HideWord", "RevealWord", "StartTogether", "ConfirmTournament", "CloseInstructions", "ResumeGame", "ReturnHome"]
            let bottoms = footerIDs.compactMap { id -> CGFloat? in
                let button = app.buttons[id]
                return button.exists && button.isHittable ? button.frame.minY - 16 : nil
            }
            var bottom = min(scroll.frame.maxY, bottoms.min() ?? app.frame.maxY)
            // In tournament results the fixed footer also contains the next player's name above its button.
            let nextPlayer = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Radha tjetër:")).firstMatch
            if nextPlayer.exists && nextPlayer.isHittable {
                bottom = min(bottom, nextPlayer.frame.minY - 16)
            }
            let top = max(scroll.frame.minY, app.navigationBars.allElementsBoundByIndex.filter(\.isHittable).map { $0.frame.maxY }.max() ?? app.frame.minY)
            guard bottom > top + 44 else { return }
            let start = CGPoint(x: app.frame.midX, y: top + (bottom - top) * 0.78)
            let end = CGPoint(x: start.x, y: top + (bottom - top) * 0.18)
            let origin = app.coordinate(withNormalizedOffset: .zero)
            origin.withOffset(CGVector(dx: start.x - app.frame.minX, dy: start.y - app.frame.minY))
                .press(forDuration: 0.05, thenDragTo: origin.withOffset(CGVector(dx: end.x - app.frame.minX, dy: end.y - app.frame.minY)))
        }
    }
    private func capture(_ name: String, _ app: XCUIApplication) {
        // A screenshot must show the settled sheet, not an intermediate animation frame.
        Thread.sleep(forTimeInterval: 0.8)
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

    func testPrivateLoopAndVisibleResultCorrection() {
        let app = launch()
        capture("01-home", app)
        // Owner decision: the app opens with Mix Shqip preselected.
        XCTAssertTrue(app.buttons["ChooseCategory"].label.contains("Mix Shqip"))
        XCTAssertEqual(app.buttons["ChoosePlayStyle"].value as? String, "Zgjedhje e lirë")
        start(app)
        XCTAssertEqual(app.staticTexts["SessionPlayStyle"].label, "Zgjedhje e lirë")
        capture("02-handoff", app)
        tap(app, "RevealWord")
        XCTAssertTrue(app.staticTexts["SecretWord"].waitForExistence(timeout: 5))
        capture("03-private-word", app)
        XCTAssertTrue(app.staticTexts["PlayStyleRule"].label.contains("gjeste pa folë ose shpjegim"))
        let first = app.staticTexts["SecretWord"].label
        tap(app, "AnotherWord")
        XCTAssertNotEqual(app.staticTexts["SecretWord"].label, first)
        tap(app, "HideWord")
        XCTAssertFalse(app.staticTexts["SecretWord"].exists)
        capture("03b-word-hidden", app)
        XCTAssertTrue(app.buttons["Guessed"].waitForExistence(timeout: 5))
        capture("04-acting", app)
        let timer = app.staticTexts["CharadesTimer"]
        // A noninteractive SwiftUI graphic can be visible without reporting a tappable hit point.
        // Verify the displayed numeral and the entire ring's geometry, plus both real touch targets.
        XCTAssertGreaterThan(timer.frame.height, 40)
        XCTAssertLessThanOrEqual(timer.frame.maxY, app.buttons["Guessed"].frame.minY, "The timer must be fully visible above the actions, including at maximum type size.")
        assertClockAndAnswersVisible(app)
        tap(app, "Guessed")
        capture("05-result", app)
        XCTAssertTrue(app.descendants(matching: .any)["ResultScore"].firstMatch.exists)
        tap(app, "CorrectResult")
        XCTAssertEqual(app.buttons["CorrectResult"].value as? String, "Nuk u gjet")
        capture("05b-result-corrected", app)
        tap(app, "NextTurn")
        XCTAssertTrue(app.buttons["RevealWord"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["SecretWord"].exists)
        tap(app, "FinishTogether")
        capture("06-group-finish", app)
        XCTAssertTrue(app.buttons["PlayAgain"].exists)
        tap(app, "ReturnHome")
        XCTAssertTrue(app.buttons["StartTogether"].waitForExistence(timeout: 5))
    }

    private func assertClockAndAnswersVisible(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let ring = app.descendants(matching: .any)["ClockRing"].firstMatch
        let yes = app.buttons["Guessed"]
        let no = app.buttons["NotGuessed"]
        XCTAssertTrue(ring.exists, file: file, line: line)
        XCTAssertGreaterThanOrEqual(ring.frame.height, 120, "The timer must retain a useful size.", file: file, line: line)
        XCTAssertLessThanOrEqual(ring.frame.maxY, yes.frame.minY, "The entire ring must remain above the answers without scrolling.", file: file, line: line)
        XCTAssertTrue(yes.isHittable && no.isHittable, file: file, line: line)
        XCTAssertLessThanOrEqual(yes.frame.maxY, no.frame.minY, file: file, line: line)
        XCTAssertLessThanOrEqual(no.frame.maxY, app.frame.maxY, file: file, line: line)
        XCTAssertEqual(yes.frame.minX, no.frame.minX, accuracy: 1, file: file, line: line)
        XCTAssertEqual(yes.frame.height, no.frame.height, accuracy: 1, "The two answers must have equal touch areas.", file: file, line: line)
        let yesIcon = yes.images["checkmark.circle.fill"]
        let noIcon = no.images["xmark.circle.fill"]
        XCTAssertTrue(yesIcon.exists && noIcon.exists, file: file, line: line)
        XCTAssertEqual(yesIcon.frame.midX, noIcon.frame.midX, accuracy: 0.5, "The answer symbols must share a column.", file: file, line: line)
    }

    func testTournamentClockKeepsLongPlayerNameRoundAndAnswersVisible() {
        let app = launch()
        tap(app, "StartTournament")
        let field = app.textFields["PlayerName-0"]
        field.tap()
        // Extend the nine-character default to the 24-character boundary without a locale-dependent edit menu.
        field.typeText("Krasniqi Berish")
        let name = field.value as? String ?? ""
        XCTAssertEqual(name.count, 24)
        XCTAssertTrue(app.buttons["ConfirmTournament"].isEnabled)
        tap(app, "ConfirmTournament")
        _ = revealAndAct(app)
        XCTAssertEqual(app.staticTexts["ActivePerformer"].label, name)
        XCTAssertEqual(app.staticTexts["ActiveRound"].label, "Raundi 1/3")
        XCTAssertTrue(app.staticTexts["ActivePerformer"].isHittable)
        assertClockAndAnswersVisible(app)
        capture("frost-long-name-timer", app)
        tap(app, "NotGuessed")
        tap(app, "CorrectResult")
        XCTAssertEqual(app.buttons["CorrectResult"].value as? String, "U gjet")
        tap(app, "NextTurn")
        _ = revealAndAct(app)
        XCTAssertEqual(app.staticTexts["ActivePerformer"].label, "Lojtari 2")
        XCTAssertEqual(app.staticTexts["ActiveRound"].label, "Raundi 1/3")
        assertClockAndAnswersVisible(app)
    }

    func testIntroductionIsScrollableAndHelpCanBeReopened() {
        let app = launch(intro: true)
        capture("07-introduction", app)
        tap(app, "CloseInstructions")
        tap(app, "HelpButton")
        XCTAssertTrue(app.buttons["DismissHelp"].waitForExistence(timeout: 5))
        let rule = app.descendants(matching: .any)["HelpStyle-explaining"].firstMatch
        for _ in 0..<12 { if rule.isHittable { break }; scroll(app) }
        XCTAssertTrue(rule.isHittable)
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
        tap(app, "ExitGame")
        XCTAssertTrue(app.buttons["Ruaje dhe dil"].waitForExistence(timeout: 5))
        capture("09b-exit-dialog", app)
        tap(app, "Ruaje dhe dil")
        XCTAssertTrue(app.buttons["ResumeSavedGame"].waitForExistence(timeout: 5))
        capture("09d-saved-home", app)
        // A saved game must not block a fresh one.
        XCTAssertTrue(app.buttons["StartFreshGame"].exists)
        tap(app, "StartFreshGame")
        XCTAssertTrue(app.buttons["Fshije lojën e ruajtun"].waitForExistence(timeout: 5))
        capture("09c-new-game-dialog", app)
        if app.buttons["Rri këtu"].exists {
            app.buttons["Rri këtu"].tap()
        } else {
            // Without a cancel choice the dialog is dismissed by tapping next to it.
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.93)).tap()
        }
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
        // The pause keeps the ring on screen instead of a line of text.
        XCTAssertTrue(app.staticTexts["PausedTimer"].exists)
        let frozen = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'sekonda të mbetura'")).firstMatch.label
        tap(app, "ResumeGame")
        XCTAssertTrue(app.buttons["Guessed"].waitForExistence(timeout: 5))
        tap(app, "PauseGame")
        XCTAssertFalse(frozen.isEmpty)
        XCTAssertFalse(app.staticTexts["SecretWord"].exists)
    }

    // MARK: - Review playthrough: ten varied games with screenshots and a flow log.
    // Run on demand (-only-testing:…/testTenGamePlaythroughForReview); the regular suite skips it.

    private var playLog: [String] = []
    private var playStart = Date()
    private func note(_ text: String) {
        playLog.append(String(format: "%6.1f s  ", Date().timeIntervalSince(playStart)) + text)
    }
    private func choose(_ app: XCUIApplication, category: String, style: String, shots: String? = nil) {
        tap(app, "ChooseCategory")
        if let shots { capture(shots + "-categories", app) }
        tap(app, "Category-" + category)
        tap(app, "ChoosePlayStyle")
        if let shots { capture(shots + "-play-style", app) }
        tap(app, "PlayStyle-" + style)
    }
    /// One turn; `guessed == nil` lets the time run out.
    private func turn(_ app: XCUIApplication, game: Int, index: Int, guessed: Bool?, anotherWord: Bool = false) {
        tap(app, "RevealWord")
        let word = app.staticTexts["SecretWord"]
        XCTAssertTrue(word.waitForExistence(timeout: 5))
        note("Spiel \(game), Zug \(index): Wort »\(word.label)«")
        if index == 1 { capture("g\(game)-reading", app) }
        if anotherWord {
            tap(app, "AnotherWord")
            note("  anderes Wort gewählt: »\(app.staticTexts["SecretWord"].label)«")
        }
        tap(app, "HideWord")
        XCTAssertTrue(app.buttons["Guessed"].waitForExistence(timeout: 5))
        if index == 1 { capture("g\(game)-acting", app) }
        if let guessed {
            tap(app, guessed ? "Guessed" : "NotGuessed")
            note(guessed ? "  U gjet" : "  Nuk u gjet")
        } else {
            XCTAssertTrue(app.staticTexts["TimeUpTitle"].waitForExistence(timeout: 70))
            capture("g\(game)-time-up", app)
            tap(app, "NotGuessed")
            note("  Zeit abgelaufen, als Nuk u gjet gewertet")
        }
        if index == 1 { capture("g\(game)-result", app) }
    }
    private func finishTogether(_ app: XCUIApplication, game: Int) {
        tap(app, "FinishTogether")
        capture("g\(game)-finish", app)
        note("Spiel \(game) beendet")
        tap(app, "ReturnHome")
    }
    private func tournament(_ app: XCUIApplication, game: Int, extraPlayers: Int, rounds: String) {
        tap(app, "StartTournament")
        for _ in 0..<extraPlayers { tap(app, "AddPlayer") }
        let picker = app.segmentedControls["RoundsPicker"]
        for _ in 0..<12 { if picker.isHittable { break }; scroll(app) }
        picker.buttons[rounds].tap()
        capture("g\(game)-tournament-setup", app)
        tap(app, "ConfirmTournament")
        XCTAssertTrue(app.buttons["RevealWord"].waitForExistence(timeout: 5))
        capture("g\(game)-handoff", app)
    }

    func testTenGamePlaythroughForReview() {
        playStart = Date()

        // 1 · together, default deck (Mix Shqip), free choice: guessed, missed, guessed
        var app = launch()
        capture("g1-home", app)
        note("Spiel 1: Lujmë bashkë · Mix Shqip (Standard) · Zgjedhje e lirë")
        start(app); capture("g1-handoff", app)
        turn(app, game: 1, index: 1, guessed: true); tap(app, "NextTurn")
        turn(app, game: 1, index: 2, guessed: false); tap(app, "NextTurn")
        turn(app, game: 1, index: 3, guessed: true)
        finishTogether(app, game: 1)
        app.terminate()

        // 2 · Mix Shqip, pantomime: skip a word, then correct the result
        app = launch()
        choose(app, category: "mix-shqip", style: "pantomime", shots: "g2")
        note("Spiel 2: Mix Shqip · Pantomimë")
        start(app)
        turn(app, game: 2, index: 1, guessed: true, anotherWord: true)
        tap(app, "CorrectResult"); note("  Ergebnis korrigiert"); capture("g2-corrected", app)
        tap(app, "NextTurn")
        turn(app, game: 2, index: 2, guessed: true)
        finishTogether(app, game: 2)
        app.terminate()

        // 3 · Diaspora, explaining: time runs out
        app = launch(duration: "3")
        choose(app, category: "gurbet", style: "explaining")
        note("Spiel 3: Diaspora · Shpjegim · Zeit läuft ab")
        start(app)
        turn(app, game: 3, index: 1, guessed: nil)
        finishTogether(app, game: 3)
        app.terminate()

        // 4 · tournament, two people, one round, Muzikë: tie
        app = launch()
        choose(app, category: "muzike", style: "freeChoice")
        note("Spiel 4: Turnier · 2 Personen · 1 Runde · Muzikë")
        tournament(app, game: 4, extraPlayers: 0, rounds: "1")
        turn(app, game: 4, index: 1, guessed: true); tap(app, "NextTurn")
        turn(app, game: 4, index: 2, guessed: true); tap(app, "NextTurn")
        capture("g4-finish", app); note("Spiel 4 beendet"); tap(app, "ReturnHome")
        app.terminate()

        // 5 · tournament, three people, one round, Sport, pantomime: one winner
        app = launch()
        choose(app, category: "sport", style: "pantomime")
        note("Spiel 5: Turnier · 3 Personen · 1 Runde · Sport · Pantomimë")
        tournament(app, game: 5, extraPlayers: 1, rounds: "1")
        turn(app, game: 5, index: 1, guessed: true); tap(app, "NextTurn")
        turn(app, game: 5, index: 2, guessed: false); tap(app, "NextTurn")
        turn(app, game: 5, index: 3, guessed: true); tap(app, "NextTurn")
        capture("g5-finish", app); note("Spiel 5 beendet"); tap(app, "ReturnHome")
        app.terminate()

        // 6 · Dasma & Tradita: pause while acting, then resume
        app = launch()
        choose(app, category: "dasma-tradita", style: "freeChoice")
        note("Spiel 6: Dasma & Tradita · Pause während der Darstellung")
        start(app)
        tap(app, "RevealWord"); note("Spiel 6, Zug 1: Wort »\(app.staticTexts["SecretWord"].label)«")
        tap(app, "HideWord")
        XCTAssertTrue(app.buttons["PauseGame"].waitForExistence(timeout: 5))
        tap(app, "PauseGame"); capture("g6-paused", app); note("  pausiert")
        tap(app, "ResumeGame"); note("  fortgesetzt")
        tap(app, "Guessed"); note("  U gjet")
        finishTogether(app, game: 6)
        app.terminate()

        // 7 · Fëmijëria: leave the app while reading, word must stay hidden
        app = launch()
        choose(app, category: "femijeria", style: "freeChoice")
        note("Spiel 7: Fëmijëria · App während des Lesens verlassen")
        start(app)
        tap(app, "RevealWord")
        let hidden = app.staticTexts["SecretWord"].label
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertTrue(app.buttons["ResumeGame"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts[hidden].exists)
        capture("g7-back-from-background", app); note("  zurück in der App, Wort verborgen")
        tap(app, "ResumeGame")
        tap(app, "HideWord")
        XCTAssertTrue(app.buttons["Guessed"].waitForExistence(timeout: 5))
        tap(app, "Guessed"); note("  U gjet")
        finishTogether(app, game: 7)
        app.terminate()

        // 8 · tournament, two people, three rounds, Nana shqiptare (12 words)
        app = launch()
        choose(app, category: "nena-shqiptare", style: "explaining")
        note("Spiel 8: Turnier · 2 Personen · 3 Runden · Nana shqiptare")
        tournament(app, game: 8, extraPlayers: 0, rounds: "3")
        for index in 1...6 {
            turn(app, game: 8, index: index, guessed: index % 3 != 0)
            tap(app, "NextTurn")
        }
        capture("g8-finish", app); note("Spiel 8 beendet"); tap(app, "ReturnHome")
        app.terminate()

        // 9 · Humor & TV: save and leave mid-game, relaunch and continue
        app = launch()
        choose(app, category: "humor-tv", style: "freeChoice")
        note("Spiel 9: Humor & TV · speichern, App neu starten, weiterspielen")
        start(app)
        turn(app, game: 9, index: 1, guessed: true); tap(app, "NextTurn")
        tap(app, "ExitGame"); tap(app, "Ruaje dhe dil")
        XCTAssertTrue(app.buttons["ResumeSavedGame"].waitForExistence(timeout: 5))
        capture("g9-saved-home", app); note("  gespeichert und verlassen")
        app.terminate()
        app.launchArguments = ["--kape-ui-tests", "--kape-keep-state"]
        app.launch()
        tap(app, "ResumeSavedGame"); note("  nach Neustart fortgesetzt")
        if app.buttons["ResumeGame"].waitForExistence(timeout: 2) { tap(app, "ResumeGame") }
        turn(app, game: 9, index: 2, guessed: false)
        finishTogether(app, game: 9)
        app.terminate()

        // 10 · Politikë, explaining: reach the last ten seconds
        app = launch(duration: "12")
        choose(app, category: "politike", style: "explaining")
        note("Spiel 10: Politikë · Shpjegim · letzte 10 Sekunden")
        start(app)
        tap(app, "RevealWord"); note("Spiel 10, Zug 1: Wort »\(app.staticTexts["SecretWord"].label)«")
        tap(app, "HideWord")
        XCTAssertTrue(app.buttons["Guessed"].waitForExistence(timeout: 5))
        capture("g10-acting-start", app)
        Thread.sleep(forTimeInterval: 3.5)
        capture("g10-last-seconds", app); note("  letzte 10 Sekunden erreicht")
        tap(app, "Guessed"); note("  U gjet")
        finishTogether(app, game: 10)

        let log = XCTAttachment(string: playLog.joined(separator: "\n"))
        log.name = "playthrough-log"; log.lifetime = .keepAlways; add(log)
    }

    func testTimeLimitRequiresJudgment() {
        let app = launch(duration: "5")
        start(app); _ = revealAndAct(app)
        capture("11a-last-seconds", app)
        XCTAssertTrue(app.staticTexts["TimeUpTitle"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.staticTexts["SecretWord"].exists)
        XCTAssertTrue(app.staticTexts["TimeUpRing"].exists, "Time-up shows the empty ring in red.")
        assertClockAndAnswersVisible(app)
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
            XCTAssertTrue(row.label.contains("1 prej 1 radhë"))
            XCTAssertTrue(row.label.contains("vendi 1"))
        }
        _ = standings
        // Play again keeps the people and starts a fresh game at the first person's turn.
        tap(app, "PlayAgain")
        XCTAssertTrue(app.buttons["RevealWord"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Lojtari 1'")).firstMatch.exists)
        capture("15b-tournament-play-again", app)
    }

    func testSettingsAppearanceAndMusicAreAvailableWithoutPurchaseUI() {
        let app = launch()
        tap(app, "SettingsButton")
        capture("16-settings-free", app)
        XCTAssertFalse(app.buttons["RestorePurchases"].exists)
        XCTAssertFalse(app.staticTexts["Blerjet"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["PrivacyLink"].firstMatch.exists)
        XCTAssertTrue(app.descendants(matching: .any)["SupportLink"].firstMatch.exists)
        XCTAssertFalse(app.buttons["AppearancePicker"].exists, "The neon look is always dark")
        capture("17-settings-dark", app)
        let settingsHelp = app.buttons.matching(NSPredicate(format: "label == %@ AND identifier != %@", "Si luhet?", "HelpButton")).firstMatch
        for _ in 0..<8 { if settingsHelp.isHittable { break }; scroll(app) }
        XCTAssertTrue(settingsHelp.isHittable)
        settingsHelp.tap()
        XCTAssertTrue(app.buttons["DismissHelp"].waitForExistence(timeout: 5))
        capture("17b-settings-help", app)
        tap(app, "CloseInstructions")
        tap(app, "CloseSettings")
        capture("18-home-dark", app)
        tap(app, "ChooseCategory")
        capture("19-categories-dark", app)
        tap(app, "Category-muzike")
        XCTAssertTrue(app.buttons["StartTogether"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["PurchaseVIP"].exists)
        XCTAssertFalse(app.buttons["ClosePurchase"].exists)
        XCTAssertTrue(app.buttons["ChooseCategory"].label.contains("Muzikë"))
        start(app)
        _ = revealAndAct(app)
        capture("20-music-free-dark", app)
        tap(app, "Guessed"); tap(app, "FinishTogether"); tap(app, "ReturnHome")
    }

    func testEveryCategoryCanBeSelectedAndMusicTournamentNeedsNoPurchase() {
        let app = launch()
        tap(app, "ChooseCategory")
        XCTAssertTrue(app.buttons["Category-dasma-tradita"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Category-dasma-tradita"].label.contains("e re"))
        XCTAssertFalse(app.buttons["Category-sport"].label.contains("e re"))
        tap(app, "Category-sport")
        for id in ["mix-shqip", "gurbet", "muzike", "sport", "humor-tv", "dasma-tradita", "femijeria", "nena-shqiptare", "historia", "politike", "social-media", "pantomime"] {
            tap(app, "ChooseCategory")
            XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label CONTAINS 'e kyçur'")).firstMatch.exists)
            tap(app, "Category-" + id)
            XCTAssertTrue(app.buttons["StartTournament"].waitForExistence(timeout: 5))
            XCTAssertFalse(app.buttons["PurchaseVIP"].exists)
        }
        tap(app, "ChooseCategory")
        tap(app, "Category-muzike")
        tap(app, "StartTournament")
        capture("21-music-tournament-free", app)
        tap(app, "ConfirmTournament")
        tap(app, "RevealWord")
        XCTAssertTrue(app.staticTexts["SecretWord"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["AccessDenied"].exists)
    }

    func testSocialMediaCategoryStartsACompleteRound() {
        let app = launch()
        tap(app, "ChooseCategory")
        for _ in 0..<10 {
            if app.buttons["Category-social-media"].isHittable { break }
            scroll(app)
        }
        let category = app.buttons["Category-social-media"]
        XCTAssertTrue(category.label.contains("Social Media"))
        XCTAssertTrue(category.label.contains("40"))
        capture("27-social-media-category", app)
        tap(app, "Category-social-media")
        XCTAssertTrue(app.buttons["ChooseCategory"].label.contains("Social Media"))
        capture("28-social-media-home", app)
        start(app)
        tap(app, "RevealWord")
        XCTAssertTrue(app.staticTexts["SecretWord"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["SecretWord"].label.isEmpty)
        capture("29-social-media-word", app)
        tap(app, "HideWord")
        XCTAssertTrue(app.buttons["Guessed"].waitForExistence(timeout: 5))
        assertClockAndAnswersVisible(app)
        tap(app, "Guessed")
        tap(app, "FinishTogether")
        XCTAssertTrue(app.staticTexts["1 fjalë\ne gjetur."].exists)
        tap(app, "ReturnHome")
    }

    func testSmallCategoryExplainsTournamentLimit() {
        let app = launch()
        tap(app, "ChooseCategory")
        tap(app, "Category-nena-shqiptare")
        tap(app, "StartTournament")
        tap(app, "AddPlayer")
        tap(app, "AddPlayer")
        tap(app, "5")
        XCTAssertTrue(app.staticTexts["TournamentTooFewWords"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["ConfirmTournament"].isEnabled)
        tap(app, "3")
        XCTAssertFalse(app.staticTexts["TournamentTooFewWords"].exists)
        XCTAssertTrue(app.buttons["ConfirmTournament"].isEnabled)
    }

    func testCountdownAndCategoryExhaustionRemainUsable() {
        let app = launch()
        // Relaunch without test arguments to verify the real three-second countdown.
        app.terminate()
        app.launchArguments = []
        app.launchEnvironment = [:]
        app.launch()
        XCTAssertTrue(app.buttons["StartTogether"].waitForExistence(timeout: 5))
        start(app)
        tap(app, "RevealWord")
        tap(app, "HideWord")
        XCTAssertTrue(app.staticTexts["Fjala u fsheh"].exists)
        capture("30-real-countdown", app)
        XCTAssertTrue(app.buttons["Guessed"].waitForExistence(timeout: 5))
        tap(app, "Guessed"); tap(app, "FinishTogether"); tap(app, "ReturnHome")
        tap(app, "ChooseCategory"); tap(app, "Category-nena-shqiptare")
        start(app); tap(app, "RevealWord")
        for _ in 0..<12 {
            if app.buttons["ReturnHome"].exists { break }
            tap(app, "AnotherWord")
        }
        XCTAssertTrue(app.staticTexts["I pamë krejt fjalët."].waitForExistence(timeout: 5))
        capture("31-category-exhausted", app)
        tap(app, "ReturnHome")
        XCTAssertTrue(app.buttons["StartTogether"].waitForExistence(timeout: 5))
    }

    func testPantomimeSelectionUsesSilentRulesAndVisibleTimer() {
        let app = launch()
        tap(app, "ChoosePlayStyle")
        XCTAssertTrue(app.buttons["PlayStyle-freeChoice"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["PlayStyle-freeChoice"].isHittable)
        capture("22-play-style-picker", app)
        tap(app, "PlayStyle-pantomime")
        XCTAssertEqual(app.buttons["ChoosePlayStyle"].value as? String, "Pantomimë")
        start(app)
        XCTAssertEqual(app.staticTexts["SessionPlayStyle"].label, "Pantomimë")
        tap(app, "RevealWord")
        XCTAssertEqual(app.staticTexts["PlayStyleRule"].label, "Vetëm me gjeste. Mos fol dhe mos bo tinguj.")
        capture("23-pantomime-private", app)
        tap(app, "HideWord")
        XCTAssertTrue(app.buttons["Guessed"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["ActingPlayStyle"].label, "Pantomimë")
        XCTAssertLessThanOrEqual(app.staticTexts["CharadesTimer"].frame.maxY, app.buttons["Guessed"].frame.minY)
        capture("24-pantomime-acting", app)
        tap(app, "Guessed"); tap(app, "FinishTogether"); tap(app, "ReturnHome")
        XCTAssertEqual(app.buttons["ChoosePlayStyle"].value as? String, "Pantomimë")
    }

    func testExplainingTournamentPreservesRulesAndPointsAfterRelaunch() {
        let app = launch()
        tap(app, "ChoosePlayStyle"); tap(app, "PlayStyle-explaining")
        tap(app, "StartTournament")
        XCTAssertEqual(app.staticTexts["TournamentPlayStyle"].label, "Shpjegim")
        let picker = app.segmentedControls["RoundsPicker"]
        for _ in 0..<12 { if picker.isHittable { break }; scroll(app) }
        picker.buttons["1"].tap()
        tap(app, "ConfirmTournament")
        _ = revealAndAct(app)
        XCTAssertEqual(app.staticTexts["ActingPlayStyle"].label, "Shpjegim")
        capture("25-explaining-acting", app)
        tap(app, "Guessed"); tap(app, "NextTurn")
        tap(app, "RevealWord")
        let word = app.staticTexts["SecretWord"].label
        XCTAssertEqual(app.staticTexts["ReadingPlayStyle"].label, "Shpjegim")
        XCTAssertEqual(app.staticTexts["PlayStyleRule"].label, "Shpjegoje pa e thanë fjalën apo pjesë të saj.")
        capture("26-explaining-private", app)
        tap(app, "ExitGame"); tap(app, "Ruaje dhe dil")
        app.terminate()
        app.launchArguments = ["--kape-ui-tests", "--kape-keep-state"]
        app.launch()
        tap(app, "ResumeSavedGame")
        XCTAssertFalse(app.staticTexts["SecretWord"].exists)
        tap(app, "ResumeGame")
        XCTAssertEqual(app.staticTexts["SecretWord"].label, word)
        XCTAssertEqual(app.staticTexts["ReadingPlayStyle"].label, "Shpjegim")
        tap(app, "HideWord")
        XCTAssertTrue(app.buttons["Guessed"].waitForExistence(timeout: 5))
        XCTAssertLessThanOrEqual(app.staticTexts["CharadesTimer"].frame.maxY, app.buttons["Guessed"].frame.minY)
        tap(app, "NotGuessed"); tap(app, "NextTurn")
        XCTAssertTrue(app.buttons["ReturnHome"].waitForExistence(timeout: 5))
        let first = app.descendants(matching: .any)["Standing-0"].firstMatch
        XCTAssertTrue(first.label.contains("1 pikë"))
        tap(app, "ReturnHome")
        XCTAssertEqual(app.buttons["ChoosePlayStyle"].value as? String, "Shpjegim")
        tap(app, "ChoosePlayStyle"); tap(app, "PlayStyle-freeChoice")
        XCTAssertEqual(app.buttons["ChoosePlayStyle"].value as? String, "Zgjedhje e lirë")
    }

    func testTournamentSupportsFivePeopleAndRemoval() {
        let app = launch()
        tap(app, "StartTournament")
        for _ in 0..<3 { tap(app, "AddPlayer") }
        XCTAssertTrue(app.textFields["PlayerName-4"].exists)
        XCTAssertFalse(app.buttons["AddPlayer"].exists)
        app.textFields["PlayerName-4"].tap()
        app.textFields["PlayerName-4"].typeText("X")
        tap(app, "Hiq lojtarin 5")
        XCTAssertFalse(app.textFields["PlayerName-4"].exists)
        tap(app, "AddPlayer")
        XCTAssertEqual(app.textFields["PlayerName-4"].value as? String, "Lojtari 5")
        app.textFields["PlayerName-2"].tap()
        app.textFields["PlayerName-2"].typeText("X")
        tap(app, "Hiq lojtarin 3")
        XCTAssertEqual(app.textFields["PlayerName-2"].value as? String, "Lojtari 4")
        XCTAssertEqual(app.textFields["PlayerName-3"].value as? String, "Lojtari 5")
        tap(app, "AddPlayer")
        XCTAssertEqual(app.textFields["PlayerName-0"].value as? String, "Lojtari 1")
        XCTAssertEqual(app.textFields["PlayerName-1"].value as? String, "Lojtari 2")
        XCTAssertEqual(app.textFields["PlayerName-4"].value as? String, "Lojtari 6")
        tap(app, "ConfirmTournament")
        XCTAssertTrue(app.buttons["RevealWord"].waitForExistence(timeout: 5))
        capture("21-five-person-handoff", app)
    }
    func testTabletRotationKeepsTheWordPrivateAndTheGamePlayable() {
        let app = launch(intro: true)
        capture("ipad-01-intro-portrait", app)
        tap(app, "CloseInstructions")
        capture("ipad-02-home-portrait", app)
        tap(app, "ChooseCategory")
        capture("ipad-03-categories-portrait", app)
        tap(app, "Category-muzike")
        start(app)
        _ = revealAndAct(app)
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        XCTAssertTrue(app.buttons["Guessed"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["SecretWord"].exists)
        capture("ipad-04-acting-landscape", app)
        XCTAssertGreaterThan(app.frame.width, app.frame.height, "The iPad must actually rotate to landscape.")
        tap(app, "Guessed"); tap(app, "FinishTogether")
        capture("ipad-05-result-landscape", app)
        tap(app, "ReturnHome")
        XCUIDevice.shared.orientation = .portrait
        tap(app, "SettingsButton")
        XCTAssertTrue(app.descendants(matching: .any)["PrivacyLink"].firstMatch.exists)
        capture("ipad-06-settings-portrait", app)
        tap(app, "CloseSettings")
    }

    func testStoreScreenshots() {
        let app = launch(intro: true)
        capture("store-01-intro", app)
        tap(app, "CloseInstructions")
        capture("store-02-home", app)
        tap(app, "ChooseCategory")
        XCTAssertTrue(app.buttons["Category-muzike"].waitForExistence(timeout: 5))
        capture("store-03-categories", app)
        tap(app, "Category-muzike")
        tap(app, "StartTournament")
        XCTAssertTrue(app.buttons["ConfirmTournament"].waitForExistence(timeout: 5))
        capture("store-04-tournament", app)
        let picker = app.segmentedControls["RoundsPicker"]
        for _ in 0..<12 { if picker.isHittable { break }; scroll(app) }
        picker.buttons["1"].tap()
        tap(app, "ConfirmTournament")
        _ = revealAndAct(app)
        capture("store-05-acting", app)
        tap(app, "Guessed"); tap(app, "NextTurn")
        _ = revealAndAct(app)
        tap(app, "NotGuessed"); tap(app, "NextTurn")
        XCTAssertTrue(app.buttons["ReturnHome"].waitForExistence(timeout: 5))
        capture("store-06-results", app)
        tap(app, "ReturnHome")
    }

}
