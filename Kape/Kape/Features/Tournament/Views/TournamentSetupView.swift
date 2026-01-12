import SwiftUI

/// Tournament setup sheet view for configuring players and rounds.
/// Presented as a modal sheet from the main menu.
struct TournamentSetupView: View {
    @Bindable var viewModel: TournamentViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedPlayerIndex: Int?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.trueBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Players Section
                        playersSection
                        
                        // Rounds Section
                        roundsSection
                        
                        // Start Button
                        startButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Turne")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Mbyll") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            focusedPlayerIndex = nil
                        }
                    }
                }
            }
            .toolbarBackground(Color.trueBlack, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Sections
    
    private var playersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Lojtarët")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Text("\(viewModel.players.count)/5")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
            }
            
            // Player List
            ForEach(Array(viewModel.players.enumerated()), id: \.element.id) { index, player in
                PlayerRowView(
                    name: Binding(
                        get: { player.name },
                        set: { viewModel.updatePlayerName(at: index, name: $0) }
                    ),
                    index: index,
                    canRemove: viewModel.canRemovePlayer,
                    isFocused: focusedPlayerIndex == index,
                    onRemove: { viewModel.removePlayer(at: index) },
                    onFocus: { focusedPlayerIndex = index }
                )
                .focused($focusedPlayerIndex, equals: index)
            }
            
            // Add Player Button
            if viewModel.canAddPlayer {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.addPlayer()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        Text("Shto Lojtar")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(Color.neonGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.neonGreen.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityIdentifier("AddPlayerButton")
            }
        }
    }
    
    private var roundsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Raundet për Lojtar")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            
            Picker("Raundet", selection: $viewModel.roundsPerPlayer) {
                ForEach(TournamentConfig.roundOptions, id: \.self) { rounds in
                    Text("\(rounds)")
                        .tag(rounds)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("RoundsPicker")
        }
    }
    
    private var startButton: some View {
        Button {
            // TODO: Story 6.2 - Navigate to turn management
            dismiss()
        } label: {
            Text("FILLO TURNEUN")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    viewModel.canStartTournament ? Color.neonGreen : Color.gray.opacity(0.3)
                )
                .clipShape(Capsule())
                .neonGlow(
                    color: viewModel.canStartTournament ? .neonGreen : .clear,
                    intensity: 0.6
                )
        }
        .disabled(!viewModel.canStartTournament)
        .accessibilityIdentifier("StartTournamentButton")
        .padding(.top, 16)
    }
}

// MARK: - Player Row View

private struct PlayerRowView: View {
    @Binding var name: String
    let index: Int
    let canRemove: Bool
    let isFocused: Bool
    let onRemove: () -> Void
    let onFocus: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Player Number Badge
            Text("\(index + 1)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
                .frame(width: 28, height: 28)
                .background(Color.neonGreen)
                .clipShape(Circle())
            
            // Name TextField
            TextField("Lojtari \(index + 1)", text: $name)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            isFocused ? Color.neonGreen : Color.clear,
                            lineWidth: 1.5
                        )
                )
                .accessibilityIdentifier("PlayerNameField_\(index)")
                .onTapGesture {
                    onFocus()
                }
            
            // Remove Button
            if canRemove {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        onRemove()
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.neonRed.opacity(0.8))
                }
                .accessibilityIdentifier("RemovePlayerButton_\(index)")
            }
        }
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        ))
    }
}

#Preview {
    TournamentSetupView(viewModel: TournamentViewModel())
}
