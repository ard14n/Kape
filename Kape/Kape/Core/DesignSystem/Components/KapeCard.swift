import SwiftUI

/// The central card component displaying the word to guess.
/// Designed for maximum legibility at 80pt with dynamic scaling for long words.
/// Per UX spec: "Audience-First UI" - readable from 2+ meters.
struct KapeCard: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 80, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .minimumScaleFactor(0.5)
            .lineLimit(3)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel("Card word: \(text)")
    }
}

// MARK: - Previews

#Preview("Short Word") {
    ZStack {
        Color.trueBlack.ignoresSafeArea()
        KapeCard(text: "Pite")
    }
}

#Preview("Long Word") {
    ZStack {
        Color.trueBlack.ignoresSafeArea()
        KapeCard(text: "Tavë Kosi me Mish")
    }
}

#Preview("Very Long Word") {
    ZStack {
        Color.trueBlack.ignoresSafeArea()
        KapeCard(text: "Përshëndetje dhe Mirëdita")
    }
}
