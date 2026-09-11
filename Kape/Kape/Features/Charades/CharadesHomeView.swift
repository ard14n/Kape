import SwiftUI

struct CharadesHomeView: View {
    private enum Sheet: String, Identifiable { case help, settings, categories, tournament, playStyle; var id: String { rawValue } }
    @Environment(\.dynamicTypeSize) private var typeSize
    @EnvironmentObject private var decks: DeckService
    @AppStorage("kape.intro.play-styles.seen") private var introSeen = false
    @AppStorage("kape.appearance") private var appearance = "system"
    @AppStorage("kape.play-style") private var playStyleRaw = CharadesPlayStyle.freeChoice.rawValue
    private var selectedStyle: CharadesPlayStyle { CharadesPlayStyle(rawValue: playStyleRaw) ?? .freeChoice }
    @State private var selectedDeck = CharadesCatalog.starter
    @State private var sheet: Sheet?
    @State private var session: CharadesSession?
    @State private var showingGame = false
    @State private var pendingGame = false
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                CharadesPage {
                    if !typeSize.isAccessibilitySize && geometry.size.height >= 700 {
                        CharadesHeading(eyebrow: "Gjeni fjalën në shqip", title: "Një fjalë.\nPlot të qeshura.",
                                        detail: "Me gjeste apo me fjalë?\nZgjidhni si doni me lujt.", symbol: "hands.sparkles")
                    }
                    if session != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Loja juaj është ruajtur", systemImage: "pause.circle").font(.headline)
                            Text("Vazhdoni aty ku e latë. Fjala mbetet e fshehur.").foregroundStyle(CharadesTheme.muted)
                            if let session { Label(session.playStyle.title, systemImage: session.playStyle.symbol).font(.subheadline.bold()) }
                            Button("Vazhdo lojën") { showingGame = true }
                                .buttonStyle(CharadesButtonStyle()).accessibilityIdentifier("ResumeSavedGame")
                        }.charadesPanel()
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("KATEGORIA").font(.caption.bold()).foregroundStyle(CharadesTheme.muted)
                            Button { sheet = .categories } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: selectedDeck.iconName).font(.system(size: 24, weight: .medium)).foregroundStyle(CharadesTheme.accent)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(selectedDeck.title).font(.system(.title3, design: .rounded, weight: .bold))
                                        Text(typeSize.isAccessibilitySize ? "\(selectedDeck.cards.count) fjalë" : "\(selectedDeck.cards.count) fjalë · Ndrysho").font(.subheadline).foregroundStyle(CharadesTheme.muted)
                                    }
                                    Spacer(minLength: 0)
                                    Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundStyle(CharadesTheme.muted)
                                }.charadesPanel()
                            }.buttonStyle(.plain).accessibilityIdentifier("ChooseCategory")
                            .accessibilityLabel("Kategoria: \(selectedDeck.title). Ndrysho kategorinë")
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            Text("MËNYRA E LOJËS").font(.caption.bold()).foregroundStyle(CharadesTheme.muted)
                            Button { sheet = .playStyle } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: selectedStyle.symbol).font(.system(size: 24, weight: .medium)).foregroundStyle(CharadesTheme.accent)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(selectedStyle.title).font(.system(.title3, design: .rounded, weight: .bold))
                                        Text(typeSize.isAccessibilitySize ? selectedStyle.shortSummary : selectedStyle.summary).font(.subheadline).foregroundStyle(CharadesTheme.muted)
                                    }
                                    Spacer(minLength: 0)
                                    Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundStyle(CharadesTheme.muted)
                                }.charadesPanel()
                            }.buttonStyle(.plain).accessibilityIdentifier("ChoosePlayStyle")
                                .accessibilityLabel("Mënyra e lojës. Ndrysho")
                                .accessibilityValue(selectedStyle.title)
                        }
                    }
                    if session == nil && typeSize.isAccessibilitySize { startButtons }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if session == nil && !typeSize.isAccessibilitySize {
                        startButtons.frame(maxWidth: 560).padding(.horizontal, 24).padding(.vertical, 14)
                            .frame(maxWidth: .infinity).background(CharadesTheme.background)
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
                    CharadesSettings()
                case .categories:
                    CharadesCategories(decks: decks.decks, selected: $selectedDeck)
                case .playStyle:
                    CharadesStylePicker(selected: selectedStyle) { playStyleRaw = $0.rawValue; sheet = nil }
                case .tournament:
                    CharadesTournamentSetup(deck: selectedDeck, playStyle: selectedStyle) { names, rounds in
                        start(mode: .tournament, names: names, rounds: rounds, fromSheet: true)
                    }
                }
            }
            .fullScreenCover(isPresented: $showingGame) {
                if let session {
                    CharadesPlayView(session: session) { discard in
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
        }
    }

    private var startButtons: some View {
        VStack(spacing: 10) {
            Button("Lujmë bashkë") { start(mode: .together) }
                .buttonStyle(CharadesButtonStyle()).accessibilityIdentifier("StartTogether")
            Button("Turne me pikë") { sheet = .tournament }
                .buttonStyle(CharadesButtonStyle(prominent: false)).accessibilityIdentifier("StartTournament")
        }
    }

    private func start(mode: CharadesSession.Mode, names: [String] = ["Së bashku"], rounds: Int = 3, fromSheet: Bool = false) {
        var duration: TimeInterval = 60
        var countdown: TimeInterval = 3
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--kape-ui-tests") {
            duration = max(1, min(60, Double(ProcessInfo.processInfo.environment["KAPE_TEST_GAME_DURATION"] ?? "60") ?? 60))
            countdown = 0.5
        }
        #endif
        let newSession = CharadesSession(mode: mode, playStyle: selectedStyle, names: names, rounds: rounds, deck: selectedDeck,
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
                                detail: "Mjaftojnë 3 hapa për me fillu.", symbol: "theatermasks")
                VStack(alignment: .leading, spacing: 24) {
                    step("1", "Lexoje vetëm ti", "Shiko fjalën mshehtas. Të tjerët s’duhet me e pa.")
                    step("2", "Fshihe dhe lëre telefonin", "Shtyp «Gati». Fjala fshihet dhe ke 3 sekonda me e lanë telefonin në tavolinë.")
                    step("3", "Ndihmo grupin me e gjetë", "Luj me gjeste ose shpjego, sipas mënyrës që keni zgjedhë. Grupi ka 60 sekonda me e gjetë. Shënoni rezultatin dhe kalojani telefonin personit tjetër.")
                }.charadesPanel()
                VStack(alignment: .leading, spacing: 18) {
                    Text("Ju zgjidhni si luhet").font(.title2.bold()).accessibilityAddTraits(.isHeader)
                    ForEach(CharadesPlayStyle.allCases) { style in
                        VStack(alignment: .leading, spacing: 6) {
                            Label { Text(style.title) } icon: {
                                Image(systemName: style.symbol).font(.system(size: 24, weight: .medium))
                            }.font(.headline)
                            Text(style.summary).foregroundStyle(CharadesTheme.muted)
                        }.accessibilityElement(children: .combine)
                            .accessibilityIdentifier("HelpStyle-\(style.rawValue)")
                    }
                }.charadesPanel()
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Button(firstTime ? "E kuptova – hajde me lujt" : "U kuptua", action: close)
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
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            CharadesPage {
                CharadesHeading(eyebrow: "Zgjidhni fjalët", title: "Prej së lehtës\nte sfida.", detail: "Filloni me veprime e kafshë, ose zgjidhni një temë që ju pëlqen.")
                row(CharadesCatalog.starter)
                Text("Kategoritë e tjera").font(.title2.bold()).accessibilityAddTraits(.isHeader)
                Text("Emra dhe tema shqiptare për pantomimë ose shpjegim.")
                    .foregroundStyle(CharadesTheme.muted)
                ForEach(decks) { row($0) }
            }
            .navigationTitle("Kategoritë").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Mbyll") { dismiss() } } }
        }.tint(CharadesTheme.accent)
    }
    private func row(_ deck: Deck) -> some View {
        return Button {
            selected = deck
            dismiss()
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: deck.iconName).font(.system(size: 24, weight: .medium)).foregroundStyle(CharadesTheme.accent).frame(width: 30)
                VStack(alignment: .leading, spacing: 8) {
                    Text(deck.title).font(.system(.headline, design: .rounded))
                    Text(deck.description).font(.subheadline).foregroundStyle(CharadesTheme.muted)
                    Text("\(deck.cards.count) fjalë").font(.caption.bold()).foregroundStyle(CharadesTheme.accent)
                }.frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: selected.id == deck.id ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(selected.id == deck.id ? CharadesTheme.accent : CharadesTheme.muted)
            }.charadesPanel()
        }.buttonStyle(.plain).accessibilityIdentifier("Category-\(deck.id)")
        .accessibilityLabel("\(deck.title), \(deck.cards.count) fjalë" + (selected.id == deck.id ? ", e zgjedhur" : ""))
        .accessibilityAddTraits(selected.id == deck.id ? .isSelected : [])
    }
}

struct CharadesTournamentSetup: View {
    let deck: Deck
    let playStyle: CharadesPlayStyle
    var start: ([String], Int) -> Void
    @Environment(\.dismiss) private var dismiss
    private struct Player: Identifiable {
        let id = UUID()
        var name: String
    }
    @State private var players = [Player(name: "Lojtari 1"), Player(name: "Lojtari 2")]
    private var names: [String] { players.map(\.name) }
    @State private var rounds = 3
    private var valid: Bool { CharadesSession.validNames(names) && deck.cards.count >= names.count * rounds }
    var body: some View {
        NavigationStack {
            CharadesPage {
                CharadesHeading(eyebrow: "Turne me pikë", title: "Kush don me lujt?", detail: "2–5 persona · \(deck.title)", symbol: "person.2")
                Label(playStyle.title, systemImage: playStyle.symbol).font(.headline)
                    .accessibilityIdentifier("TournamentPlayStyle")
                Text(playStyle.summary).foregroundStyle(CharadesTheme.muted)
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(players) { player in
                        let index = players.firstIndex { $0.id == player.id } ?? 0
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("\(index + 1)").font(.headline).foregroundStyle(CharadesTheme.accent).frame(width: 24)
                            TextField("Emri", text: nameBinding(for: player.id)).textInputAutocapitalization(.words)
                                .autocorrectionDisabled().textFieldStyle(.roundedBorder)
                                .accessibilityLabel("Emri i lojtarit \(index + 1)").accessibilityIdentifier("PlayerName-\(index)")
                            if names.count > 2 {
                                Button { players.removeAll { $0.id == player.id } } label: { Image(systemName: "minus.circle").frame(minWidth: 44, minHeight: 44) }
                                    .accessibilityLabel("Hiq lojtarin \(index + 1)")
                            }
                        }
                    }
                    if names.count < 5 {
                        Button {
                            var n = names.count + 1
                            while names.contains("Lojtari \(n)") { n += 1 }
                            players.append(Player(name: "Lojtari \(n)"))
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
                    if deck.cards.count < names.count * rounds {
                        Text("Kjo kategori ka vetëm \(deck.cards.count) fjalë. Zgjidhni më pak radhë ose persona.")
                            .font(.footnote).foregroundStyle(CharadesTheme.accent)
                            .accessibilityIdentifier("TournamentTooFewWords")
                    }
                }
                Text("1 fjalë për radhë. Kur grupi e gjen, personi që ka radhën merr 1 pikë. Kur nuk e gjen, 0 pikë. Të gjithë lujnë po aq herë; pikët e barabarta ndajnë të njëjtin vend.")
                    .foregroundStyle(CharadesTheme.muted)
                Button("Fillo turneun") { start(names, rounds) }
                    .buttonStyle(CharadesButtonStyle()).disabled(!valid).accessibilityIdentifier("ConfirmTournament")
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Turne").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Mbyll") { dismiss() } } }
        }.tint(CharadesTheme.accent)
    }

    // A focused field can briefly outlive its row while SwiftUI dismisses the keyboard.
    // Resolve by identity so a removed row cannot index or edit a different player.
    private func nameBinding(for id: UUID) -> Binding<String> {
        Binding {
            players.first { $0.id == id }?.name ?? ""
        } set: { value in
            guard let index = players.firstIndex(where: { $0.id == id }) else { return }
            players[index].name = value
        }
    }
}
