import SwiftUI

struct CharadesHomeView: View {
    private enum Sheet: String, Identifiable { case help, settings, categories, tournament, playStyle; var id: String { rawValue } }
    @Environment(\.dynamicTypeSize) private var typeSize
    @EnvironmentObject private var decks: DeckService
    @AppStorage("kape.intro.play-styles.seen") private var introSeen = false
    @AppStorage("kape.play-style") private var playStyleRaw = CharadesPlayStyle.freeChoice.rawValue
    private var selectedStyle: CharadesPlayStyle { CharadesPlayStyle(rawValue: playStyleRaw) ?? .freeChoice }
    @State private var selectedDeck = CharadesCatalog.mixedDeck(from: [])
    @State private var sheet: Sheet?
    @State private var session: CharadesSession?
    @State private var showingGame = false
    @State private var pendingGame = false
    @State private var loaded = false
    @State private var discardSaved = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                CharadesPage(stretched: true, party: true) {
                    logo(compact: typeSize.isAccessibilitySize || geometry.size.height < 630)
                    Spacer(minLength: 0)
                    if session != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Loja jote u ruajt", systemImage: "pause.circle").font(.headline).foregroundStyle(CharadesTheme.action)
                            Text("Vazhdo aty ku e le. Fjala mbetet e fshehtë.").foregroundStyle(CharadesTheme.muted)
                            if let session { Label(session.playStyle.title, systemImage: session.playStyle.symbol).font(.subheadline.bold()) }
                            Button("Vazhdo lojën") { showingGame = true }
                                .buttonStyle(CharadesButtonStyle()).accessibilityIdentifier("ResumeSavedGame")
                            // Without this a new game could only be started by resuming the old one and leaving it.
                            Button("Lojë e re") { discardSaved = true }
                                .buttonStyle(CharadesButtonStyle(prominent: false)).accessibilityIdentifier("StartFreshGame")
                        }.charadesPanel(CharadesTheme.action)
                    } else {
                        VStack(spacing: 12) {
                            Button { sheet = .categories } label: { categoryCard }
                                .buttonStyle(.plain).accessibilityIdentifier("ChooseCategory")
                                .accessibilityLabel("Kategoria: \(selectedDeck.title). Ndrysho kategorinë")
                            if selectedDeck.id == "all-categories" {
                                Text(selectedDeck.description)
                                    .font(.subheadline).foregroundStyle(CharadesTheme.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .accessibilityIdentifier("MixedCategoryExplanation")
                            }
                            Button { sheet = .playStyle } label: { styleRow }
                                .buttonStyle(.plain).accessibilityIdentifier("ChoosePlayStyle")
                                .accessibilityLabel("Mënyra e lojës. Ndrysho")
                                .accessibilityValue(selectedStyle.title)
                        }
                    }
                    Spacer(minLength: 0)
                    if session == nil && typeSize.isAccessibilitySize { startButtons }
                }
                .scrollBounceBehavior(.basedOnSize, axes: .vertical)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if session == nil && !typeSize.isAccessibilitySize {
                        startButtons.frame(maxWidth: 560).padding(.horizontal, 24).padding(.vertical, 14)
                            .frame(maxWidth: .infinity).background(CharadesTheme.background)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .charadesNavigationBar()
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
            // Alert, not a confirmation dialog, see CharadesPlayView.
            .alert("A don me nisë një lojë të re?", isPresented: $discardSaved) {
                Button("Fshije lojën e ruajtun", role: .destructive) { session = nil; CharadesArchive.clear() }
                Button("Rri këtu", role: .cancel) {}
            } message: {
                Text("Loja e ruajtun fshihet dhe nis prej fillimit.")
            }
            .fullScreenCover(isPresented: $showingGame) {
                if let session {
                    CharadesPlayView(session: session, close: { discard in
                        if discard { self.session = nil; CharadesArchive.clear() }
                        showingGame = false
                    }, replay: { replay(session) })
                }
            }
        }
        .tint(CharadesTheme.accent)
        .preferredColorScheme(.dark)
        .background(CharadesPrivacyCover {
            if showingGame { session?.pause() }
            UIApplication.shared.isIdleTimerDisabled = false
        })
        .task {
            guard !loaded else { return }
            loaded = true
            selectedDeck = CharadesCatalog.mixedDeck(from: decks.decks)
            if let restored = CharadesArchive.load() {
                restored.save = { CharadesArchive.save($0) }
                session = restored
            }
            if !introSeen { sheet = .help }
        }
    }

    private func logo(compact: Bool) -> some View {
        VStack(spacing: compact ? 10 : 18) {
            Text("KAPE!").font(CharadesTheme.logoFont(size: compact ? 46 : 72))
                .foregroundStyle(CharadesTheme.ink)
                .shadow(color: CharadesTheme.brandShadow, radius: 0, x: 4, y: 5)
                .rotationEffect(.degrees(-2))
                .lineLimit(1).minimumScaleFactor(0.5)
            Text("Një fjalë.\nPlot të qeshura.")
                .font(.system(compact ? .subheadline : .headline, design: .rounded, weight: .heavy))
                .multilineTextAlignment(.center).foregroundStyle(CharadesTheme.ink)
        }
        .padding(.horizontal, 14).padding(.top, compact ? 18 : 38).padding(.bottom, compact ? 32 : 48)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 24).fill(CharadesTheme.hero)
                .shadow(color: CharadesTheme.brandShadow, radius: 0, x: 5, y: 7)
                .rotationEffect(.degrees(-3))
        }
        .overlay(alignment: .bottom) {
            Text("HAJDE, LUJMË!").font(.system(.caption, design: .rounded, weight: .black)).tracking(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8).padding(.vertical, 10).frame(maxWidth: .infinity)
                .foregroundStyle(CharadesTheme.onAccent)
                .background {
                    RoundedRectangle(cornerRadius: 3).fill(CharadesTheme.action)
                        .shadow(color: CharadesTheme.onAccent, radius: 0, x: 3, y: 3)
                }
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(CharadesTheme.onAccent, lineWidth: 2))
                .rotationEffect(.degrees(3)).padding(.horizontal, 18).offset(y: 10)
        }
        .overlay(alignment: .topTrailing) {
            Image(systemName: "sparkles").font(.system(size: compact ? 34 : 42, weight: .black))
                .foregroundStyle(CharadesTheme.action)
                .shadow(color: CharadesTheme.onAccent, radius: 0, x: 2, y: 2)
                .rotationEffect(.degrees(12)).offset(x: -4, y: -14)
        }
        .padding(.horizontal, 6).padding(.top, compact ? 14 : 18).padding(.bottom, compact ? 16 : 20)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Kape! Një fjalë. Plot të qeshura.").accessibilityAddTraits(.isHeader)
    }

    /// The category is the one thing a group really chooses, so it owns the screen: named as a
    /// category, in its own colour, with the word count and "Ndrysho" as the only explanation.
    private var categoryCard: some View {
        // Label, name and word count share one left edge; only the symbol stands beside them.
        return HStack(spacing: 16) {
            Image(systemName: selectedDeck.iconName).font(.system(size: 28, weight: .bold))
                .foregroundStyle(CharadesTheme.onAccent).frame(width: 38, height: 44)
            VStack(alignment: .leading, spacing: 4) {
                if !typeSize.isAccessibilitySize {
                    Text("KATEGORIA").font(.system(.caption, design: .rounded, weight: .heavy)).tracking(1.5)
                        .foregroundStyle(CharadesTheme.cardMuted)
                }
                Text(selectedDeck.title).font(.system(.title2, design: .rounded, weight: .heavy)).foregroundStyle(CharadesTheme.onAccent)
                    .lineLimit(2).minimumScaleFactor(0.6).fixedSize(horizontal: false, vertical: true)
                Text("\(CharadesCatalog.uniqueCards(selectedDeck.cards).count) fjalë")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(CharadesTheme.cardMuted)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.system(size: 16, weight: .bold)).foregroundStyle(CharadesTheme.onAccent)
        }
        .padding(18).frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 20).fill(CharadesTheme.card)
                .shadow(color: CharadesTheme.brandShadow, radius: 0, x: 4, y: 5)
        }
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(CharadesTheme.onAccent, lineWidth: 2))
    }

    /// The rule is set once and rarely changed: one quiet line instead of a second big card.
    private var styleRow: some View {
        HStack(spacing: 10) {
            Image(systemName: selectedStyle.symbol).font(.system(size: 20, weight: .bold)).frame(width: 24)
            Text(selectedStyle.title).font(.system(.subheadline, design: .rounded, weight: .bold))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold))
        }
        .foregroundStyle(CharadesTheme.accent)
        .padding(.horizontal, 4).padding(.vertical, 10).frame(minHeight: 44)
        .contentShape(Rectangle())
    }

    private var startButtons: some View {
        VStack(spacing: 10) {
            Button("Lujmë bashkë") { start(mode: .together) }
                .buttonStyle(CharadesButtonStyle()).accessibilityIdentifier("StartTogether")
            // One framed button only: two neon frames below each other fought for the same attention.
            Button { sheet = .tournament } label: {
                Label("Turne me pikë", systemImage: "trophy.fill")
            }
            .buttonStyle(CharadesButtonStyle(prominent: false, bare: true)).accessibilityIdentifier("StartTournament")
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

    /// Same people, rules and category after a finished game; the words are shuffled anew.
    private func replay(_ finished: CharadesSession) {
        let old = finished.snapshot
        let next = CharadesSession(mode: old.mode, playStyle: finished.playStyle, names: old.names, rounds: old.rounds, deck: old.deck,
                                   turnDuration: old.turnDuration, countdownDuration: old.countdownDuration)
        next.save = { CharadesArchive.save($0) }
        CharadesArchive.save(next.snapshot)
        session = next
    }
}

struct CharadesInstructions: View {
    var firstTime = false
    var close: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        NavigationStack {
            CharadesPage {
                CharadesHeading(eyebrow: "3 hapa", title: "Telefoni në tavolinë.\nDuart të lira.", detail: "")
                VStack(alignment: .leading, spacing: 24) {
                    step("eye.slash.fill", "Lexoje vetëm ti", "Të tjerët s’duhet me e pa fjalën.")
                    step("iphone", "Fshihe dhe lëshoje telefonin", "Shtype Gati – fshihe. I ke 3 sekonda me e lanë telefonin në tavolinë.")
                    step("theatermasks.fill", "Ndihmo grupin me e gjetë", "Gjeste ose shpjegim. Grupi ka 60 sekonda.")
                }
                if !firstTime { VStack(alignment: .leading, spacing: 18) {
                    Text("Ti e zgjedh si luhet").font(.system(.title2, design: .rounded, weight: .heavy)).accessibilityAddTraits(.isHeader)
                    ForEach(CharadesPlayStyle.allCases) { style in
                        VStack(alignment: .leading, spacing: 6) {
                            Label { Text(style.title) } icon: {
                                Image(systemName: style.symbol).font(.system(size: 24, weight: .bold)).foregroundStyle(CharadesTheme.accent)
                            }.font(.headline)
                            Text(style.summary).foregroundStyle(CharadesTheme.muted)
                        }.accessibilityElement(children: .combine)
                            .accessibilityIdentifier("HelpStyle-\(style.rawValue)")
                    }
                }.padding(.top, 12) }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Button(firstTime ? (typeSize.isAccessibilitySize ? "Hajde me lujt" : "E kuptova – hajde me lujt") : "U kuptua", action: close)
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

    private func step(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol).font(.system(size: 23, weight: .bold))
                .foregroundStyle(CharadesTheme.accent).frame(width: 38, height: 38)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.system(.headline, design: .rounded, weight: .heavy))
                Text(detail).foregroundStyle(CharadesTheme.muted).fixedSize(horizontal: false, vertical: true)
            }
        }.accessibilityElement(children: .combine)
    }
}

struct CharadesCategories: View {
    let decks: [Deck]
    @Binding var selected: Deck
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        NavigationStack {
            CharadesPage {
                Text("Zgjedhi fjalët.").font(.system(.title, design: .rounded, weight: .heavy)).accessibilityAddTraits(.isHeader)
                tile(CharadesCatalog.mixedDeck(from: decks), featured: true)
                Text("Ose zgjedhe një kategori")
                    .font(.headline).foregroundStyle(CharadesTheme.muted).accessibilityAddTraits(.isHeader)
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(availableDecks) { tile($0, featured: false) }
                }
            }
            .navigationTitle("Kategoritë").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Mbyll") { dismiss() } } }
        }.tint(CharadesTheme.accent)
    }
    private var availableDecks: [Deck] {
        let all = decks.filter { $0.id != CharadesCatalog.starter.id && $0.id != "all-categories" } + [CharadesCatalog.starter]
        return all.filter { $0.id == "mix-shqip" } + all.filter { $0.id != "mix-shqip" }
    }
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 14, alignment: .top), count: typeSize.isAccessibilitySize ? 1 : 2)
    }
    private func tile(_ deck: Deck, featured: Bool) -> some View {
        let color = CharadesTheme.deckColor(deck.id)
        let isSelected = selected.id == deck.id
        let isNew = deck.isNew == true
        let wordCount = CharadesCatalog.uniqueCards(deck.cards).count
        return Button {
            selected = deck
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: deck.iconName).font(.system(size: 28, weight: .bold)).foregroundStyle(CharadesTheme.onAccent)
                    Spacer(minLength: 0)
                    if isNew {
                        Text("E RE").font(.system(.caption2, design: .rounded, weight: .heavy)).foregroundStyle(CharadesTheme.ink)
                            .padding(.horizontal, 7).padding(.vertical, 3).background(CharadesTheme.onAccent, in: Capsule())
                    }
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 22)).foregroundStyle(CharadesTheme.onAccent)
                    }
                }
                Text(deck.title).font(.system(.headline, design: .rounded, weight: .heavy)).foregroundStyle(CharadesTheme.onAccent)
                    .fixedSize(horizontal: false, vertical: true)
                if featured || typeSize.isAccessibilitySize {
                    Text(deck.description).font(.subheadline).foregroundStyle(CharadesTheme.onAccent).fixedSize(horizontal: false, vertical: true)
                }
                Text("\(wordCount) fjalë").font(.caption.bold()).foregroundStyle(CharadesTheme.cardMuted)
            }
            .padding(16).frame(maxWidth: .infinity, minHeight: featured ? 0 : 124, alignment: .topLeading)
            .background {
                RoundedRectangle(cornerRadius: 18).fill(color)
                    .shadow(color: isSelected ? CharadesTheme.action : CharadesTheme.brandShadow, radius: 0, x: 3, y: 4)
            }
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(CharadesTheme.onAccent, lineWidth: isSelected ? 3 : 2))
        }.buttonStyle(.plain).accessibilityIdentifier("Category-\(deck.id)")
        .accessibilityLabel("\(deck.title), \(wordCount) fjalë" + (isNew ? ", e re" : "") + (isSelected ? ", e zgjedhur" : ""))
        .accessibilityHint(deck.description)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
    private var wordCount: Int { CharadesCatalog.uniqueCards(deck.cards).count }
    private var valid: Bool { CharadesSession.validNames(names) && wordCount >= names.count * rounds }
    /// The rounds picker is the app's only segmented control; give it the neon colours once.
    private static let neonPicker: Void = {
        let control = UISegmentedControl.appearance()
        control.selectedSegmentTintColor = UIColor(CharadesTheme.action)
        control.backgroundColor = UIColor(CharadesTheme.panel)
        control.setTitleTextAttributes([.foregroundColor: UIColor(CharadesTheme.onAccent),
                                        .font: UIFont.systemFont(ofSize: 17, weight: .heavy)], for: .selected)
        control.setTitleTextAttributes([.foregroundColor: UIColor(CharadesTheme.ink),
                                        .font: UIFont.systemFont(ofSize: 17, weight: .bold)], for: .normal)
    }()
    var body: some View {
        let _ = Self.neonPicker
        NavigationStack {
            CharadesPage {
                CharadesHeading(eyebrow: "Turne me pikë", title: "Kush don me lujt?", detail: "2–5 persona · \(deck.title)",
                                symbol: "trophy.fill", color: CharadesTheme.action)
                Label(playStyle.title, systemImage: playStyle.symbol).font(.headline).foregroundStyle(CharadesTheme.accent)
                    .accessibilityIdentifier("TournamentPlayStyle")
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(players) { player in
                        let index = players.firstIndex { $0.id == player.id } ?? 0
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("\(index + 1)").font(.headline).foregroundStyle(CharadesTheme.action).frame(width: 24)
                            TextField("Emri", text: nameBinding(for: player.id)).textInputAutocapitalization(.words)
                                .autocorrectionDisabled().font(.system(.body, design: .rounded, weight: .bold))
                                .padding(.horizontal, 12).padding(.vertical, 10)
                                .background(CharadesTheme.background, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(CharadesTheme.action.opacity(0.7), lineWidth: 1.5))
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
                        Text("Shkruj emra të ndryshëm, me 1–24 shkronja.").font(.footnote).foregroundStyle(CharadesTheme.warning)
                    }
                }.charadesPanel(CharadesTheme.action)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Radhë për person").font(.headline)
                    Picker("Radhë për person", selection: $rounds) {
                        ForEach([1, 3, 5], id: \.self) { Text("\($0)").tag($0) }
                    }.pickerStyle(.segmented).accessibilityIdentifier("RoundsPicker")
                    Text("\(names.count * rounds) fjalë gjithsej · deri në 60 sekonda për fjalë")
                        .font(.subheadline).foregroundStyle(CharadesTheme.muted)
                    if wordCount < names.count * rounds {
                        Text("Kjo kategori ka vetëm \(wordCount) fjalë. Zgjedh ma pak radhë ose persona.")
                            .font(.footnote).foregroundStyle(CharadesTheme.warning)
                            .accessibilityIdentifier("TournamentTooFewWords")
                    }
                }
            }
            // Pinned like the start buttons on the home screen: with five players the start button
            // used to scroll out of reach.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Button("Fillo turneun") { start(names, rounds) }
                    .buttonStyle(CharadesButtonStyle()).disabled(!valid).accessibilityIdentifier("ConfirmTournament")
                    .frame(maxWidth: 560).padding(.horizontal, 24).padding(.vertical, 14)
                    .frame(maxWidth: .infinity).background(CharadesTheme.background)
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
