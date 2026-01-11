import SwiftUI

/// Buffer state overlay showing "Place on Forehead" instructions and countdown.
/// Displayed during the 3-second buffer phase before gameplay begins.
struct BufferView: View {
    /// Time remaining in buffer countdown (e.g., 3.0, 2.5, 2.0, ...)
    let countdown: TimeInterval
    
    /// Computed integer countdown value
    private var countdownInt: Int {
        countdown > 0 ? Int(ceil(countdown)) : 0
    }
    
    var body: some View {
        VStack(spacing: 40) {
            // Phone icon with forehead instruction
            Image(systemName: "iphone")
                .font(.system(size: 80))
                .foregroundStyle(Color.neonRed)
                .rotationEffect(.degrees(-90)) // Landscape orientation hint
                .shadow(color: Color.neonRed.opacity(0.5), radius: 20)
            
            Text("Place on Forehead")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            
            // Countdown number
            Text("\(countdownInt)")
                .font(.system(size: 120, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.neonGreen)
                .contentTransition(.numericText())
                .animation(.bouncy(duration: 0.3), value: countdownInt)
                .neonGlow(color: Color.neonGreen, radius: 15)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Previews

#Preview("Countdown 3") {
    ZStack {
        Color.trueBlack.ignoresSafeArea()
        BufferView(countdown: 3.0)
    }
}

#Preview("Countdown 1") {
    ZStack {
        Color.trueBlack.ignoresSafeArea()
        BufferView(countdown: 1.2)
    }
}
