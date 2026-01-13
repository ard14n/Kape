import SwiftUI

/// Calibration screen that guides the user to position the device correctly
/// before starting the game. Ensures the device is on the forehead in landscape
/// orientation to prevent accidental tilts during gameplay.
struct CalibrationView: View {
    /// The motion manager to validate positioning
    let motionManager: MotionManager
    
    /// Callback when calibration is successful
    let onCalibrated: () -> Void
    
    /// Timer to continuously check position
    @State private var validationTimer: Timer?
    
    /// Current validation state for UI feedback
    @State private var isValid: Bool = false
    @State private var statusMessage: String = "Position device on forehead"
    
    var body: some View {
        VStack(spacing: 40) {
            // Phone icon with positioning indicator
            ZStack {
                Circle()
                    .fill(isValid ? Color.neonGreen.opacity(0.2) : Color.neonRed.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .animation(.easeInOut(duration: 0.3), value: isValid)
                
                Image(systemName: isValid ? "checkmark.circle.fill" : "iphone")
                    .font(.system(size: 80))
                    .foregroundStyle(isValid ? Color.neonGreen : Color.neonRed)
                    .rotationEffect(.degrees(-90)) // Landscape orientation hint
                    .shadow(color: (isValid ? Color.neonGreen : Color.neonRed).opacity(0.5), radius: 20)
                    .animation(.easeInOut(duration: 0.3), value: isValid)
            }
            
            VStack(spacing: 16) {
                Text("Kalibrimi")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(statusMessage)
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .animation(.easeInOut(duration: 0.3), value: statusMessage)
            }
            
            if isValid {
                VStack(spacing: 12) {
                    Image(systemName: "hand.point.up.left.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.neonGreen)
                    
                    Text("Pozita e Saktë!")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.neonGreen)
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                VStack(spacing: 8) {
                    Text("📱 Mbaje telefonin në mënyrë vertikale")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                    
                    Text("🔄 Ktheje në landscape (horizontal)")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                    
                    Text("👤 Vendose mbi ballë")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            startValidation()
        }
        .onDisappear {
            validationTimer?.invalidate()
        }
    }
    
    // MARK: - Validation Logic
    
    private func startValidation() {
        // Check position immediately
        checkPosition()
        
        // Then check every 0.5 seconds
        validationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            checkPosition()
        }
    }
    
    private func checkPosition() {
        let valid = motionManager.validatePosition()
        
        withAnimation {
            isValid = valid
            
            switch motionManager.calibrationState {
            case .notStarted:
                statusMessage = "Duke filluar kalibrimin..."
            case .checking:
                statusMessage = "Duke kontrolluar pozicionin..."
            case .valid:
                statusMessage = "Pozicioni është i saktë!"
                // Auto-proceed after a brief moment
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if isValid {
                        validationTimer?.invalidate()
                        motionManager.calibrate()
                        onCalibrated()
                    }
                }
            case .invalid(let reason):
                statusMessage = "Rikontrollo pozicionin"
            }
        }
    }
}

// MARK: - Previews

#Preview("Calibrating") {
    ZStack {
        Color.trueBlack.ignoresSafeArea()
        CalibrationView(
            motionManager: MotionManager(),
            onCalibrated: {}
        )
    }
}
