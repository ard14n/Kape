import Foundation

/// Snapshot used for persisting tournament state safely with primitive values only.
struct TournamentSnapshot: Codable {
    let players: [PlayerSnapshot]
    let roundsPerPlayer: Int
    let currentRound: Int
    let currentPlayerIndex: Int
    let phase: String

    init(from state: TournamentState) {
        self.players = state.players.map { PlayerSnapshot(from: $0) }
        self.roundsPerPlayer = state.roundsPerPlayer
        self.currentRound = state.currentRound
        self.currentPlayerIndex = state.currentPlayerIndex
        self.phase = state.phase.rawValue
    }

    func toState() -> TournamentState {
        let players = self.players.map { $0.toPlayer() }
        let phase = TournamentPhase(rawValue: self.phase) ?? .setup

        return TournamentState(
            players: players,
            roundsPerPlayer: self.roundsPerPlayer,
            currentRound: self.currentRound,
            currentPlayerIndex: self.currentPlayerIndex,
            phase: phase
        )
    }
}

struct PlayerSnapshot: Codable {
    let id: String
    let name: String
    let score: Int
    let sessionHistory: [SessionResultSnapshot]

    init(from player: Player) {
        self.id = player.id.uuidString
        self.name = player.name
        self.score = player.score
        self.sessionHistory = player.sessionHistory.map { SessionResultSnapshot(from: $0) }
    }

    func toPlayer() -> Player {
        let uuid = UUID(uuidString: self.id) ?? UUID()
        var player = Player(id: uuid, name: self.name)
        player.score = self.score
        player.sessionHistory = self.sessionHistory.map { $0.toSessionResult() }
        return player
    }
}

struct SessionResultSnapshot: Codable {
    let id: String
    let correctCount: Int
    let passCount: Int
    let incorrectCount: Int
    let timestamp: Double

    init(from result: SessionResult) {
        self.id = result.id.uuidString
        self.correctCount = result.correctCount
        self.passCount = result.passCount
        self.incorrectCount = result.incorrectCount
        self.timestamp = result.timestamp.timeIntervalSince1970
    }

    func toSessionResult() -> SessionResult {
        let uuid = UUID(uuidString: self.id) ?? UUID()
        let date = Date(timeIntervalSince1970: self.timestamp)
        return SessionResult(
            id: uuid,
            correctCount: self.correctCount,
            passCount: self.passCount,
            incorrectCount: self.incorrectCount,
            timestamp: date
        )
    }
}
