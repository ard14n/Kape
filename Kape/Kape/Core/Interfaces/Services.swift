import Foundation

protocol AudioServiceProtocol: Sendable {
    func playSound(_ name: String)
}

protocol HapticServiceProtocol: Sendable {
    func playFeedback(_ type: GameFeedbackType)
}

enum GameFeedbackType: Sendable {
    case success
    case pass
    case warning
}
