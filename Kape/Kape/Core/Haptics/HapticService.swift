import UIKit

/// HapticService implementation for generating tactile feedback during gameplay.
/// Conforms to `HapticServiceProtocol` for dependency injection.
///
/// Pre-warms feedback generators on init for <50ms latency requirement (AC: 7).
@MainActor
final class HapticService: HapticServiceProtocol {
    
    // MARK: - Properties
    
    private let heavyImpactGenerator: UIImpactFeedbackGenerator
    private let rigidImpactGenerator: UIImpactFeedbackGenerator
    private let notificationGenerator: UINotificationFeedbackGenerator
    
    /// Indicates whether haptics are supported on this device
    nonisolated let isHapticsSupported: Bool
    
    // MARK: - Initialization
    
    init() {
        // Check hardware capability
        // Note: UIFeedbackGenerator works on all modern iPhones (6s+), but has no effect on older devices
        // CoreHaptics capability check is more accurate but overkill for MVP
        self.isHapticsSupported = UIDevice.current.userInterfaceIdiom == .phone
        
        // Create generators
        self.heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
        self.rigidImpactGenerator = UIImpactFeedbackGenerator(style: .rigid)
        self.notificationGenerator = UINotificationFeedbackGenerator()
        
        // Pre-warm for <50ms latency (AC: 7)
        heavyImpactGenerator.prepare()
        rigidImpactGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    // MARK: - HapticServiceProtocol
    
    func playFeedback(_ type: GameFeedbackType) {
        guard isHapticsSupported else { return }
        
        switch type {
        case .success:
            // AC: 1 - .impact(.heavy) for correct guesses
            heavyImpactGenerator.impactOccurred()
            heavyImpactGenerator.prepare() // Re-prepare for next use
            
        case .pass:
            // AC: 2 - .impact(.rigid) for pass events
            rigidImpactGenerator.impactOccurred()
            rigidImpactGenerator.prepare()
            
        case .warning:
            // AC: 3 - notification-style haptic for 10-second warning
            notificationGenerator.notificationOccurred(.warning)
            notificationGenerator.prepare()
        }
    }
}
