import SwiftUI

struct CharadesSettings: View {
    @ObservedObject var store: StoreViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("kape.sound") private var sound = true
    @AppStorage("kape.appearance") private var appearance = "system"
    @State private var help = false
    var body: some View {
        NavigationStack {
            CharadesPage {
                CharadesHeading(eyebrow: "Cilësimet", title: "Sipas dëshirës.", detail: "Rregullojeni për grupin tuaj.")
                VStack(alignment: .leading, spacing: 20) {
                    Toggle("Tingujt e lojës", isOn: $sound).accessibilityIdentifier("SoundToggle")
                    Text("Tingull kur fillon ose mbaron koha. Respekton mënyrën pa zë të telefonit.")
                        .font(.footnote).foregroundStyle(CharadesTheme.muted)
                    Picker("Pamja", selection: $appearance) {
                        Text("Si telefoni").tag("system")
                        Text("E çelët").tag("light")
                        Text("E errët").tag("dark")
                    }.pickerStyle(.menu).accessibilityIdentifier("AppearancePicker")
                }.charadesPanel()
                Button("Si luhet?") { help = true }.buttonStyle(CharadesButtonStyle(prominent: false))
                VStack(alignment: .leading, spacing: 14) {
                    Text("Blerjet").font(.headline)
                    Text(store.isVIPUnlocked ? "Kategoritë VIP janë të hapura." : "Nëse keni blerë VIP më parë, mund ta riktheni këtu.")
                        .foregroundStyle(CharadesTheme.muted)
                    Button(store.isRestoring ? "Duke rikthyer…" : "Rikthe blerjet") { Task { await store.restorePurchases() } }
                        .frame(minHeight: 44).disabled(store.isRestoring).accessibilityIdentifier("RestorePurchases")
                    if let message = store.alertMessage { Text(message).font(.subheadline).foregroundStyle(CharadesTheme.muted) }
                }.charadesPanel()
                Text("Kape! · \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")\nFjalët dhe loja ruhen në këtë telefon.")
                    .font(.footnote).foregroundStyle(CharadesTheme.muted)
            }
            .navigationTitle("Cilësimet").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Mbyll") { dismiss() }.accessibilityIdentifier("CloseSettings") } }
            .sheet(isPresented: $help) { CharadesInstructions { help = false } }
        }.tint(CharadesTheme.accent)
    }
}

struct CharadesPurchase: View {
    @ObservedObject var store: StoreViewModel
    let decks: [Deck]
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            CharadesPage {
                CharadesHeading(eyebrow: "Kategoritë VIP", title: "Më shumë për\ntë luajtur.", detail: "Një blerje e vetme. Pa abonim.", symbol: "rectangle.stack.badge.plus")
                ForEach(decks) { deck in
                    Label("\(deck.title) · \(deck.cards.count) fjalë", systemImage: deck.iconName).font(.headline).charadesPanel()
                }
                Text("Emra dhe tema shqiptare për të luajtur me pantomimë ose shpjegim.")
                    .foregroundStyle(CharadesTheme.muted)
                if store.isVIPUnlocked {
                    Label("VIP është i hapur", systemImage: "checkmark.circle").foregroundStyle(CharadesTheme.accent)
                    Button("Vazhdo") { dismiss() }.buttonStyle(CharadesButtonStyle())
                } else if let product = store.vipProduct {
                    Button(store.purchaseState == .purchasing ? "Duke blerë…" : "Hap VIP · \(product.displayPrice)") {
                        Task { await store.purchase(product: product) }
                    }.buttonStyle(CharadesButtonStyle()).disabled(store.purchaseState == .purchasing || store.isRestoring)
                        .accessibilityIdentifier("PurchaseVIP")
                } else {
                    Text(store.isLoading ? "Duke ngarkuar çmimin…" : "Çmimi nuk u ngarkua. Mund të provoni përsëri ose të luani me kategoritë falas.")
                        .foregroundStyle(CharadesTheme.muted)
                    Button("Provo përsëri") { Task { await store.loadProductsAndEntitlements() } }
                        .buttonStyle(CharadesButtonStyle()).disabled(store.isLoading)
                }
                Button(store.isRestoring ? "Duke rikthyer…" : "Rikthe blerjet") { Task { await store.restorePurchases() } }
                    .frame(minHeight: 44).disabled(store.isRestoring || store.purchaseState == .purchasing)
                    .accessibilityIdentifier("RestoreInOffer")
                if let message = store.alertMessage { Text(message).font(.subheadline).foregroundStyle(CharadesTheme.muted) }
            }
            .navigationTitle("VIP").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Mbyll") { dismiss() }.accessibilityIdentifier("ClosePurchase") } }
        }.tint(CharadesTheme.accent)
    }
}
