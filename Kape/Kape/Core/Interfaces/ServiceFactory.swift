import Foundation

/// Composition root for service instantiation.
/// Creates real implementations of service protocols for production use.
@MainActor
enum ServiceFactory {
    
    /// Creates the production AudioService
    static func makeAudioService() -> AudioServiceProtocol {
        return AudioService()
    }
    
    /// Creates the production HapticService
    static func makeHapticService() -> HapticServiceProtocol {
        return HapticService()
    }
    
    /// Creates a fully configured GameEngine with real services
    static func makeGameEngine() -> GameEngine {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--kape-ui-tests") {
            let unavailable = ProcessInfo.processInfo.arguments.contains("--kape-ui-motion-unavailable")
            let duration = Double(ProcessInfo.processInfo.environment["KAPE_TEST_GAME_DURATION"] ?? "45") ?? 45
            return GameEngine(
                motionManager: MotionManager(motionProvider: UITestMotionProvider(available: !unavailable)),
                audioService: makeAudioService(), hapticService: makeHapticService(),
                configuration: .init(bufferDuration: 0, gameDuration: max(1, min(60, duration)))
            )
        }
        #endif
        return GameEngine(
            motionManager: MotionManager(),
            audioService: makeAudioService(),
            hapticService: makeHapticService()
        )
    }
    
    /// Creates the StoreService.
    /// Returns production StoreService for App Store builds, MockStoreService for DEBUG.
    static func makeStoreService() -> StoreServiceProtocol {
        #if DEBUG
        // Use mock for running tests and previews
        return MockStoreService()
        #else
        // Production StoreKit 2
        return StoreService()
        #endif
    }
}

#if DEBUG
/// Explicit UI-test input; excluded from Release builds. It does not claim real sensor coverage.
private final class UITestMotionProvider: MotionProviding {
    let isAvailable: Bool
    var currentSample: MotionSample? { isAvailable ? MotionSample(x: 1, y: 0, z: 0) : nil }
    init(available: Bool) { isAvailable = available }
    func start(_ handler: @escaping @MainActor (MotionSample?, Error?) -> Void) {}
    func stop() {}
}
#endif
