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
