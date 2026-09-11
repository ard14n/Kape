import XCTest
@testable import Kape

/// Exercises real lifecycle/calibration logic with deterministic sensor samples.
final class TestMotionProvider: MotionProviding {
    // Avoid the implicit isolated-deinit back-deployment bug (swiftlang/swift#88036).
    nonisolated deinit {}
    var isAvailable = true
    var currentSample: MotionSample? = MotionSample(x: 1, y: 0, z: 0)
    var handler: (@MainActor (MotionSample?, Error?) -> Void)?
    func start(_ handler: @escaping @MainActor (MotionSample?, Error?) -> Void) { self.handler = handler }
    func stop() { handler = nil }
    func emit(_ tilt: Double) {
        currentSample = MotionSample(x: cos(tilt), y: 0, z: sin(tilt))
        handler?(currentSample, nil)
    }
}

@MainActor
final class LaunchRegressionTests: XCTestCase {
    private struct SilentAudio: AudioServiceProtocol { func playSound(_ name: String) {} }
    private struct SilentHaptic: HapticServiceProtocol { func playFeedback(_ type: GameFeedbackType) {} }

    private func deck() -> Deck {
        Deck(id: "regression", title: "Test", description: "", iconName: "star", difficulty: 1,
             isPro: false, cards: (0..<4).map { Card(id: "\($0)", text: "Card \($0)") })
    }

    private func engine(_ provider: TestMotionProvider) -> GameEngine {
        GameEngine(motionManager: MotionManager(motionProvider: provider), audioService: SilentAudio(),
                   hapticService: SilentHaptic(), configuration: .init(bufferDuration: 0, gameDuration: 30))
    }

    private func waitUntil(_ predicate: @escaping @MainActor () -> Bool,
                           file: StaticString = #filePath, line: UInt = #line) async {
        for _ in 0..<200 {
            if predicate() { return }
            try? await Task.sleep(for: .milliseconds(5))
        }
        XCTFail("Expected state was not reached", file: file, line: line)
    }

    private func calibrate(_ game: GameEngine) {
        game.motionManager.startMonitoring()
        XCTAssertTrue(game.motionManager.validatePosition())
        game.motionManager.calibrate()
        game.onCalibrationComplete()
        game.startGameLoop()
    }

    func testGravityCalibrationAcceptsBothLandscapeSidesAndRejectsPortraitOrFlat() {
        let provider = TestMotionProvider()
        let motion = MotionManager(motionProvider: provider)
        for side in [-1.0, 1.0] {
            provider.currentSample = MotionSample(x: side, y: 0, z: 0)
            XCTAssertTrue(motion.validatePosition())
        }
        for sample in [MotionSample(x: 0, y: -1, z: 0), MotionSample(x: 0, y: 0, z: -1),
                       MotionSample(x: 1, y: 0, z: .nan)] {
            provider.currentSample = sample
            XCTAssertFalse(motion.validatePosition())
            XCTAssertFalse(motion.calibrate())
        }
        XCTAssertEqual(MotionSample(x: 0, y: 0, z: 1).tilt, .pi / 2, accuracy: 0.001)
        XCTAssertEqual(MotionSample(x: 0, y: 0, z: -1).tilt, -.pi / 2, accuracy: 0.001)
    }

    func testCalibrationGateCannotBeSkippedByStartingLoop() async {
        let game = engine(TestMotionProvider()); defer { game.stop() }
        game.startRound(with: deck())
        game.startGameLoop()
        await Task.yield()
        XCTAssertEqual(game.gameState, .calibrating)
        XCTAssertEqual(game.currentRound?.score, 0)
    }

    func testCalibrationEventsAreDiscardedBeforeGameplay() async {
        let provider = TestMotionProvider(); let game = engine(provider); defer { game.stop() }
        game.startRound(with: deck())
        game.motionManager.startMonitoring()
        game.motionManager.calibrate()
        provider.emit(0.9)
        provider.emit(0)
        game.onCalibrationComplete(); game.startGameLoop()
        await waitUntil { game.gameState == .playing }
        try? await Task.sleep(for: .milliseconds(30))
        XCTAssertEqual(game.currentRound?.score, 0)
        provider.emit(0.9)
        await waitUntil { game.currentRound?.score == 1 }
    }

    func testPauseResumeRecalibratesAndAcceptsFurtherMotion() async {
        let provider = TestMotionProvider(); let game = engine(provider); defer { game.stop() }
        game.startRound(with: deck()); calibrate(game)
        await waitUntil { game.gameState == .playing }
        provider.emit(0.9)
        await waitUntil { game.currentRound?.score == 1 }
        game.pause()
        XCTAssertEqual(game.motionManager.calibrationState, .notStarted)
        let remaining = game.currentRound?.timeRemaining
        game.resume()
        XCTAssertEqual(game.gameState, .calibrating)
        provider.emit(0)
        try? await Task.sleep(for: .milliseconds(150))
        XCTAssertEqual(game.currentRound?.timeRemaining, remaining)
        calibrate(game)
        provider.emit(0.9)
        await waitUntil { game.currentRound?.score == 2 }
    }

    func testFinishNotifiesTournamentExactlyOnce() async {
        let game = engine(TestMotionProvider()); defer { game.stop() }
        var completions = 0
        game.onGameComplete = { _ in completions += 1 }
        game.startRound(with: deck()); calibrate(game)
        await waitUntil { game.gameState == .playing }
        game.finishGame(); game.finishGame()
        try? await Task.sleep(for: .milliseconds(150))
        XCTAssertEqual(completions, 1)
        XCTAssertEqual(game.gameState, .finished)
    }

    func testSecondRoundHasFreshMotionStreamAndNoStaleFinish() async {
        let provider = TestMotionProvider(); let game = engine(provider); defer { game.stop() }
        game.startRound(with: deck()); calibrate(game)
        await waitUntil { game.gameState == .playing }
        game.finishGame()
        game.startRound(with: deck())
        XCTAssertNil(game.result)
        calibrate(game)
        await waitUntil { game.gameState == .playing }
        provider.emit(0.9)
        await waitUntil { game.currentRound?.score == 1 }
        try? await Task.sleep(for: .milliseconds(150))
        XCTAssertEqual(game.gameState, .playing)
    }

    func testDismissStopsLoopWithoutPublishingResult() async {
        let game = engine(TestMotionProvider())
        var completions = 0
        game.onGameComplete = { _ in completions += 1 }
        game.startRound(with: deck()); calibrate(game)
        await waitUntil { game.gameState == .playing }
        game.stop()
        try? await Task.sleep(for: .milliseconds(150))
        XCTAssertEqual(game.gameState, .idle)
        XCTAssertNil(game.result)
        XCTAssertEqual(completions, 0)
    }

    func testStoreBuffersUpdateBeforeConsumerStartsAndSurvivesReload() async {
        let store = MockStoreService()
        store.purchasedProductIds.insert(StoreViewModel.vipProductId)
        store.emitTransaction(StoreViewModel.vipProductId)
        var iterator = store.transactionUpdates.makeAsyncIterator()
        let buffered = await iterator.next()
        XCTAssertEqual(buffered, StoreViewModel.vipProductId)

        let model = StoreViewModel(storeService: store)
        await model.loadProductsAndEntitlements()
        await model.loadProductsAndEntitlements()
        store.purchasedProductIds.removeAll()
        store.emitTransaction(StoreViewModel.vipProductId)
        await waitUntil { !model.isVIPUnlocked }
        store.purchasedProductIds.insert(StoreViewModel.vipProductId)
        store.emitTransaction(StoreViewModel.vipProductId)
        await waitUntil { model.isVIPUnlocked }
    }

    func testStoreListenerDoesNotRetainViewModel() async {
        let store = MockStoreService()
        var model: StoreViewModel? = StoreViewModel(storeService: store)
        weak var weakModel = model
        await model?.loadProductsAndEntitlements()
        await Task.yield()
        model = nil
        XCTAssertNil(weakModel)
    }
}
