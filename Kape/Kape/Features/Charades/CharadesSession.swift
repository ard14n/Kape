import Foundation
import Observation

/// One word, one performer and at most one result per turn. No motion input.
@MainActor @Observable
final class CharadesSession: Identifiable {
    enum Mode: String, Codable { case together, tournament }
    enum Phase: String, Codable {
        case handoff, reading, countdown, acting, paused, timeUp, result, finished, exhausted
    }
    struct Outcome: Codable, Equatable, Identifiable {
        let id: UUID
        let turn: Int
        let performer: Int
        let word: String
        var guessed: Bool
    }
    struct Snapshot: Codable {
        var version = 1
        var id = UUID()
        var mode: Mode
        var names: [String]
        var rounds: Int
        var deck: Deck
        var pool: [Card]
        var current: Card?
        var outcomes: [Outcome] = []
        var phase: Phase = .handoff
        var resumePhase: Phase = .reading
        var remaining: TimeInterval = 60
        var turnDuration: TimeInterval = 60
        var countdownDuration: TimeInterval = 3
    }

    private(set) var snapshot: Snapshot
    private(set) var accessDenied = false
    @ObservationIgnored private var deadline: TimeInterval?
    @ObservationIgnored private let now: () -> TimeInterval
    @ObservationIgnored var save: (Snapshot) -> Void = { _ in }

    var id: UUID { snapshot.id }
    var phase: Phase { snapshot.phase }
    var isClockRunning: Bool { phase == .countdown || phase == .acting }
    var isTournament: Bool { snapshot.mode == .tournament }
    var turnIndex: Int { snapshot.outcomes.count }
    var performerIndex: Int { turnIndex % snapshot.names.count }
    var performer: String { isTournament ? snapshot.names[performerIndex] : "Personi që do të luajë" }
    var round: Int { min(snapshot.rounds, turnIndex / snapshot.names.count + 1) }
    var totalTurns: Int { snapshot.names.count * snapshot.rounds }
    var seconds: Int { max(0, Int(ceil(snapshot.remaining))) }
    var score: Int { snapshot.outcomes.filter(\.guessed).count }
    var visibleWord: String? { phase == .reading ? snapshot.current?.text : nil }
    var lastOutcome: Outcome? { snapshot.outcomes.last }
    var isComplete: Bool { !isTournament || turnIndex == totalTurns }

    struct Standing: Identifiable {
        let id: Int
        let name: String
        let points: Int
        let turns: Int
        let rank: Int
    }
    var standings: [Standing] {
        let scores = snapshot.names.indices.map { index in
            snapshot.outcomes.filter { $0.performer == index && $0.guessed }.count
        }
        return snapshot.names.indices.map { index in
            Standing(id: index, name: snapshot.names[index], points: scores[index],
                     turns: snapshot.outcomes.filter { $0.performer == index }.count,
                     rank: 1 + scores.filter { $0 > scores[index] }.count)
        }.sorted { $0.points == $1.points ? $0.id < $1.id : $0.points > $1.points }
    }

    init(mode: Mode, names: [String] = ["Së bashku"], rounds: Int = 3, deck: Deck,
         shuffled: Bool = true, turnDuration: TimeInterval = 60, countdownDuration: TimeInterval = 3,
         now: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }) {
        let players = mode == .tournament ? names.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } : ["Së bashku"]
        precondition(Self.validNames(players, tournament: mode == .tournament))
        precondition([1, 3, 5].contains(rounds))
        snapshot = Snapshot(mode: mode, names: players, rounds: rounds, deck: deck,
                            pool: shuffled ? deck.cards.shuffled() : deck.cards,
                            remaining: turnDuration, turnDuration: turnDuration,
                            countdownDuration: countdownDuration)
        self.now = now
    }

    init?(restoring state: Snapshot, now: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }) {
        guard state.version == 1, Self.validNames(state.names, tournament: state.mode == .tournament),
              [1, 3, 5].contains(state.rounds),
              state.turnDuration > 0, state.turnDuration <= 60,
              state.countdownDuration >= 0, state.countdownDuration <= 3,
              state.remaining.isFinite, state.remaining >= 0, state.remaining <= 60,
              Set(state.pool.map(\.id)).count == state.pool.count,
              Set(state.outcomes.map(\.id)).count == state.outcomes.count,
              state.outcomes.enumerated().allSatisfy({ $0.offset == $0.element.turn && $0.element.performer == $0.offset % state.names.count }),
              state.mode != .tournament || state.outcomes.count <= state.names.count * state.rounds,
              ![Phase.reading, .countdown, .acting, .timeUp, .result, .paused].contains(state.phase) || state.current != nil,
              state.phase != .result || !state.outcomes.isEmpty,
              state.phase != .finished || state.mode != .tournament || state.outcomes.count == state.names.count * state.rounds,
              state.phase != .paused || [.reading, .countdown, .acting, .timeUp, .result].contains(state.resumePhase)
        else { return nil }
        snapshot = state
        self.now = now
        // A restored word is always behind an explicit privacy/resume gate.
        if [.reading, .countdown, .acting, .timeUp, .result].contains(state.phase) {
            snapshot.resumePhase = state.phase
            snapshot.phase = .paused
        }
    }

    nonisolated deinit {}

    static func validNames(_ names: [String], tournament: Bool = true) -> Bool {
        let trimmed = names.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        return (tournament ? (2...5).contains(names.count) : names.count == 1)
            && trimmed.allSatisfy { !$0.isEmpty && $0.count <= 24 }
            && Set(trimmed.map { $0.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "sq")) }).count == trimmed.count
    }

    func reveal(vip: Bool) {
        guard phase == .handoff else { return }
        guard !snapshot.deck.isPro || vip else { accessDenied = true; return }
        accessDenied = false
        draw()
    }

    func anotherWord(vip: Bool) {
        guard phase == .reading else { return }
        guard !snapshot.deck.isPro || vip else { accessDenied = true; pause(); return }
        draw()
    }

    private func draw() {
        guard !snapshot.pool.isEmpty else {
            snapshot.current = nil
            snapshot.phase = .exhausted
            changed()
            return
        }
        snapshot.current = snapshot.pool.removeFirst()
        snapshot.remaining = snapshot.turnDuration
        snapshot.phase = .reading
        changed()
    }

    func ready() {
        guard phase == .reading, snapshot.current != nil else { return }
        snapshot.phase = .countdown
        snapshot.remaining = snapshot.countdownDuration
        deadline = now() + snapshot.countdownDuration
        tick()
        changed()
    }

    /// A single view-owned, cancellable task calls tick. The monotonic deadline avoids drift.
    func tick() {
        guard isClockRunning, let end = deadline else { return }
        snapshot.remaining = max(0, end - now())
        guard snapshot.remaining == 0 else { return }
        if phase == .countdown {
            snapshot.phase = .acting
            snapshot.remaining = snapshot.turnDuration
            deadline = now() + snapshot.turnDuration
        } else {
            snapshot.phase = .timeUp
            deadline = nil
        }
        changed()
    }

    func pause() {
        tick()
        guard [.reading, .countdown, .acting, .timeUp, .result].contains(phase) else { return }
        snapshot.resumePhase = phase
        snapshot.phase = .paused
        deadline = nil
        changed()
    }

    func resume(vip: Bool) {
        guard phase == .paused else { return }
        // A paid word already being performed may be judged. Re-reading requires current access.
        guard snapshot.resumePhase != .reading || !snapshot.deck.isPro || vip else {
            accessDenied = true
            return
        }
        accessDenied = false
        snapshot.phase = snapshot.resumePhase
        if isClockRunning { deadline = now() + snapshot.remaining }
        changed()
    }

    func record(guessed: Bool) {
        tick()
        guard [.acting, .timeUp].contains(phase), let card = snapshot.current else { return }
        let outcome = Outcome(id: UUID(), turn: turnIndex, performer: performerIndex, word: card.text, guessed: guessed)
        snapshot.outcomes.append(outcome)
        snapshot.phase = .result
        deadline = nil
        changed()
    }

    func correctLastResult() {
        guard phase == .result, !snapshot.outcomes.isEmpty else { return }
        snapshot.outcomes[snapshot.outcomes.count - 1].guessed.toggle()
        changed()
    }

    func next() {
        guard phase == .result else { return }
        snapshot.current = nil
        snapshot.phase = isTournament && turnIndex == totalTurns ? .finished : .handoff
        snapshot.remaining = snapshot.turnDuration
        changed()
    }

    func finishTogether() {
        guard !isTournament, [.result, .handoff, .exhausted].contains(phase) else { return }
        snapshot.current = nil
        snapshot.phase = .finished
        changed()
    }

    private func changed() { save(snapshot) }
}

@MainActor
enum CharadesArchive {
    static let key = "kape.charades.session.v1"
    static func save(_ state: CharadesSession.Snapshot, defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: key)
    }
    static func load(defaults: UserDefaults = .standard) -> CharadesSession? {
        guard let data = defaults.data(forKey: key),
              let state = try? JSONDecoder().decode(CharadesSession.Snapshot.self, from: data) else { return nil }
        return CharadesSession(restoring: state)
    }
    static func clear(defaults: UserDefaults = .standard) { defaults.removeObject(forKey: key) }
}
