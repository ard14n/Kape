import XCTest
@testable import Kape

@MainActor
final class CharadesSessionTests: XCTestCase {
    private var clock: TimeInterval = 100
    private func game(mode: CharadesSession.Mode = .tournament, people: Int = 2, rounds: Int = 1,
                      count: Int = 60, vip: Bool = false, countdown: TimeInterval = 3) -> CharadesSession {
        let deck = Deck(id: "test", title: "Test", description: "", iconName: "star", difficulty: 1,
                        isPro: vip, cards: (0..<count).map { Card(id: "\($0)", text: "Word \($0)") })
        return CharadesSession(mode: mode, names: (1...people).map { "Person \($0)" }, rounds: rounds,
                               deck: deck, shuffled: false, countdownDuration: countdown, now: { self.clock })
    }
    private func act(_ game: CharadesSession, vip: Bool = false) {
        game.reveal(vip: vip)
        game.ready()
        clock += 3
        game.tick()
        XCTAssertEqual(game.phase, .acting)
    }

    func testPrivateHandoffAndReadyNeverExposeTheWordToGuessers() {
        let s = game()
        XCTAssertNil(s.visibleWord)
        s.reveal(vip: false)
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
        s.reveal(vip: false)
        var seen = Set<String>()
        for _ in 0..<10 {
            XCTAssertTrue(seen.insert(s.visibleWord!).inserted)
            s.anotherWord(vip: false)
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
            s.reveal(vip: false)
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
        s.record(guessed: true); s.next(); s.reveal(vip: false)
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
        s.resume(vip: false)
        clock += 47.75; s.tick()
        XCTAssertEqual(s.phase, .timeUp)
    }
    func testBackgroundAtDeadlineStillRequiresJudgment() {
        let s = game()
        act(s); clock += 70; s.pause()
        XCTAssertEqual(s.phase, .paused)
        XCTAssertEqual(s.snapshot.resumePhase, .timeUp)
        s.resume(vip: false)
        XCTAssertEqual(s.phase, .timeUp)
        XCTAssertEqual(s.turnIndex, 0)
    }
    func testRestoreHidesReadingActingAndResults() throws {
        let s = game()
        s.reveal(vip: false)
        for expected in [CharadesSession.Phase.reading, .acting, .result] {
            if expected == .acting { s.ready(); clock += 3; s.tick() }
            if expected == .result { s.record(guessed: true) }
            let encoded = try JSONEncoder().encode(s.snapshot)
            let restored = try XCTUnwrap(CharadesSession(restoring: JSONDecoder().decode(CharadesSession.Snapshot.self, from: encoded), now: { self.clock }))
            XCTAssertEqual(restored.phase, .paused)
            XCTAssertNil(restored.visibleWord)
            restored.resume(vip: false)
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
        s.reveal(vip: false); s.pause()
        CharadesArchive.save(s.snapshot, defaults: defaults)
        let restored = try XCTUnwrap(CharadesArchive.load(defaults: defaults))
        XCTAssertEqual(restored.score, 1)
        XCTAssertEqual(restored.performerIndex, 1)
        XCTAssertEqual(restored.phase, .paused)
        XCTAssertNil(restored.visibleWord)
        CharadesArchive.clear(defaults: defaults)
        XCTAssertNil(CharadesArchive.load(defaults: defaults))
    }
    func testVIPCannotBeBypassedByTournamentRestoreOrUnknownWord() throws {
        let s = game(vip: true)
        s.reveal(vip: false)
        XCTAssertTrue(s.accessDenied)
        XCTAssertNil(s.visibleWord)
        XCTAssertEqual(s.snapshot.pool.count, 60)
        s.reveal(vip: true)
        let restored = try XCTUnwrap(CharadesSession(restoring: s.snapshot))
        restored.resume(vip: false)
        XCTAssertNil(restored.visibleWord)
        s.anotherWord(vip: false)
        XCTAssertEqual(s.phase, .paused)
        XCTAssertNil(s.visibleWord)
        XCTAssertEqual(s.snapshot.pool.count, 59)
    }
    func testVIPRevocationAllowsJudgingCurrentTurnButBlocksNextReveal() {
        let s = game(vip: true)
        act(s, vip: true)
        s.pause(); s.resume(vip: false)
        s.record(guessed: true); s.next()
        s.reveal(vip: false)
        XCTAssertEqual(s.score, 1)
        XCTAssertEqual(s.phase, .handoff)
        XCTAssertTrue(s.accessDenied)
        XCTAssertNil(s.visibleWord)
    }
    func testPoolExhaustionDoesNotDeclareUnfairWinnerOrRepeatWords() {
        let s = game(count: 1)
        act(s); s.record(guessed: true); s.next(); s.reveal(vip: false)
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
