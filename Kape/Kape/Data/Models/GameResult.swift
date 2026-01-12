import Foundation
import SwiftUI

/// Represents the result of a completed game session
struct GameResult: Equatable, Identifiable {
    let id = UUID()
    let score: Int
    let passed: Int
    let date: Date
    
    /// Total cards attempted (correct + passed)
    var total: Int {
        score + passed
    }
    
    /// Accuracy percentage (score / total), guarded against divide-by-zero
    var accuracy: Double {
        total > 0 ? Double(score) / Double(total) : 0.0
    }
    
    /// Computed rank based on score
    var rank: Rank {
        Rank.from(score: score)
    }
    
    /// Factory method to create GameResult from a GameRound
    static func from(_ round: GameRound) -> GameResult {
        GameResult(
            score: round.score,
            passed: round.passed,
            date: Date()
        )
    }
    
    /// Custom Equatable to exclude `id` from comparison (value-based equality)
    static func == (lhs: GameResult, rhs: GameResult) -> Bool {
        lhs.score == rhs.score &&
        lhs.passed == rhs.passed &&
        lhs.date == rhs.date
    }
}

/// Rank categorization based on game score
enum Rank: Equatable {
    case mishIHuaj  // 0-4 points
    case shqipe     // 5-9 points
    case legjende   // 10+ points
    
    /// Localized title for the rank
    var title: String {
        switch self {
        case .mishIHuaj: return "Turist"
        case .shqipe: return "Shqipe"
        case .legjende: return "Legjendë"
        }
    }
    
    /// Design system color for the rank
    var color: Color {
        switch self {
        case .mishIHuaj: return .white.opacity(0.6)
        case .shqipe: return .neonOrange
        case .legjende: return .neonGreen
        }
    }
    
    /// Determines rank from score using story-defined boundaries
    static func from(score: Int) -> Rank {
        switch score {
        case ..<5:  // 0-4 (and any negative - defensive)
            return .mishIHuaj
        case 5...9:
            return .shqipe
        default:  // 10+
            return .legjende
        }
    }
}
