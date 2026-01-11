import SwiftUI

/// Specialized view for rendering shareable result image (1080x1920 portrait)
/// Architecture: Features/Summary/Views/ShareLayoutView.swift
/// Purpose: Rendering only - not for direct display in app UI
/// CR-01 Fix: Uses fixed sizes (not @ScaledMetric) for consistent branded output
struct ShareLayoutView: View {
    let result: GameResult
    
    // CR-01 Fix: Fixed sizes for controlled render environment (no @ScaledMetric)
    // This ensures consistent "Rolex-quality" output regardless of user's accessibility settings
    private let scoreFontSize: CGFloat = 96
    private let footerFontSize: CGFloat = 20
    private let logoSize: CGFloat = 80
    
    // CR-02 Fix: Shared gradient constants matching ResultScreen for brand consistency
    private enum GradientConstants {
        static let rankColorOpacity: Double = 0.4  // Matches ResultScreen
        static let startRadius: CGFloat = 50       // Matches ResultScreen
        static let endRadius: CGFloat = 400        // Matches ResultScreen (scaled for 1080x1920)
    }
    
    var body: some View {
        ZStack {
            // Background: trueBlack + RadialGradient per UX spec
            // CR-02 Fix: Aligned with ResultScreen gradient parameters
            Color.trueBlack
            
            RadialGradient(
                colors: [result.rank.color.opacity(GradientConstants.rankColorOpacity), .trueBlack],
                center: .center,
                startRadius: GradientConstants.startRadius,
                endRadius: GradientConstants.endRadius
            )
            
            VStack(spacing: 0) {
                // Logo area (top)
                Spacer()
                    .frame(height: 120)
                
                logoView
                    .padding(.bottom, 60)
                
                Spacer()
                
                // Score (center-top, dominant)
                scoreView
                    .padding(.bottom, 40)
                
                // Rank Badge (center, below score)
                RankBadge(rank: result.rank, rotation: -3)
                    .scaleEffect(1.5) // Larger for share image
                
                Spacer()
                
                // Footer (bottom)
                footerView
                    .padding(.bottom, 80)
            }
        }
        .frame(width: 1080, height: 1920)
    }
    
    // MARK: - Subviews
    
    private var logoView: some View {
        // Using SF Symbol as placeholder; can swap for AppIcon asset
        Image(systemName: "bird.fill")
            .resizable()
            .scaledToFit()
            .frame(width: logoSize, height: logoSize)
            .foregroundStyle(.white)
            .neonGlow(color: .white, radius: 15)
    }
    
    private var scoreView: some View {
        Text("\(result.score)/\(result.total)")
            .font(.system(size: scoreFontSize, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .minimumScaleFactor(0.5)
            .neonGlow(color: result.rank.color, radius: 25)
    }
    
    private var footerView: some View {
        Text("kape.app")
            .font(.system(size: footerFontSize, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.8))
    }
}

// MARK: - Previews

#Preview("Legjendë (10/12)") {
    ShareLayoutView(result: GameResult(score: 10, passed: 2, date: Date()))
        .scaleEffect(0.2)
        .frame(width: 216, height: 384)
}

#Preview("Shqipe (7/10)") {
    ShareLayoutView(result: GameResult(score: 7, passed: 3, date: Date()))
        .scaleEffect(0.2)
        .frame(width: 216, height: 384)
}

#Preview("Mish i Huaj (3/8)") {
    ShareLayoutView(result: GameResult(score: 3, passed: 5, date: Date()))
        .scaleEffect(0.2)
        .frame(width: 216, height: 384)
}
