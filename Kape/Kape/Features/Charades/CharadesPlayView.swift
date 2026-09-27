import SwiftUI

struct CharadesPlayView: View {
    @Bindable var session: CharadesSession
    var close: (_ discard: Bool) -> Void
    /// Starts the next game with the same people, rules and category.
    var replay: () -> Void = {}
    @AppStorage("kape.sound") private var sound = true
    @State private var confirmExit = false
    @State private var audio = ServiceFactory.makeAudioService()
    @State private var haptics = ServiceFactory.makeHapticService()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var wordSize: CGFloat = 54
    @ScaledMetric(relativeTo: .title3) private var responseSize: CGFloat = 19

    var body: some View {
        NavigationStack {
            gamePage
            .id(session.phase)
            .overlay {
                if (session.phase == .result && session.lastOutcome?.guessed == true) || session.phase == .finished {
                    CharadesCelebration().id("\(session.phase.rawValue)-\(session.turnIndex)")
                }
            }
            .navigationTitle(session.isTournament ? "Turne" : "Kape!")
            .navigationBarTitleDisplayMode(.inline)
            .charadesNavigationBar()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Dalje") {
                        if session.phase == .finished { close(true) }
                        else { session.pause(); confirmExit = true }
                    }.frame(minHeight: 44).accessibilityIdentifier("ExitGame")
                }
                if session.isClockRunning {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { session.pause() } label: { Image(systemName: "pause.fill").frame(minWidth: 44, minHeight: 44) }
                            .accessibilityLabel("Pauzë").accessibilityIdentifier("PauseGame")
                    }
                }
            }
            // An alert, not a confirmation dialog: since iOS 26 the dialog is a popover pinned to
            // the view it hangs on, which drops the visible cancel choice. The alert always sits in
            // the middle and shows all three answers.
            .alert("A don me dalë?", isPresented: $confirmExit) {
                Button("Ruaje dhe dil") { close(false) }
                Button("Fshije lojën", role: .destructive) { close(true) }
                Button("Rri këtu", role: .cancel) {}
            } message: {
                Text("Mundesh me e ruajtë lojën për ma vonë, ose me e fshi e me nisë prej fillimit.")
            }
        }
        .tint(CharadesTheme.accent)
        .preferredColorScheme(.dark)
        .task(id: session.isClockRunning) {
            guard session.isClockRunning else { return }
            while !Task.isCancelled && session.isClockRunning {
                session.tick()
                do { try await Task.sleep(for: .milliseconds(100)) } catch { return }
            }
        }
        .onChange(of: session.phase) { _, phase in
            UIApplication.shared.isIdleTimerDisabled = session.isClockRunning
            if phase == .acting || phase == .timeUp {
                if sound { audio.playSound("warning") }
                haptics.playFeedback(.warning)
            }
        }
        .onChange(of: session.seconds) { _, seconds in
            // The phone lies on the table: the last seconds can be felt without looking.
            guard session.phase == .acting else { return }
            if seconds == 10 { haptics.playFeedback(.warning) }
            else if (1...5).contains(seconds) { haptics.playFeedback(.pass) }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { session.pause(); UIApplication.shared.isIdleTimerDisabled = false }
        }
        .onDisappear {
            session.pause()
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private var deckColor: Color { CharadesTheme.deckColor(session.snapshot.deck.id) }
    /// A pause during the countdown or while acting keeps a running clock, so the ring replaces the symbol.
    private var clockPaused: Bool { [.acting, .countdown].contains(session.snapshot.resumePhase) }

    private var usesClockLayout: Bool {
        [.countdown, .acting, .timeUp].contains(session.phase) || (session.phase == .paused && clockPaused)
    }

    @ViewBuilder private var gamePage: some View {
        if usesClockLayout {
            // The footer is measured first; the ring uses only the space that actually remains.
            VStack(spacing: 0) {
                VStack(spacing: typeSize.isAccessibilitySize ? 8 : 16) {
                    clockContext.fixedSize(horizontal: false, vertical: true)
                    GeometryReader { geometry in
                        let diameter = max(0, min(270, geometry.size.width - 24, geometry.size.height - 24))
                        clockRing(diameter: diameter)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                    if !typeSize.isAccessibilitySize {
                        Label(session.phase == .paused ? "Koha është ndalë." : "Fjala mbetet e fshehtë.",
                              systemImage: session.phase == .paused ? "pause.fill" : "eye.slash")
                            .font(.footnote).foregroundStyle(CharadesTheme.muted)
                    }
                }
                .padding(.horizontal, 24).padding(.vertical, 12)
                .frame(maxWidth: 560).frame(maxWidth: .infinity)
                actionFooter
            }
            .background(CharadesTheme.background.ignoresSafeArea(.container, edges: .top))
            .foregroundStyle(CharadesTheme.ink)
        } else {
            CharadesPage(centered: true) { content }
                .safeAreaInset(edge: .bottom, spacing: 0) { actionFooter }
        }
    }

    private var actionFooter: some View {
        VStack(spacing: [.acting, .timeUp].contains(session.phase) ? 16 : 10) { actions }
            .frame(maxWidth: 560).padding(.horizontal, 24).padding(.vertical, 14)
            .frame(maxWidth: .infinity).background(CharadesTheme.background)
    }

    @ViewBuilder private var clockContext: some View {
        if session.phase == .countdown {
            Text("Fjala u fsheh").font(.subheadline.bold()).foregroundStyle(CharadesTheme.accent)
            Text("Lëshoje telefonin në tavolinë.").font(.system(.title3, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)
        } else if session.phase == .timeUp {
            Text("Koha mbaroi").font(.system(.headline, design: .rounded, weight: .heavy))
                .foregroundStyle(CharadesTheme.failure).accessibilityIdentifier("TimeUpTitle")
            if !typeSize.isAccessibilitySize {
                Text("A u gjet fjala brenda kohës?").font(.subheadline).multilineTextAlignment(.center)
            }
        } else {
            VStack(spacing: 6) {
                if session.isTournament {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) { performerLabel; roundLabel }
                        VStack(spacing: 4) { performerLabel; roundLabel }
                    }
                } else {
                    Text(progress).font(.system(.headline, design: .rounded, weight: .bold))
                        .padding(.horizontal, typeSize.isAccessibilitySize ? 10 : 16)
                        .padding(.vertical, typeSize.isAccessibilitySize ? 3 : 8)
                        .foregroundStyle(CharadesTheme.ink)
                        .background(CharadesTheme.hero, in: RoundedRectangle(cornerRadius: 8))
                        .rotationEffect(.degrees(typeSize.isAccessibilitySize ? 0 : -3))
                        .accessibilityIdentifier("ActiveTurn")
                }
                if !typeSize.isAccessibilitySize {
                    Label(session.playStyle.title, systemImage: session.playStyle.symbol)
                        .font(.subheadline.bold()).foregroundStyle(CharadesTheme.accent)
                        .accessibilityIdentifier("ActingPlayStyle")
                }
                if session.phase == .paused {
                    Text("Loja është në pauzë").font(.subheadline.bold()).foregroundStyle(CharadesTheme.accent)
                }
            }
        }
    }

    private var performerLabel: some View {
        Text(session.performer).font(.system(.title3, design: .rounded, weight: .heavy))
            .lineLimit(2).minimumScaleFactor(0.7)
            .multilineTextAlignment(.center).accessibilityIdentifier("ActivePerformer")
    }
    private var roundLabel: some View {
        Text("Raundi \(session.round)/\(session.snapshot.rounds)")
            .font(.subheadline.bold()).foregroundStyle(CharadesTheme.muted)
            .accessibilityIdentifier("ActiveRound")
    }

    @ViewBuilder private var content: some View {
        switch session.phase {
        case .handoff:
            CharadesHeading(eyebrow: progress, title: session.isTournament ? "Radha e\n\(session.performer)" : "Kush e ka radhën?",
                            detail: "Jepja telefonin atij që e ka radhën.",
                            // The heading asks who is up, so the symbol shows people. The phone glyph
                            // with an arrow is what iOS uses for logging out and read as "exit".
                            symbol: "person.2.fill", color: CharadesTheme.action)
            chips
            if session.isTournament {
                Text("Nëse grupi e gjen fjalën, \(session.performer) merr 1 pikë.").foregroundStyle(CharadesTheme.muted)
            } else if session.turnIndex > 0 {
                Text(session.score == 1 ? "1 fjalë e gjetur deri tani" : "\(session.score) fjalë të gjetura deri tani").font(.headline).foregroundStyle(CharadesTheme.success)
            }
        case .reading:
            VStack(spacing: 8) {
                Label("Vetëm për ty", systemImage: "eye.slash")
                    .font(.subheadline.bold()).foregroundStyle(CharadesTheme.accent).accessibilityAddTraits(.isHeader)
                if session.isMixed, let category = session.currentCategory {
                    Label(category.title, systemImage: category.iconName)
                        .font(.headline).foregroundStyle(CharadesTheme.deckColor(category.id))
                        .accessibilityIdentifier("ReadingCategory")
                }
            }
            // Keep supporting labels compact so the secret word remains visible above the
            // fixed actions on small phones, including the largest accessibility text size.
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            if let word = session.visibleWord {
                Text(word).font(.system(size: typeSize.isAccessibilitySize ? min(wordSize, 64) : wordSize, weight: .heavy, design: .rounded))
                    .lineLimit(4).minimumScaleFactor(typeSize.isAccessibilitySize ? 0.35 : 0.5).multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .frame(height: typeSize.isAccessibilitySize ? 120 : 200)
                    .charadesPanel()
                    .accessibilityIdentifier("SecretWord")
            }
            Label(session.playStyle.title, systemImage: session.playStyle.symbol).font(.headline)
                .foregroundStyle(CharadesTheme.accent)
                .accessibilityIdentifier("ReadingPlayStyle")
            Text(session.playStyle.rule).foregroundStyle(CharadesTheme.muted).accessibilityIdentifier("PlayStyleRule")
        case .countdown, .acting, .timeUp:
            EmptyView() // These phases use the measured, non-scrolling clock stage.
        case .paused:
            CharadesHeading(eyebrow: "Loja është në pauzë", title: "Pusho pak.", detail: session.snapshot.resumePhase == .reading
                            ? "Fjala është e fshehtë. Kur të vazhdosh, le ta shohë veç ai që e ka radhën."
                            : "Koha është ndalë. Vazhdo kur të jesh gati.",
                            symbol: clockPaused ? nil : "pause.circle", color: CharadesTheme.action)
        case .result:
            if let outcome = session.lastOutcome {
                resultHeader(outcome)
                scoreBadge
                correction(outcome)
            }
        case .finished:
            CharadesHeading(eyebrow: session.isTournament ? "Turneu përfundoi" : "Sa bukur bashkë!",
                            title: session.isTournament ? winnerTitle : session.score == 1 ? "1 fjalë\ne gjetur." : "\(session.score) fjalë\ntë gjetura.",
                            detail: session.isTournament ? "Krejt lujtën \(session.snapshot.rounds) herë. Çdo fjalë që gjendet vlen 1 pikë." : "\(session.turnIndex) radhë bashkë. Gati për një lojë tjetër?",
                            symbol: "trophy.fill", celebrate: true, color: CharadesTheme.success)
            if session.isTournament { leaderboard(final: true) }
        case .exhausted:
            CharadesHeading(eyebrow: "Fjalët mbaruan", title: "I pamë krejt fjalët.",
                            detail: session.isTournament ? "Turneu mbeti i papërfunduar. Nuk shpallim fitues, sepse nuk u lujtën krejt radhët." : "Fjalët s’përsëriten në të njëjtën lojë. Nise një lojë të re për me lujtë prapë.",
                            symbol: "rectangle.stack")
            if session.isTournament { leaderboard(final: false) }
        }
    }

    @ViewBuilder private var actions: some View {
        switch session.phase {
        case .handoff:
            primary("Shiko fjalën", id: "RevealWord") { session.reveal() }
            if !session.isTournament && session.turnIndex > 0 {
                secondary("Përfundo lojën", id: "FinishTogether") { session.finishTogether() }
            }
        case .reading:
            primary(typeSize.isAccessibilitySize ? "Gati – fshihe" : "Gati – fshihe fjalën", id: "HideWord") { session.ready() }
            secondary(typeSize.isAccessibilitySize ? "Fjalë tjetër" : "Nuk e njeh? Shiko një tjetër", id: "AnotherWord") {
                session.anotherWord()
            }
        case .countdown:
            Text("Loja fillon pas pak").font(.headline).foregroundStyle(CharadesTheme.muted).padding(.vertical, 16)
        case .acting, .timeUp:
            CharadesAnswerStack { response(true); response(false) }
        case .paused:
            primary(session.snapshot.resumePhase == .reading ? "Vazhdo – shiko fjalën" : "Vazhdo lojën", id: "ResumeGame") {
                session.resume()
            }
        case .result:
            if session.isTournament && session.turnIndex < session.totalTurns {
                Text("Radha tjetër: \(session.performer)").font(.footnote).foregroundStyle(CharadesTheme.muted)
            }
            primary(session.isTournament && session.turnIndex == session.totalTurns ? "Shiko rezultatet" : "Radha tjetër", id: "NextTurn") { session.next() }
            if !session.isTournament { secondary("Përfundo lojën", id: "FinishTogether") { session.finishTogether() } }
        case .finished:
            primary("Lujmë prapë", id: "PlayAgain") { replay() }
            secondary("Kthehu në fillim", id: "ReturnHome") { close(true) }
        case .exhausted:
            primary("Kthehu në fillim", id: "ReturnHome") { close(true) }
        }
    }

    private var progress: String {
        session.isTournament ? "Raundi \(session.round) prej \(session.snapshot.rounds)" : "Radha \(session.turnIndex + 1)"
    }
    private var winnerTitle: String {
        let winners = session.standings.filter { $0.rank == 1 }
        return winners.count > 1 ? "Pikë të barabarta!" : "\(winners.first?.name ?? "")\nfiton!"
    }
    /// Category and rule are information, not choices. Framed capsules looked like buttons that
    /// do nothing when pressed, so they are quiet coloured labels.
    private var chips: some View {
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .center, spacing: 8)) : AnyLayout(HStackLayout(spacing: 18))
        return layout {
            chip(session.snapshot.deck.title, symbol: session.snapshot.deck.iconName, color: deckColor)
                .accessibilityIdentifier("SessionCategory")
            chip(session.playStyle.title, symbol: session.playStyle.symbol, color: CharadesTheme.accent)
                .accessibilityIdentifier("SessionPlayStyle")
        }
    }
    private func chip(_ text: String, symbol: String, color: Color) -> some View {
        Label(text, systemImage: symbol).font(.subheadline.bold()).foregroundStyle(color).lineLimit(1)
    }
    /// Only the arc animates; seconds remain crisp and never cross-fade over one another.
    private func ring(diameter: CGFloat, fraction: Double, seconds: Int, color: Color,
                      id: String, label: String) -> some View {
        return ZStack {
            Circle().stroke(session.phase == .timeUp ? color.opacity(0.55) : CharadesTheme.line, lineWidth: 9)
            Circle().trim(from: 0, to: fraction)
                .stroke(color, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .neonGlow(color, radius: 14)
                .animation(reduceMotion ? nil : .linear(duration: 0.1), value: fraction)
            VStack(spacing: 8) {
                Text("\(seconds)").font(.system(size: min(96, diameter * 0.38), weight: .heavy, design: .rounded)).monospacedDigit()
                    .foregroundStyle(color)
                    .transaction { $0.animation = nil }
                    .accessibilityIdentifier(id).accessibilityLabel(label)
                Text(session.phase == .paused ? "në pauzë" : "sekonda")
                    .font(.system(size: max(12, min(16, diameter * 0.065)), weight: .semibold, design: .rounded))
                    .foregroundStyle(CharadesTheme.muted).accessibilityHidden(true)
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .contain).accessibilityIdentifier("ClockRing")
    }
    private func clockRing(diameter: CGFloat) -> some View {
        let phase = session.phase == .paused ? session.snapshot.resumePhase : session.phase
        let total = phase == .countdown ? session.snapshot.countdownDuration : session.snapshot.turnDuration
        let fraction = total > 0 ? min(1, max(0, session.snapshot.remaining / total)) : 0
        let urgent = phase == .timeUp || (phase == .acting && session.seconds <= 10)
        let id = session.phase == .paused ? "PausedTimer" : session.phase == .timeUp ? "TimeUpRing" : "CharadesTimer"
        let label = session.phase == .paused ? "\(session.seconds) sekonda të mbetura" : "\(session.seconds) sekonda"
        return ring(diameter: diameter, fraction: fraction, seconds: session.seconds,
                    color: urgent ? CharadesTheme.failure : CharadesTheme.action, id: id, label: label)
            .scaleEffect(!reduceMotion && session.phase == .acting && urgent && session.seconds.isMultiple(of: 2) ? 1.04 : 1)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: session.seconds)
    }
    private func resultHeader(_ outcome: CharadesSession.Outcome) -> some View {
        let color = outcome.guessed ? CharadesTheme.success : CharadesTheme.failure
        return VStack(spacing: 12) {
            Image(systemName: outcome.guessed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 62, weight: .semibold)).symbolRenderingMode(.palette)
                .foregroundStyle(CharadesTheme.onAccent, color)
                .shadow(color: color.opacity(0.3), radius: 16)
                .symbolEffect(.variableColor.iterative.reversing, options: .repeating,
                              isActive: outcome.guessed && !reduceMotion)
                .accessibilityHidden(true)
            Text(outcome.guessed ? "U gjet!" : "Provojmë tjetrën")
                .font(.system(.title, design: .rounded, weight: .heavy))
                .foregroundStyle(color).multilineTextAlignment(.center)
                .rotationEffect(.degrees(outcome.guessed && !typeSize.isAccessibilitySize ? -3 : 0))
            Text(outcome.word).font(.system(size: min(wordSize, 96), weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center).lineLimit(3).minimumScaleFactor(0.5)
                .foregroundStyle(CharadesTheme.onAccent)
                .padding(.horizontal, 16).padding(.vertical, 26).frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 18).fill(CharadesTheme.card)
                        .shadow(color: CharadesTheme.brand, radius: 0, x: 4, y: 5)
                }
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(CharadesTheme.onAccent, lineWidth: 2))
                .rotationEffect(.degrees(typeSize.isAccessibilitySize ? 0 : 2))
                .padding(.horizontal, 6).padding(.top, 4)
            Text(resultDetail(outcome)).font(.system(.subheadline, design: .rounded, weight: .heavy))
                .foregroundStyle(CharadesTheme.onAccent).multilineTextAlignment(.center)
                .padding(.horizontal, 15).padding(.vertical, 7)
                .background(color, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(CharadesTheme.onAccent, lineWidth: 2))
                .rotationEffect(.degrees(typeSize.isAccessibilitySize ? 0 : -4))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
    /// A quiet, baseline-aligned row keeps the outcome above it as the main information.
    private var scoreBadge: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(session.isTournament ? "Pikët deri tani" : "Fjalë të gjetura deri tani")
                .font(.subheadline.bold()).foregroundStyle(CharadesTheme.muted)
                .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Text("\(resultScore)").font(.system(.title, design: .rounded, weight: .heavy)).monospacedDigit()
                .foregroundStyle(resultScore > 0 ? CharadesTheme.success : CharadesTheme.muted)
        }
        .padding(.vertical, 18).frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine).accessibilityIdentifier("ResultScore")
    }
    private var resultScore: Int {
        guard session.isTournament, let outcome = session.lastOutcome else { return session.score }
        return session.standings.first { $0.id == outcome.performer }?.points ?? 0
    }
    private func correction(_ outcome: CharadesSession.Outcome) -> some View {
        Button { session.correctLastResult() } label: {
            Label(outcome.guessed ? "Shëno Nuk u gjet" : "Shëno U gjet", systemImage: "arrow.uturn.backward")
                .font(.subheadline.bold()).foregroundStyle(outcome.guessed ? CharadesTheme.failure : CharadesTheme.success)
                .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .buttonStyle(.plain).frame(minHeight: 44).frame(maxWidth: .infinity)
        .accessibilityIdentifier("CorrectResult")
        .accessibilityValue(outcome.guessed ? "U gjet" : "Nuk u gjet")
    }
    private func resultDetail(_ outcome: CharadesSession.Outcome) -> String {
        if session.isTournament {
            return "\(session.snapshot.names[outcome.performer]) · \(outcome.guessed ? "+1 pikë" : "0 pikë")"
        }
        return outcome.guessed ? "+1 pikë" : "0 pikë"
    }
    private func leaderboard(final: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(final ? "Rezultatet" : "Pikët deri tani").font(.title2.bold()).accessibilityAddTraits(.isHeader)
            ForEach(session.standings) { standing in
                // At the end the first place glows in mint with a trophy; a tie lights up every leader.
                let winner = final && standing.rank == 1
                let tint = winner ? CharadesTheme.success : CharadesTheme.action
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("\(standing.rank).").foregroundStyle(winner ? tint : CharadesTheme.accent).font(.headline)
                    VStack(alignment: .leading, spacing: 4) {
                        Label {
                            Text(standing.name).font(winner ? .system(.title3, design: .rounded, weight: .heavy) : .headline)
                        } icon: {
                            if winner { Image(systemName: "trophy.fill").foregroundStyle(tint).neonGlow(tint, radius: 5) }
                        }
                        .foregroundStyle(winner ? tint : CharadesTheme.ink)
                        Text("\(standing.turns)/\(session.snapshot.rounds) radhë").font(.caption).foregroundStyle(CharadesTheme.muted)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(standing.points)").font(.system(.title, design: .rounded, weight: .heavy))
                        .foregroundStyle(tint)
                }.accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(standing.name), \(standing.points) pikë, \(standing.turns) prej \(session.snapshot.rounds) radhë, vendi \(standing.rank)")
                    .accessibilityIdentifier("Standing-\(standing.id)")
            }
        }.padding(.vertical, 12)
    }
    private func primary(_ text: String, id: String, color: Color? = nil, action: @escaping () -> Void) -> some View {
        Button(text, action: action).buttonStyle(CharadesButtonStyle(color: color)).accessibilityIdentifier(id)
    }
    private func secondary(_ text: String, id: String, action: @escaping () -> Void) -> some View {
        Button(text, action: action).buttonStyle(CharadesButtonStyle(prominent: false, bare: true)).accessibilityIdentifier(id)
    }
    private func response(_ guessed: Bool) -> some View {
        Button { record(guessed) } label: { CharadesResponseLabel(guessed: guessed) }
            // Only the time-critical answers use a bounded game type scale; reading/help retain Dynamic Type.
            .buttonStyle(CharadesButtonStyle(color: guessed ? CharadesTheme.success : CharadesTheme.failure,
                                             font: .system(size: min(responseSize, 36), weight: .heavy, design: .rounded),
                                             fillsHeight: true, outlined: true))
            .accessibilityIdentifier(guessed ? "Guessed" : "NotGuessed")
    }
    private func record(_ guessed: Bool) {
        session.record(guessed: guessed)
        if sound { audio.playSound(guessed ? "success" : "pass") }
        haptics.playFeedback(guessed ? .success : .pass)
    }
}
