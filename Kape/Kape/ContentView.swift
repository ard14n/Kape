import SwiftUI

struct ContentView: View {
    var body: some View {
        CharadesHomeView()
    }
}

#Preview {
    ContentView()
        .environmentObject(DeckService(decks: [
            Deck(
                id: "1",
                title: "Preview Deck",
                description: "Description",
                iconName: "star",
                difficulty: 1,
                isPro: false,
                cards: []
            )
        ]))
}
