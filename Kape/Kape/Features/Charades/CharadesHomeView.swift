import SwiftUI

struct CharadesHomeView: View {
    private enum Sheet: String, Identifiable { case help, settings, categories, tournament; var id: String { rawValue } }
    @EnvironmentObject private var decks: DeckService
    @StateObject private var store = StoreViewModel()
    @AppStorage("kape.intro.seen") private var introSeen = false
    @AppStorage("kape.appearance") private var appearance = "system"
    @State private var selectedDeck = CharadesCatalog.starter
    @State private var sheet: Sheet?
    @State private var session: CharadesSession?
    @State private var showingGame = false
    @State private var pendingGame = false
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            CharadesPage {
                CharadesHeading(eyebrow: "Pantomimë në shqip", title: "Pa fjalë.\nPlot të qeshura.",
                                detail: "Një person luan me gjeste.\nTë tjerët gjejnë fjalën.", symbol: "hands.sparkles")
                if session != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Loja juaj është ruajtur", systemImage: "pause.circle").font(.headline)
                        Text("Vazhdoni aty ku e latë. Fjala mbetet e fshehur.").foregroundStyle(CharadesTheme.muted)
                        Button("Vazhdo lojën") { showingGame = true }
                            .buttonStyle(CharadesButtonStyle()).accessibilityIdentifier("ResumeSavedGame")
                    }.charadesPanel()
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("KATEGORIA").font(.caption.bold()).foregroundStyle(CharadesTheme.muted)
                        Button { sheet = .categories } label: {
                            HStack(spacing: 16) {
                                Image(systemName: selectedDeck.iconName).font(.title2).foregroundStyle(CharadesTheme.accent)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(selectedDeck.title).font(.system(.title3, design: .rounded, weight: .bold))
                                    Text("\(selectedDeck.cards.count) fjalë · Ndrysho").font(.subheadline).foregroundStyle(CharadesTheme.muted)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right").foregroundStyle(CharadesTheme.muted)
                            }.charadesPanel()
                        }.buttonStyle(.plain).accessibilityIdentifier("ChooseCategory")
                        .accessibilityLabel("Kategoria: \(selectedDeck.title). Ndrysho kategorinë")
                    }
                    VStack(spacing: 12) {
                        Button("Luaj së bashku") { start(mode: .together) }
                            .buttonStyle(CharadesButtonStyle()).accessibilityIdentifier("StartTogether")
                        Button("Turne me pikë") { sheet = .tournament }
                            .buttonStyle(CharadesButtonStyle(prominent: false)).accessibilityIdentifier("StartTournament")
                        Text("Së bashku: sa fjalë mund të gjeni?\nTurne: 2–5 persona, radhë të barabarta.")
                            .font(.footnote).foregroundStyle(CharadesTheme.muted).multilineTextAlignment(.center).padding(.top, 4)
                    }
                }
            }
            .navigationTitle("Kape!")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { sheet = .help } label: { Image(systemName: "questionmark.circle").frame(minWidth: 44, minHeight: 44) }
                        .accessibilityLabel("Si luhet?").accessibilityIdentifier("HelpButton")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { sheet = .settings } label: { Image(systemName: "gearshape").frame(minWidth: 44, minHeight: 44) }
                        .accessibilityLabel("Cilësimet").accessibilityIdentifier("SettingsButton")
                }
            }
            .sheet(item: $sheet, onDismiss: {
                if pendingGame { pendingGame = false; showingGame = true }
            }) { item in
                switch item {
                case .help:
                    CharadesInstructions(firstTime: !introSeen) { introSeen = true; sheet = nil }
                case .settings:
                    CharadesSettings(store: store)
                case .categories:
                    CharadesCategories(decks: decks.decks, selected: $selectedDeck, store: store)
                case .tournament:
                    CharadesTournamentSetup(deck: selectedDeck) { names, rounds in
                        start(mode: .tournament, names: names, rounds: rounds, fromSheet: true)
                    }
                }
            }
            .fullScreenCover(isPresented: $showingGame) {
                if let session {
                    CharadesPlayView(session: session, store: store) { discard in
                        if discard { self.session = nil; CharadesArchive.clear() }
                        showingGame = false
                    }
                }
            }
        }
        .tint(CharadesTheme.accent)
        .preferredColorScheme(appearance == "light" ? .light : appearance == "dark" ? .dark : nil)
        .background(CharadesPrivacyCover {
            if showingGame { session?.pause() }
            UIApplication.shared.isIdleTimerDisabled = false
        })
        .task {
            guard !loaded else { return }
            loaded = true
            if let restored = CharadesArchive.load() {
                restored.save = { CharadesArchive.save($0) }
                session = restored
            }
            if !introSeen { sheet = .help }
            await store.loadProductsAndEntitlements()
        }
    }

    private func start(mode: CharadesSession.Mode, names: [String] = ["Së bashku"], rounds: Int = 3, fromSheet: Bool = false) {
        guard !selectedDeck.isPro || store.isVIPUnlocked else {
            selectedDeck = CharadesCatalog.starter
            sheet = .categories
            return
        }
        var duration: TimeInterval = 60
        var countdown: TimeInterval = 3
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--kape-ui-tests") {
            duration = max(1, min(60, Double(ProcessInfo.processInfo.environment["KAPE_TEST_GAME_DURATION"] ?? "60") ?? 60))
            countdown = 0.5
        }
        #endif
        let newSession = CharadesSession(mode: mode, names: names, rounds: rounds, deck: selectedDeck,
                                        turnDuration: duration, countdownDuration: countdown)
        newSession.save = { CharadesArchive.save($0) }
        CharadesArchive.save(newSession.snapshot)
        session = newSession
        if fromSheet { pendingGame = true; sheet = nil } else { showingGame = true }
    }
}

struct CharadesInstructions: View {
    var firstTime = false
    var close: () -> Void
    var body: some View {
        NavigationStack {
            CharadesPage {
                CharadesHeading(eyebrow: "Si luhet?", title: "Telefoni në tavolinë.\nDuart të lira.",
                                detail: "Mjaftojnë 3 hapa për të filluar.", symbol: "theatermasks")
                VStack(alignment: .leading, spacing: 24) {
                    step("1", "Lexoje vetëm ti", "Shiko fjalën fshehurazi. Të tjerët nuk duhet ta shohin.")
                    step("2", "Fshihe dhe lëre telefonin", "Shtyp «Gati». Fjala fshihet dhe ke 3 sekonda për ta lënë telefonin mbi tavolinë.")
                    step("3", "Luaj pa folur", "Paraqite fjalën me gjeste. Grupi ka 60 sekonda për ta gjetur. Pastaj shënoni rezultatin dhe kalojani telefonin personit tjetër.")
                }.charadesPanel()
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Button(firstTime ? "E kuptova – le të luajmë" : "U kuptua", action: close)
                    .buttonStyle(CharadesButtonStyle()).accessibilityIdentifier("CloseInstructions")
                    .frame(maxWidth: 560).padding(.horizontal, 24).padding(.vertical, 14)
                    .frame(maxWidth: .infinity).background(CharadesTheme.background)
            }
            .navigationTitle("Si luhet?").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Mbyll", action: close).accessibilityIdentifier("DismissHelp")
                }
            }
        }.tint(CharadesTheme.accent)
    }

    private func step(_ number: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number).font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(CharadesTheme.accent).frame(width: 32, height: 32)
                .background(CharadesTheme.soft, in: Circle()).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.system(.headline, design: .rounded))
                Text(detail).foregroundStyle(CharadesTheme.muted).fixedSize(horizontal: false, vertical: true)
            }
        }.accessibilityElement(children: .combine)
    }
}

struct CharadesCategories: View {
    let decks: [Deck]
    @Binding var selected: Deck
    @ObservedObject var store: StoreViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showPurchase = false
    var body: some View {
        NavigationStack {
            CharadesPage {
                CharadesHeading(eyebrow: "Zgjidhni fjalët", title: "Nga e lehta\nte sfida.", detail: "Për lojën e parë, provoni Pantomimë.")
                row(CharadesCatalog.starter)
                Text("Kategoritë e tjera").font(.title2.bold()).accessibilityAddTraits(.isHeader)
                Text("Emra dhe tema shqiptare. Disa janë më të vështira për t’u paraqitur pa folur.")
                    .foregroundStyle(CharadesTheme.muted)
                ForEach(decks) { row($0) }
            }
            .navigationTitle("Kategoritë").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Mbyll") { dismiss() } } }
            .sheet(isPresented: $showPurchase) { CharadesPurchase(store: store, decks: decks.filter(\.isPro)) }
        }.tint(CharadesTheme.accent)
    }
    private func row(_ deck: Deck) -> some View {
        let locked = deck.isPro && !store.isVIPUnlocked
        return Button {
            if locked { showPurchase = true } else { selected = deck; dismiss() }
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: deck.iconName).font(.title2).foregroundStyle(CharadesTheme.accent).frame(width: 30)
                VStack(alignment: .leading, spacing: 8) {
                    Text(deck.title).font(.system(.headline, design: .rounded))
                    Text(deck.description).font(.subheadline).foregroundStyle(CharadesTheme.muted)
                    Text("\(deck.cards.count) fjalë" + (locked ? " · VIP" : "")).font(.caption.bold()).foregroundStyle(CharadesTheme.accent)
                }.frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: locked ? "lock" : selected.id == deck.id ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected.id == deck.id ? CharadesTheme.accent : CharadesTheme.muted)
            }.charadesPanel()
        }.buttonStyle(.plain).accessibilityIdentifier("Category-\(deck.id)")
        .accessibilityLabel("\(deck.title), \(deck.cards.count) fjalë" + (locked ? ", e kyçur, VIP" : selected.id == deck.id ? ", e zgjedhur" : ""))
        .accessibilityAddTraits(selected.id == deck.id ? .isSelected : [])
    }
}

struct CharadesTournamentSetup: View {
    let deck: Deck
    var start: ([String], Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var names = ["Lojtari 1", "Lojtari 2"]
    @State private var rounds = 3
    private var valid: Bool { CharadesSession.validNames(names) && deck.cards.count >= names.count * rounds }
    var body: some View {
        NavigationStack {
            CharadesPage {
                CharadesHeading(eyebrow: "Turne me pikë", title: "Kush do të luajë?", detail: "2–5 persona · \(deck.title)", symbol: "person.2")
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(names.indices, id: \.self) { index in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("\(index + 1)").font(.headline).foregroundStyle(CharadesTheme.accent).frame(width: 24)
                            TextField("Emri", text: $names[index]).textInputAutocapitalization(.words)
                                .autocorrectionDisabled().textFieldStyle(.roundedBorder)
                                .accessibilityLabel("Emri i lojtarit \(index + 1)").accessibilityIdentifier("PlayerName-\(index)")
                            if names.count > 2 {
                                Button { names.remove(at: index) } label: { Image(systemName: "minus.circle").frame(minWidth: 44, minHeight: 44) }
                                    .accessibilityLabel("Hiq lojtarin \(index + 1)")
                            }
                        }
                    }
                    if names.count < 5 {
                        Button {
                            var n = names.count + 1
                            while names.contains("Lojtari \(n)") { n += 1 }
                            names.append("Lojtari \(n)")
                        } label: { Label("Shto një person", systemImage: "plus.circle").frame(minHeight: 44) }
                            .accessibilityIdentifier("AddPlayer")
                    }
                    if !CharadesSession.validNames(names) {
                        Text("Shkruani emra të ndryshëm, me 1–24 shkronja.").font(.footnote).foregroundStyle(CharadesTheme.accent)
                    }
                }.charadesPanel()
                VStack(alignment: .leading, spacing: 12) {
                    Text("Radhë për person").font(.headline)
                    Picker("Radhë për person", selection: $rounds) {
                        ForEach([1, 3, 5], id: \.self) { Text("\($0)").tag($0) }
                    }.pickerStyle(.segmented).accessibilityIdentifier("RoundsPicker")
                    Text("\(names.count * rounds) fjalë gjithsej · deri në 60 sekonda për fjalë")
                        .font(.subheadline).foregroundStyle(CharadesTheme.muted)
                }
                Text("1 fjalë për radhë. Kur grupi e gjen, personi që luan me gjeste merr 1 pikë. Kur nuk e gjen, 0 pikë. Të gjithë luajnë po aq herë; pikët e barabarta ndajnë të njëjtin vend.")
                    .foregroundStyle(CharadesTheme.muted)
                Button("Fillo turneun") { start(names, rounds) }
                    .buttonStyle(CharadesButtonStyle()).disabled(!valid).accessibilityIdentifier("ConfirmTournament")
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Turne").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Mbyll") { dismiss() } } }
        }.tint(CharadesTheme.accent)
    }
}
