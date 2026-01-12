import SwiftUI

/// High-energy result screen celebrating game completion
/// Architecture: Features/Summary/Views/ResultScreen.swift
struct ResultScreen: View {
    let result: GameResult
    var onPlayAgain: (() -> Void)?
    var onShare: (() -> Void)?
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    // Dynamic Type Scaling (Fix CR-01)
    @ScaledMetric(relativeTo: .largeTitle) private var scoreFontSize: CGFloat = 96
    
    // Constants (Fix CR-03: Magic Numbers)
    private enum Constants {
        static let animDurationFade: Double = 0.3
        static let animDurationBounce: Double = 0.5
        static let animDelayBounce: Double = 0.3
        static let scoreTracking: CGFloat = 4
        static let glowRadius: CGFloat = 20
        static let btnHeight: CGFloat = 60
        static let btnCornerRadius: CGFloat = 16
        static let btnGlowRadius: CGFloat = 15
    }
    
    @State private var badgeScale: CGFloat = 0.8
    @State private var scoreOpacity: Double = 0.0
    @State private var playAgainTapped = false
    @State private var shareTapped = false
    
    // Story 3.3: Image generation state
    @State private var isGeneratingImage = false
    @State private var showImageError = false
    @State private var generatedImage: UIImage?
    
    // Story 3.4: Share sheet presentation state
    @State private var showShareSheet = false
    
    var body: some View {
        ZStack {
            // Background: RadialGradient with rank color center fading to black
            RadialGradient(
                colors: [result.rank.color.opacity(0.4), Color.trueBlack],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Score Display (AC: 1)
                VStack(spacing: 8) {
                    Text("SAKTË")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(Constants.scoreTracking)
                    
                    Text("\(result.score)")
                        .font(.system(size: scoreFontSize, weight: .heavy, design: .rounded))
                        .minimumScaleFactor(0.5) // A11y safety
                        .foregroundColor(result.rank.color)
                        .contentTransition(.numericText())
                        .neonGlow(color: result.rank.color, radius: Constants.glowRadius)
                }
                .opacity(scoreOpacity)
                .accessibilityIdentifier("ResultScore")
                
                // Rank Badge (AC: 2)
                RankBadge(rank: result.rank)
                    .scaleEffect(badgeScale)
                    .accessibilityIdentifier("ResultRankBadge")
                
                // Stats Display (AC: 1)
                HStack(spacing: 24) {
                    StatView(value: "\(Int(result.accuracy * 100))%", label: "Accuracy")
                    StatView(value: "\(result.total)", label: "Cards")
                    StatView(value: "\(result.passed)", label: "Passed")
                }
                .padding(.top, 16)
                
                Spacer()
                
                // Action Buttons (AC: 3)
                VStack(spacing: 16) {
                    // Play Again - Primary CTA
                    Button {
                        playAgainTapped.toggle()
                        onPlayAgain?()
                    } label: {
                        Text("Luaj Përsëri")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.trueBlack)
                            .frame(maxWidth: .infinity)
                            .frame(height: Constants.btnHeight)
                            .background(Color.neonGreen)
                            .cornerRadius(Constants.btnCornerRadius)
                            .neonGlow(color: .neonGreen, radius: Constants.btnGlowRadius)
                    }
                    .sensoryFeedback(.impact, trigger: playAgainTapped)
                    .accessibilityIdentifier("PlayAgainButton")
                    
                    // Share - Secondary (Story 3.3: Triggers image generation)
                    Button {
                        shareTapped.toggle()
                        Task {
                            await generateShareImage()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if isGeneratingImage {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                            Text(isGeneratingImage ? "Generating..." : "Share")
                        }
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                    }
                    .disabled(isGeneratingImage)
                    .sensoryFeedback(.impact, trigger: shareTapped)
                    .accessibilityIdentifier("ShareButton")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            animate()
        }
        .alert("Nuk u krijua imazhi", isPresented: $showImageError) {
            Button("Provo Përsëri") {
                Task {
                    await generateShareImage()
                }
            }
            Button("Anulo", role: .cancel) {}
        } message: {
            Text("Provo përsëri.")
        }
        .accessibilityIdentifier("ResultScreen")
        // Story 3.4: Share Sheet presentation
        .sheet(isPresented: $showShareSheet, onDismiss: {
            // AC 3: Clean up state after share completes/cancels
            generatedImage = nil
        }) {
            if let image = generatedImage {
                ShareSheetView(image: image)
            }
        }
    }
    
    private func animate() {
        guard !reduceMotion else {
            badgeScale = 1.0
            scoreOpacity = 1.0
            return
        }
        
        // Score fade in
        withAnimation(.easeOut(duration: Constants.animDurationFade)) {
            scoreOpacity = 1.0
        }
        
        // Badge bounce animation
        withAnimation(.bouncy(duration: Constants.animDurationBounce).delay(Constants.animDelayBounce)) {
            badgeScale = 1.0
        }
    }
    
    // MARK: - Story 3.3: Image Generation
    
    private func generateShareImage() async {
        isGeneratingImage = true
        defer { isGeneratingImage = false }
        
        if let image = await ResultImageGenerator.generate(for: result) {
            // CR-05 Fix: Capture image before callback to prevent race condition
            // Store locally first, then update state
            generatedImage = image
            
            // Story 3.4: Auto-present share sheet after image generation
            await MainActor.run {
                print("✅ Image generated: \(image.size)")
                showShareSheet = true
                onShare?()
            }
        } else {
            showImageError = true
        }
    }
}

// MARK: - Story 3.4: Share Sheet View

/// Wrapper view to present ShareLink in a sheet
private struct ShareSheetView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Preview of image being shared
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 400)
                    .cornerRadius(16)
                    .shadow(radius: 10)
                
                // ShareLink for native sharing
                ShareLink(
                    item: ShareableImage(uiImage: image),
                    preview: SharePreview(
                        "Kape Score",
                        image: Image(uiImage: image)
                    )
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Shpërndaj...")
                    }
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.neonGreen)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding()
            .background(Color.trueBlack)
            .navigationTitle("Shpërndaj Rezultatin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Mbyll") {
                        dismiss()
                    }
                    .foregroundColor(.neonGreen)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

/// Small stat display for accuracy, cards, passed
private struct StatView: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

#Preview {
    ResultScreen(
        result: GameResult(score: 8, passed: 3, date: Date()),
        onPlayAgain: { print("Play Again tapped") },
        onShare: { print("Share tapped") }
    )
}
