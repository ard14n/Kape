import SwiftUI

struct CharadesPlayView: View {
    @Bindable var session: CharadesSession
    @ObservedObject var store: StoreViewModel
    var close: (_ discard: Bool) -> Void
    @AppStorage("kape.sound") private var sound = true
    @State private var confirmExit = false
    @State private var audio = ServiceFactory.makeAudioService()
    @State private var haptics = ServiceFactory.makeHapticService()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        NavigationStack {
            CharadesPage {
                content
                if session.accessDenied {
                    Text("Kjo kategori kërkon VIP. Mund ta fshini këtë lojë nga «Dalje» dhe të zgjidhni një kategori falas, ose ta ruani dhe të riktheni blerjet te Cilësimet.")
                        .foregroundStyle(CharadesTheme.accent).charadesPanel().accessibilityIdentifier("AccessDenied")
                }
            }
            .id(session.phase)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 10) { actions }
                    .frame(maxWidth: 560).padding(.horizontal, 24).padding(.vertical, 14)
                    .frame(maxWidth: .infinity).background(CharadesTheme.background)
            }
            .navigationTitle(session.isTournament ? "Turne" : "Kape!")
            .navigationBarTitleDisplayMode(.inline)
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
            .confirmationDialog("Dëshironi të dilni?", isPresented: $confirmExit, titleVisibility: .visible) {
                Button("Ruaje dhe dil") { close(false) }
                Button("Fshije lojën", role: .destructive) { close(true) }
                Button("Qëndro këtu", role: .cancel) {}
            } message: {
                Text("Mund ta ruani lojën për më vonë ose ta fshini dhe të filloni nga e para.")
            }
        }
        .tint(CharadesTheme.accent)
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
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { session.pause(); UIApplication.shared.isIdleTimerDisabled = false }
        }
        .onDisappear {
            session.pause()
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    @ViewBuilder private var content: some View {
        switch session.phase {
        case .handoff:
            CharadesHeading(eyebrow: progress, title: session.isTournament ? "Radha e\n\(session.performer)" : "Kush e ka radhën?",
                            detail: "Kalojani telefonin personit që do të luajë me gjeste. Vetëm ai person duhet ta shohë fjalën.",
                            symbol: "iphone.and.arrow.forward")
            Label(session.snapshot.deck.title, systemImage: session.snapshot.deck.iconName)
                .font(.headline).charadesPanel()
            if session.isTournament {
                Text("Nëse grupi e gjen fjalën, \(session.performer) merr 1 pikë.").foregroundStyle(CharadesTheme.muted)
            } else if session.turnIndex > 0 {
                Text("\(session.score) fjalë të gjetura deri tani").font(.headline).foregroundStyle(CharadesTheme.accent)
            }
        case .reading:
            if typeSize.isAccessibilitySize {
                Text("Vetëm për ty").font(.headline).foregroundStyle(CharadesTheme.accent).accessibilityAddTraits(.isHeader)
            } else {
                CharadesHeading(eyebrow: "Vetëm për ty", title: "Lexoje fshehurazi.",
                                detail: "Sapo të jesh gati, fjala do të fshihet.")
            }
            if let word = session.visibleWord {
                Text(word).font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center).padding(.vertical, 26).charadesPanel()
                    .accessibilityIdentifier("SecretWord")
            }
            Text("Mos e thuaj me zë. Paraqite me gjeste, pa folur.").foregroundStyle(CharadesTheme.muted)
        case .countdown:
            CharadesHeading(eyebrow: "Fjala u fsheh", title: typeSize.isAccessibilitySize ? "Lëre telefonin." : "Lëre telefonin\nmbi tavolinë.",
                            detail: typeSize.isAccessibilitySize ? "" : "Bëhu gati të luash me gjeste.", symbol: typeSize.isAccessibilitySize ? nil : "hand.raised.slash")
            timer
        case .acting:
            CharadesHeading(eyebrow: typeSize.isAccessibilitySize ? "Pa folur" : "Pa folur · vetëm me gjeste",
                            title: typeSize.isAccessibilitySize ? "Luaj me gjeste." : "Tani radha\nështë e jotja.",
                            detail: typeSize.isAccessibilitySize ? "" : "Grupi përpiqet të gjejë fjalën.")
            timer
            if !typeSize.isAccessibilitySize {
                Text("Shtypni «U gjet» sapo ta gjejë grupi.").foregroundStyle(CharadesTheme.muted)
            }
        case .paused:
            CharadesHeading(eyebrow: "Loja është në pauzë", title: "Merrni një çast.", detail: session.snapshot.resumePhase == .reading
                            ? "Fjala është fshehur. Vetëm personi që luan duhet ta shohë kur të vazhdoni."
                            : "Koha është ndalur. Vazhdoni kur të jeni gati.", symbol: "pause.circle")
            if [.acting, .countdown].contains(session.snapshot.resumePhase) {
                Text("\(session.seconds) sekonda të mbetura").font(.title2.bold()).charadesPanel()
            }
        case .timeUp:
            CharadesHeading(eyebrow: "Koha mbaroi", title: "A u gjet fjala\nbrenda kohës?",
                            detail: "Shënoni vetëm rezultatin e kësaj radhe.", symbol: "timer")
        case .result:
            if let outcome = session.lastOutcome {
                CharadesHeading(eyebrow: outcome.guessed ? "U gjet!" : "Provojmë tjetrën", title: outcome.word,
                                detail: resultDetail(outcome), symbol: outcome.guessed ? "checkmark.circle" : "arrow.right.circle")
                Button(outcome.guessed ? "Shëno «Nuk u gjet»" : "Shëno «U gjet»") { session.correctLastResult() }
                    .frame(minHeight: 44).accessibilityIdentifier("CorrectResult")
                    .accessibilityValue(outcome.guessed ? "U gjet" : "Nuk u gjet")
                if session.isTournament { leaderboard(final: false) }
            }
        case .finished:
            CharadesHeading(eyebrow: session.isTournament ? "Turneu përfundoi" : "Sa bukur së bashku!",
                            title: session.isTournament ? winnerTitle : "\(session.score) fjalë\ntë gjetura.",
                            detail: session.isTournament ? "Të gjithë luajtën \(session.snapshot.rounds) herë. Çdo fjalë e gjetur vlen 1 pikë." : "\(session.turnIndex) radhë, shumë gjeste. Gati për një lojë tjetër?",
                            symbol: "hands.clap")
            if session.isTournament { leaderboard(final: true) }
        case .exhausted:
            CharadesHeading(eyebrow: "Kategoria mbaroi", title: "I pamë të gjitha fjalët.",
                            detail: session.isTournament ? "Turneu mbeti i papërfunduar. Nuk shpallim fitues, sepse nuk u luajtën të gjitha radhët." : "Nuk përsërisim fjalë brenda së njëjtës lojë. Zgjidhni një kategori tjetër për të vazhduar me një lojë të re.",
                            symbol: "rectangle.stack")
            if session.isTournament { leaderboard(final: false) }
        }
    }

    @ViewBuilder private var actions: some View {
        switch session.phase {
        case .handoff:
            primary("Shiko fjalën", id: "RevealWord") { session.reveal(vip: store.isVIPUnlocked) }
            if !session.isTournament && session.turnIndex > 0 {
                secondary("Përfundo lojën", id: "FinishTogether") { session.finishTogether() }
            }
        case .reading:
            primary("Gati – fshihe fjalën", id: "HideWord") { session.ready() }
            secondary(typeSize.isAccessibilitySize ? "Fjalë tjetër" : "Nuk e njeh? Shiko një tjetër", id: "AnotherWord") {
                session.anotherWord(vip: store.isVIPUnlocked)
            }
        case .countdown:
            Text("Loja fillon pas pak").font(.headline).foregroundStyle(CharadesTheme.muted).padding(.vertical, 16)
        case .acting, .timeUp:
            primary("U gjet", id: "Guessed") { record(true) }
            secondary("Nuk u gjet", id: "NotGuessed") { record(false) }
        case .paused:
            primary(session.snapshot.resumePhase == .reading ? "Vazhdo – shiko fjalën" : "Vazhdo lojën", id: "ResumeGame") {
                session.resume(vip: store.isVIPUnlocked)
            }
        case .result:
            primary(session.isTournament && session.turnIndex == session.totalTurns ? "Shiko rezultatet" : "Radha tjetër", id: "NextTurn") { session.next() }
            if !session.isTournament { secondary("Përfundo lojën", id: "FinishTogether") { session.finishTogether() } }
        case .finished, .exhausted:
            primary("Kthehu në fillim", id: "ReturnHome") { close(true) }
        }
    }

    private var progress: String {
        session.isTournament ? "Raundi \(session.round) nga \(session.snapshot.rounds)" : "Radha \(session.turnIndex + 1)"
    }
    private var winnerTitle: String {
        let winners = session.standings.filter { $0.rank == 1 }
        return winners.count > 1 ? "Pikë të barabarta!" : "\(winners.first?.name ?? "")\nfiton!"
    }
    private var timer: some View {
        VStack(spacing: 4) {
            Text("\(session.seconds)").font(.system(size: 80, weight: .bold, design: .rounded)).monospacedDigit()
                .foregroundStyle(CharadesTheme.accent).accessibilityIdentifier("CharadesTimer")
                .accessibilityLabel("\(session.seconds) sekonda")
            Text("sekonda").font(.headline).foregroundStyle(CharadesTheme.muted)
        }.frame(maxWidth: .infinity).padding(.vertical, 12).charadesPanel()
    }
    private func resultDetail(_ outcome: CharadesSession.Outcome) -> String {
        if session.isTournament {
            return "\(session.snapshot.names[outcome.performer]): \(outcome.guessed ? "+1 pikë" : "0 pikë"). Mund ta ndryshoni rezultatin para radhës tjetër."
        }
        return "\(session.score) fjalë të gjetura nga grupi. Kalojani telefonin personit tjetër."
    }
    private func leaderboard(final: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(final ? "Rezultatet" : "Pikët deri tani").font(.title2.bold()).accessibilityAddTraits(.isHeader)
            ForEach(session.standings) { standing in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("\(standing.rank).").foregroundStyle(CharadesTheme.accent).font(.headline)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(standing.name).font(.headline)
                        Text("\(standing.turns)/\(session.snapshot.rounds) radhë").font(.caption).foregroundStyle(CharadesTheme.muted)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(standing.points)").font(.system(.title2, design: .rounded, weight: .bold))
                }.accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(standing.name), \(standing.points) pikë, \(standing.turns) nga \(session.snapshot.rounds) radhë, vendi \(standing.rank)")
                    .accessibilityIdentifier("Standing-\(standing.id)")
            }
        }.charadesPanel()
    }
    private func primary(_ text: String, id: String, action: @escaping () -> Void) -> some View {
        Button(text, action: action).buttonStyle(CharadesButtonStyle()).accessibilityIdentifier(id)
    }
    private func secondary(_ text: String, id: String, action: @escaping () -> Void) -> some View {
        Button(text, action: action).buttonStyle(CharadesButtonStyle(prominent: false)).accessibilityIdentifier(id)
    }
    private func record(_ guessed: Bool) {
        session.record(guessed: guessed)
        if sound { audio.playSound(guessed ? "success" : "pass") }
        haptics.playFeedback(guessed ? .success : .pass)
    }
}
