import SwiftUI

/// Flash overlay that displays colored flash feedback for game actions.
/// Triggers on `.correct` (green) and `.pass` (orange) events.
/// Respects `accessibilityReduceMotion` preference.
struct FlashOverlay: View {
    /// The action that triggered this flash (nil = no flash)
    let action: GameEngine.ActionTrigger?
    
    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private var flashColor: Color {
        guard let event = action?.event else { return .clear }
        switch event {
        case .correct:
            return Color.neonGreen
        case .pass:
            return Color.neonOrange
        }
    }
    
    var body: some View {
        flashColor
            .opacity(isVisible ? (reduceMotion ? 0.4 : 0.7) : 0)
            .ignoresSafeArea()
            .allowsHitTesting(false) // Don't block touches
            .animation(
                reduceMotion 
                    ? .easeOut(duration: 0.3) 
                    : .easeOut(duration: 0.15),
                value: isVisible
            )
            .onChange(of: action) { oldValue, newValue in
                guard newValue != nil else { return }
                triggerFlash()
            }
    }
    
    private func triggerFlash() {
        isVisible = true
        
        // Flash duration: ~0.1s visible, then fade out
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            isVisible = false
        }
    }
}

// MARK: - Previews

#Preview("No Flash") {
    FlashOverlay(action: nil)
}

#Preview("Correct Flash") {
    FlashOverlay(action: GameEngine.ActionTrigger(event: .correct))
        .onAppear {
            // Simulate flash trigger
        }
}

#Preview("Pass Flash") {
    FlashOverlay(action: GameEngine.ActionTrigger(event: .pass))
}
