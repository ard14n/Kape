import Foundation

class TournamentPersistenceService {
    static let shared = TournamentPersistenceService()
    
    private let fileName = "current_tournament.json"
    
    private var fileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName)
    }
    
    /// Persist a snapshot of the tournament state to disk.
    func save(state: TournamentState) {
        guard let url = fileURL else { return }
        do {
            let snapshot = TournamentSnapshot(from: state)
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: url, options: .atomic)
            print("✅ Tournament state saved successfully.")
        } catch {
            print("❌ ERROR saving tournament state: \(error.localizedDescription)")
        }
    }

    /// Load a saved snapshot from disk (if available).
    func loadSnapshot() -> TournamentSnapshot? {
        guard let url = fileURL, FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let snapshot = try JSONDecoder().decode(TournamentSnapshot.self, from: data)
            print("✅ Tournament state loaded successfully.")
            return snapshot
        } catch {
            print("❌ ERROR loading tournament state: \(error.localizedDescription)")
            return nil
        }
    }

    /// Convenience to return decoded TournamentState directly.
    func loadState() -> TournamentState? {
        loadSnapshot()?.toState()
    }

    /// Remove any persisted tournament state from disk.
    func clear() {
        guard let url = fileURL else { return }
        try? FileManager.default.removeItem(at: url)
    }

    /// Whether a persisted tournament file currently exists on disk.
    var hasPersistedState: Bool {
        guard let url = fileURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
}
