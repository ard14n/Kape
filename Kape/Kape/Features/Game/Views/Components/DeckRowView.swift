import SwiftUI

struct DeckRowView: View {
    let deck: Deck
    let isSelected: Bool
    var isLocked: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: deck.iconName)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(isSelected ? Color.neonGreen : .white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .stroke(isSelected ? Color.neonGreen : Color.white.opacity(0.2), lineWidth: 2)
                )
                .shadow(color: isSelected ? Color.neonGreen.opacity(0.5) : .clear, radius: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(deck.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text(deck.description)
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.neonGreen)
                    .font(.title2)
                    .shadow(color: Color.neonGreen.opacity(0.5), radius: 4)
            } else if isLocked {
                // CR4.2-01 FIX: Use isLocked (derived from deck.isPro && !isVIPUnlocked)
                // instead of deck.isPro to correctly hide lock for purchased decks (AC4)
                Image(systemName: "lock.fill")
                    .foregroundStyle(Color.neonRed)
                    .font(.title2)
            } else {
                 Image(systemName: "chevron.right")
                    .foregroundStyle(Color.white.opacity(0.3))
                    .font(.body)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemGray6).opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.neonGreen : Color.clear, lineWidth: 2)
        )
        .neonGlow(color: isSelected ? .neonGreen : .clear)
        .contentShape(Rectangle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .opacity(isLocked ? 0.5 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    ZStack {
        Color.trueBlack.ignoresSafeArea()
        
        VStack {
            DeckRowView(
                deck: Deck(
                    id: "1",
                    title: "Mix Shqip",
                    description: "Gjithçka shqip – filma, muzikë, ushqim!",
                    iconName: "sparkles",
                    difficulty: 1,
                    isPro: false,
                    cards: []
                ),
                isSelected: true
            )
            
            // Locked VIP Deck
            DeckRowView(
                deck: Deck(
                    id: "2",
                    title: "Muzikë VIP",
                    description: "Këngë dhe artistë legjendarë.",
                    iconName: "music.mic",
                    difficulty: 2,
                    isPro: true,
                    cards: []
                ),
                isSelected: false,
                isLocked: true
            )
            
            // Unlocked VIP Deck
            DeckRowView(
                deck: Deck(
                    id: "3",
                    title: "Muzikë VIP (Owned)",
                    description: "Këngë dhe artistë legjendarë.",
                    iconName: "music.mic",
                    difficulty: 2,
                    isPro: true,
                    cards: []
                ),
                isSelected: false,
                isLocked: false
            )
        }
        .padding()
    }
}
