import SwiftUI

struct DeckBrowserView: View {
    // MARK: - Environment
    @EnvironmentObject private var deckService: DeckService
    
    // State (CR-06 FIX: Grouped at top)
    @State private var gameEngine: GameEngine?
    @State private var gameResult: GameResult?
    @State private var showSettingsSheet = false
    @State private var isButtonPressed = false // CR-01 FIX: Moved from line 173
    
    // Logic
    @StateObject private var viewModel = DeckBrowserViewModel()
    @StateObject private var storeViewModel = StoreViewModel()
    
    // MARK: - Body
    var body: some View {
        // CR4.4-M2 FIX: NavigationStack required for toolbar to render
        NavigationStack {
            ZStack {
                Color.trueBlack.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    headerView
                    
                    // Deck List (AC1: vertical list implementation)
                    deckListView
                }
                
                // Floating Start Button
                startButtonOverlay
            }
            .fullScreenCover(item: $gameEngine) { engine in
                GameScreen(engine: engine) { round in
                    // Convert round to GameResult and show ResultScreen
                    gameResult = GameResult.from(round)
                    gameEngine = nil
                }
            }
            .fullScreenCover(item: $gameResult) { result in
                ResultScreen(
                    result: result,
                    onPlayAgain: {
                        gameResult = nil
                        // Optionally restart with same deck
                        if let deck = viewModel.selectedDeck {
                            startNewGame(with: deck)
                        }
                    },
                    onShare: {
                        // Story 3.3 will implement share functionality
                    }
                )
            }
            .sheet(isPresented: $viewModel.showPurchaseSheet) {
                if let product = storeViewModel.vipProduct {
                    PurchaseSheetView(
                        product: product,
                        onPurchase: {
                            await storeViewModel.purchase(product: product)
                        },
                        onDismiss: { 
                            viewModel.showPurchaseSheet = false
                            storeViewModel.purchaseState = .idle // Reset state on dismiss if needed
                        }
                    )
                } else {
                    // Fallback if product fails to load
                    Text("Duke ngarkuar...")
                        .foregroundStyle(.white)
                        .presentationDetents([.fraction(0.3)])
                }
            }
            // CR4.4-M3 FIX: Dynamic alert title based on message content
            .alert(storeViewModel.alertMessage?.contains("rikthyen") == true ? "Sukses" : "Dyqani", isPresented: Binding(
                get: { storeViewModel.alertMessage != nil },
                set: { if !$0 { storeViewModel.alertMessage = nil } }
            )) {
                Button("OK") {
                    storeViewModel.alertMessage = nil
                }
            } message: {
                Text(storeViewModel.alertMessage ?? "")
            }
            .onChange(of: storeViewModel.purchaseState) { oldValue, newValue in
                if newValue == .succeeded {
                    viewModel.showPurchaseSheet = false
                }
            }
            .sheet(isPresented: $showSettingsSheet) {
                SettingsView(storeViewModel: storeViewModel)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettingsSheet = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(.white)
                    }
                    .accessibilityIdentifier("settingsButton")
                }
            }
            .task {
                await storeViewModel.loadProductsAndEntitlements()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        Text("Zgjidh Viben")
            .font(.system(size: 34, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .subtleGlow(color: .neonBlue) // Story 5.1 AC2: Restored subtle glow
            .padding(.top, 20)
            .padding(.bottom, 8) // Reduced padding here because list now has internal top padding
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .accessibilityIdentifier("DeckBrowserHeader")
    }
    
    private var deckListView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Free Decks
                ForEach(deckService.freeDecks) { deck in
                    DeckRowView(
                        deck: deck,
                        isSelected: viewModel.selectedDeck?.id == deck.id,
                        isLocked: false
                    )
                    .accessibilityIdentifier("DeckRow_\(deck.id)")
                    .onTapGesture {
                        withAnimation {
                            viewModel.handleDeckTap(deck, isVIPUnlocked: true) // Free decks always unlocked
                        }
                    }
                }
                
                // VIP Decks Header
                if !deckService.proDecks.isEmpty {
                    Text("Decks VIP")
                        .font(.system(size: 20, weight: .heavy, design: .rounded)) // Story 5.1 AC4: Match Heading spec
                        .foregroundStyle(Color.vipLabel) // Story 5.1 AC4: High-contrast VIP label
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                        .accessibilityIdentifier("VIPDecksHeader")
                }
                
                // VIP Decks
                ForEach(deckService.proDecks) { deck in
                    DeckRowView(
                        deck: deck,
                        isSelected: viewModel.selectedDeck?.id == deck.id,
                        isLocked: !storeViewModel.isVIPUnlocked
                    )
                    .accessibilityIdentifier("DeckRow_\(deck.id)")
                    .onTapGesture {
                        withAnimation {
                            viewModel.handleDeckTap(deck, isVIPUnlocked: storeViewModel.isVIPUnlocked)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 20) // Story 5.1 AC3 FIX: Add top padding INSIDE ScrollView to prevent boundary clipping
            .padding(.bottom, 120)
        }
    }
    
    private var startButtonOverlay: some View {
        VStack {
            Spacer()
            
            Button(action: startGame) {
                Text("FILLO LOJËN")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        viewModel.selectedDeck == nil ? Color.gray.opacity(0.3) : Color.neonGreen
                    )
                    .clipShape(Capsule())
                    .neonGlow(color: viewModel.selectedDeck == nil ? .clear : .neonGreen, intensity: 0.6) // Story 5.1 AC2: Reduced glow
            }
            .scaleEffect(isButtonPressed ? 0.95 : 1.0) // Story 5.1 AC2: Scale down on press
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isButtonPressed)
            .sensoryFeedback(.impact(flexibility: .solid, intensity: 0.8), trigger: isButtonPressed) // Story 5.1: Haptic on press
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isButtonPressed = true }
                    .onEnded { _ in isButtonPressed = false }
            )
            .disabled(viewModel.selectedDeck == nil)
            .accessibilityIdentifier("StartGameButton") // CR-05 FIX
            .padding(.horizontal, 24)
            .padding(.bottom, 10)
        }
    }
    
    // MARK: - Actions
    
    private func startGame() {
        guard let deck = viewModel.selectedDeck else { return }
        startNewGame(with: deck)
    }
    
    private func startNewGame(with deck: Deck) {
        let engine = GameEngine(
            motionManager: MotionManager(),
            audioService: AudioService(),
            hapticService: HapticService()
        )
        
        engine.startRound(with: deck)
        self.gameEngine = engine
    }
}


#Preview {
    DeckBrowserView()
        .environmentObject(DeckService(decks: [
            Deck(
                id: "1",
                title: "Mix Shqip",
                description: "Test description",
                iconName: "star",
                difficulty: 1,
                isPro: false,
                cards: []
            )
        ]))
}
