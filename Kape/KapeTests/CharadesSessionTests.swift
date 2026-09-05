import XCTest
@testable import Kape

@MainActor
final class CharadesSessionTests: XCTestCase {
    private var clock: TimeInterval = 100
    private func game(mode: CharadesSession.Mode = .tournament, style: CharadesPlayStyle = .freeChoice, people: Int = 2, rounds: Int = 1,
                      count: Int = 60, vip: Bool = false, countdown: TimeInterval = 3) -> CharadesSession {
        let deck = Deck(id: "test", title: "Test", description: "", iconName: "star", difficulty: 1,
                        isPro: vip, cards: (0..<count).map { Card(id: "\($0)", text: "Word \($0)") })
        return CharadesSession(mode: mode, playStyle: style, names: (1...people).map { "Person \($0)" }, rounds: rounds,
                               deck: deck, shuffled: false, countdownDuration: countdown, now: { self.clock })
    }
    private func act(_ game: CharadesSession) {
        game.reveal()
        game.ready()
        clock += 3
        game.tick()
        XCTAssertEqual(game.phase, .acting)
    }

    func testPrivateHandoffAndReadyNeverExposeTheWordToGuessers() {
        let s = game()
        XCTAssertNil(s.visibleWord)
        s.reveal()
        XCTAssertEqual(s.visibleWord, "Word 0")
        s.ready()
        XCTAssertNil(s.visibleWord)
        XCTAssertEqual(s.phase, .countdown)
        clock += 3; s.tick()
        XCTAssertEqual(s.phase, .acting)
        XCTAssertEqual(s.seconds, 60)
        XCTAssertNil(s.visibleWord)
    }
    func testUnknownWordConsumesNoTurnAndNeverRepeats() {
        let s = game()
        s.reveal()
        var seen = Set<String>()
        for _ in 0..<10 {
            XCTAssertTrue(seen.insert(s.visibleWord!).inserted)
            s.anotherWord()
        }
        XCTAssertEqual(s.turnIndex, 0)
        XCTAssertEqual(s.score, 0)
        XCTAssertEqual(s.performerIndex, 0)
    }
    func testDoubleTapCannotAwardTwoPointsOrAdvanceTwoPeople() {
        let s = game()
        act(s)
        s.record(guessed: true); s.record(guessed: true); s.record(guessed: false)
        XCTAssertEqual(s.score, 1)
        XCTAssertEqual(s.turnIndex, 1)
        s.next(); s.next()
        XCTAssertEqual(s.performerIndex, 1)
        XCTAssertEqual(s.phase, .handoff)
        XCTAssertNil(s.visibleWord)
    }
    func testCorrectionReplacesResultAndClosesAtNextTurn() {
        let s = game()
        act(s); s.record(guessed: true)
        let id = s.lastOutcome?.id
        s.correctLastResult()
        XCTAssertEqual(s.score, 0)
        XCTAssertEqual(s.lastOutcome?.id, id)
        s.correctLastResult()
        XCTAssertEqual(s.score, 1)
        s.next(); s.correctLastResult()
        XCTAssertEqual(s.score, 1)
    }
    func testEveryPlayerGetsExactlyFiveTurnsAndTiesShareRank() {
        let s = game(people: 5, rounds: 5)
        var seen = Set<String>()
        for index in 0..<25 {
            XCTAssertEqual(s.performerIndex, index % 5)
            XCTAssertEqual(s.round, index / 5 + 1)
            s.reveal()
            XCTAssertTrue(seen.insert(s.visibleWord!).inserted)
            s.ready(); clock += 3; s.tick()
            s.record(guessed: index % 5 < 2)
            s.next()
        }
        XCTAssertEqual(s.phase, .finished)
        XCTAssertTrue(s.isComplete)
        XCTAssertEqual(s.standings.map(\.turns), [5, 5, 5, 5, 5])
        XCTAssertEqual(s.standings.map(\.points), [5, 5, 0, 0, 0])
        XCTAssertEqual(s.standings.map(\.rank), [1, 1, 3, 3, 3])
        s.record(guessed: true); s.next(); s.reveal()
        XCTAssertEqual(s.turnIndex, 25)
    }
    func testDeadlineEndsTurnOnceWithoutAutoAwardingPoints() {
        let s = game()
        act(s)
        clock += 60; s.tick(); s.tick()
        XCTAssertEqual(s.phase, .timeUp)
        XCTAssertEqual(s.seconds, 0)
        XCTAssertEqual(s.score, 0)
        XCTAssertNil(s.visibleWord)
        s.record(guessed: true); s.record(guessed: true)
        XCTAssertEqual(s.score, 1)
    }
    func testPauseFreezesRemainingTimeAndRequiresExplicitResume() {
        let s = game()
        act(s); clock += 12.25
        s.pause()
        XCTAssertEqual(s.seconds, 48)
        clock += 500; s.tick()
        XCTAssertEqual(s.phase, .paused)
        XCTAssertEqual(s.seconds, 48)
        XCTAssertNil(s.visibleWord)
        s.resume()
        clock += 47.75; s.tick()
        XCTAssertEqual(s.phase, .timeUp)
    }
    func testBackgroundAtDeadlineStillRequiresJudgment() {
        let s = game()
        act(s); clock += 70; s.pause()
        XCTAssertEqual(s.phase, .paused)
        XCTAssertEqual(s.snapshot.resumePhase, .timeUp)
        s.resume()
        XCTAssertEqual(s.phase, .timeUp)
        XCTAssertEqual(s.turnIndex, 0)
    }
    func testRestoreHidesReadingActingAndResults() throws {
        let s = game()
        s.reveal()
        for expected in [CharadesSession.Phase.reading, .acting, .result] {
            if expected == .acting { s.ready(); clock += 3; s.tick() }
            if expected == .result { s.record(guessed: true) }
            let encoded = try JSONEncoder().encode(s.snapshot)
            let restored = try XCTUnwrap(CharadesSession(restoring: JSONDecoder().decode(CharadesSession.Snapshot.self, from: encoded), now: { self.clock }))
            XCTAssertEqual(restored.phase, .paused)
            XCTAssertNil(restored.visibleWord)
            restored.resume()
            XCTAssertEqual(restored.phase, expected)
            XCTAssertEqual(restored.turnIndex, s.turnIndex)
        }
    }
    func testArchiveRoundTripRetainsPartialTurnAndCanBeCleared() throws {
        let suite = "kape-test-\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let s = game()
        act(s); s.record(guessed: true); s.next()
        s.reveal(); s.pause()
        CharadesArchive.save(s.snapshot, defaults: defaults)
        let restored = try XCTUnwrap(CharadesArchive.load(defaults: defaults))
        XCTAssertEqual(restored.score, 1)
        XCTAssertEqual(restored.performerIndex, 1)
        XCTAssertEqual(restored.phase, .paused)
        XCTAssertNil(restored.visibleWord)
        CharadesArchive.clear(defaults: defaults)
        XCTAssertNil(CharadesArchive.load(defaults: defaults))
    }
    func testLegacyPaidSessionCanResumeReplaceWordsAndFinishWithoutPurchases() throws {
        for mode in [CharadesSession.Mode.together, .tournament] {
            let original = game(mode: mode, vip: true)
            original.reveal()
            let encoded = try JSONEncoder().encode(original.snapshot)
            let snapshot = try JSONDecoder().decode(CharadesSession.Snapshot.self, from: encoded)
            XCTAssertTrue(snapshot.deck.isPro, "Fixture retains the old paid flag")
            let restored = try XCTUnwrap(CharadesSession(restoring: snapshot, now: { self.clock }))
            XCTAssertEqual(restored.phase, .paused)
            XCTAssertNil(restored.visibleWord)
            restored.resume()
            XCTAssertEqual(restored.visibleWord, "Word 0")
            restored.anotherWord()
            XCTAssertEqual(restored.visibleWord, "Word 1")
            XCTAssertEqual(restored.turnIndex, 0)
            restored.ready(); clock += 3; restored.tick()
            restored.record(guessed: true); restored.next()
            restored.reveal()
            XCTAssertEqual(restored.visibleWord, "Word 2")
            restored.ready(); clock += 3; restored.tick()
            restored.record(guessed: false)
            if mode == .tournament { restored.next() } else { restored.finishTogether() }
            XCTAssertEqual(restored.phase, .finished)
            XCTAssertEqual(restored.score, 1)
        }
    }
    func testLegacyPaidTimerRestoresRemainingTimeWithNewMonotonicClock() throws {
        let original = game(vip: true)
        act(original)
        clock += 11
        original.pause()
        XCTAssertEqual(original.seconds, 49)
        let state = try JSONDecoder().decode(CharadesSession.Snapshot.self, from: JSONEncoder().encode(original.snapshot))
        clock = 2 // A new device boot has a different system uptime.
        let restored = try XCTUnwrap(CharadesSession(restoring: state, now: { self.clock }))
        restored.resume()
        XCTAssertEqual(restored.seconds, 49)
        clock += 49; restored.tick()
        XCTAssertEqual(restored.phase, .timeUp)
        restored.record(guessed: true)
        XCTAssertEqual(restored.score, 1)
    }
    func testPoolExhaustionDoesNotDeclareUnfairWinnerOrRepeatWords() {
        let s = game(count: 1)
        act(s); s.record(guessed: true); s.next(); s.reveal()
        XCTAssertEqual(s.phase, .exhausted)
        XCTAssertFalse(s.isComplete)
        XCTAssertEqual(s.turnIndex, 1)
        XCTAssertNil(s.visibleWord)
    }
    func testTogetherModeFinishesOnRequestWithGroupScore() {
        let s = game(mode: .together)
        for success in [true, false, true] {
            act(s); s.record(guessed: success); s.next()
        }
        s.finishTogether()
        XCTAssertEqual(s.phase, .finished)
        XCTAssertEqual(s.score, 2)
        XCTAssertEqual(s.turnIndex, 3)
    }
    func testInvalidNamesAndCorruptSnapshotsAreRejected() {
        for names in [["A"], ["", "B"], ["A", " a "], ["Ë", "e"], Array(repeating: "x", count: 6)] {
            XCTAssertFalse(CharadesSession.validNames(names))
        }
        var state = game().snapshot
        state.names = []
        XCTAssertNil(CharadesSession(restoring: state))
        state = game().snapshot
        state.phase = .acting
        XCTAssertNil(CharadesSession(restoring: state))
        state = game().snapshot
        state.remaining = -.infinity
        XCTAssertNil(CharadesSession(restoring: state))
        state = game().snapshot
        state.version = 999
        XCTAssertNil(CharadesSession(restoring: state))
    }
    func testEveryPlayStyleSurvivesPrivateResumeAndCompletedTurnsInBothScoringModes() throws {
        for mode in [CharadesSession.Mode.together, .tournament] {
            for style in CharadesPlayStyle.allCases {
                let s = game(mode: mode, style: style)
                act(s); s.record(guessed: true); s.next()
                s.reveal(); s.pause()
                let data = try JSONEncoder().encode(s.snapshot)
                let state = try JSONDecoder().decode(CharadesSession.Snapshot.self, from: data)
                let restored = try XCTUnwrap(CharadesSession(restoring: state, now: { self.clock }))
                XCTAssertEqual(restored.playStyle, style)
                XCTAssertEqual(restored.score, 1)
                XCTAssertNil(restored.visibleWord)
                restored.resume()
                XCTAssertEqual(restored.visibleWord, "Word 1")
                restored.ready(); clock += 3; restored.tick()
                XCTAssertNil(restored.visibleWord)
                restored.record(guessed: false); restored.next()
                XCTAssertEqual(restored.score, 1)
                XCTAssertEqual(restored.playStyle, style)
                XCTAssertEqual(restored.phase, mode == .tournament ? .finished : .handoff)
            }
        }
    }
    func testLegacyArchiveWithoutStyleKeepsPantomimeAndPrivateState() throws {
        let s = game()
        s.reveal()
        let data = try JSONEncoder().encode(s.snapshot)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        json.removeValue(forKey: "playStyle")
        let legacy = try JSONSerialization.data(withJSONObject: json)
        let suite = "kape-legacy-\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(legacy, forKey: CharadesArchive.key)
        let restored = try XCTUnwrap(CharadesArchive.load(defaults: defaults))
        XCTAssertEqual(restored.playStyle, .pantomime)
        XCTAssertNil(restored.visibleWord)
        restored.resume()
        XCTAssertEqual(restored.visibleWord, "Word 0")
        CharadesArchive.save(restored.snapshot, defaults: defaults)
        XCTAssertEqual(CharadesArchive.load(defaults: defaults)?.playStyle, .pantomime)
    }
    func testUnknownArchivedStyleIsRejectedInsteadOfChangingTheRules() throws {
        let data = try JSONEncoder().encode(game().snapshot)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        json["playStyle"] = "unknown-future-rule"
        let invalid = try JSONSerialization.data(withJSONObject: json)
        XCTAssertThrowsError(try JSONDecoder().decode(CharadesSession.Snapshot.self, from: invalid))
    }
    func testStarterContainsEnoughUniqueWordsForLargestTournament() {
        let starter = CharadesCatalog.starter
        XCTAssertFalse(starter.isPro)
        XCTAssertGreaterThanOrEqual(starter.cards.count, 25)
        XCTAssertEqual(Set(starter.cards.map(\.id)).count, starter.cards.count)
        XCTAssertEqual(Set(starter.cards.map(\.text)).count, starter.cards.count)
    }
    func testRestoreWithoutEntitlementDoesNotClaimVIPWasRestored() async {
        struct NoPurchaseStore: StoreServiceProtocol {
            var transactionUpdates: AsyncStream<String> { AsyncStream { $0.finish() } }
            func fetchProducts() async throws -> [KapeProduct] { [] }
            func purchase(productId: String) async throws -> PurchaseResult { .cancelled }
            func isEntitled(productId: String) async -> Bool { false }
            func restorePurchases() async throws {}
        }
        let store = StoreViewModel(storeService: NoPurchaseStore())
        await store.restorePurchases()
        XCTAssertFalse(store.isVIPUnlocked)
        XCTAssertEqual(store.alertMessage, "Nuk u gjetën blerje VIP në këtë llogari.")
    }
}
