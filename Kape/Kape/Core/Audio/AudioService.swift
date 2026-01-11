import AVFoundation

/// AudioService implementation for playing game sounds.
/// Conforms to `AudioServiceProtocol` for dependency injection.
///
/// Configures AVAudioSession with `.ambient` category to:
/// - Respect the hardware mute switch (AC: 5)
/// - Mix with background music like Spotify/Apple Music (AC: 6)
/// - Pre-load sounds for <50ms latency (AC: 7)
final class AudioService: AudioServiceProtocol {
    
    // MARK: - Properties
    
    /// Toggle to enable/disable sound playback (AC: 4)
    /// When false, haptics still play but audio is silenced.
    var isSoundEnabled: Bool = true
    
    /// Pre-loaded audio players for instant playback
    private var players: [String: AVAudioPlayer] = [:]
    
    /// Sound file extension
    private let soundFileExtension = "wav"
    
    // MARK: - Initialization
    
    init() {
        configureAudioSession()
        preloadSounds(["success", "pass", "warning"])
    }
    
    // MARK: - Private Methods
    
    /// Configures AVAudioSession with ambient category (AC: 5, 6)
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            // .ambient: Respects mute switch, allows background audio
            // .mixWithOthers: Doesn't interrupt Spotify/Apple Music
            try session.setCategory(.ambient, options: .mixWithOthers)
            try session.setActive(true)
        } catch {
            print("[AudioService] Failed to configure audio session: \(error)")
        }
    }
    
    /// Pre-loads sound files for instant playback (AC: 7)
    private func preloadSounds(_ names: [String]) {
        for name in names {
            guard let url = Bundle.main.url(forResource: name, withExtension: soundFileExtension) else {
                print("[AudioService] Sound file not found: \(name).\(soundFileExtension)")
                continue
            }
            
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                players[name] = player
            } catch {
                print("[AudioService] Failed to load sound '\(name)': \(error)")
            }
        }
    }
    
    // MARK: - AudioServiceProtocol
    
    func playSound(_ name: String) {
        // AC: 4 - Respect mute toggle
        guard isSoundEnabled else { return }
        
        guard let player = players[name] else {
            print("[AudioService] No player for sound: \(name)")
            return
        }
        
        // Reset to start and play
        player.currentTime = 0
        player.play()
    }
}
