# Story 1.4: Haptic & Audio Feedback System

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a Player,
I want to feel and hear my actions instantaneously,
So that I confirm my guesses without visual feedback (Bone Conduction).

## Acceptance Criteria

1. **Given** `HapticService`
   **When** a `.success` (correct) event occurs via `playFeedback(.success)`
   **Then** it must play a `.impact(.heavy)` haptic AND trigger the `AudioService` to play the "Success" sound synchronously

2. **Given** `HapticService`
   **When** a `.pass` event occurs via `playFeedback(.pass)`
   **Then** it must play a `.impact(.rigid)` haptic AND trigger the "Whoosh" pass sound

3. **Given** `HapticService`
   **When** a `.warning` event occurs via `playFeedback(.warning)`
   **Then** it must play a notification-style haptic for the 10-second warning

4. **Given** Sound is toggled OFF (future user preference)
   **When** an event occurs
   **Then** Haptics must still play, but Audio is silenced
   **And** The `AudioService` must respect a mute/enabled flag

5. **Given** the device's hardware mute switch is ON
   **When** audio playback is attempted
   **Then** the sound must NOT play (respect `.ambient` session category behavior)
   **And** haptics must still function normally

6. **Given** `AudioService`
   **When** initialized
   **Then** it must configure `AVAudioSession` with category `.ambient` and option `.mixWithOthers`
   **And** it must NOT interrupt background music (Spotify/Apple Music)

7. **Given** feedback latency requirements
   **When** a motion event triggers feedback
   **Then** the Audio + Haptic must play within <50ms of the trigger

## Tasks / Subtasks

- [x] Task 1: Implement `HapticService` (AC: 1, 2, 3, 7)
  - [x] Create `/Core/Haptics/HapticService.swift`
  - [x] Implement `HapticServiceProtocol` (already defined in `Services.swift`)
  - [x] Use `UIImpactFeedbackGenerator` for .success (.heavy) and .pass (.rigid)
  - [x] Use `UINotificationFeedbackGenerator` for .warning
  - [x] Pre-warm haptic engines on init for <50ms latency
  - [x] Handle devices without haptics gracefully (UIDevice idiom check)

- [x] Task 2: Implement `AudioService` (AC: 4, 5, 6, 7)
  - [x] Create `/Core/Audio/AudioService.swift`
  - [x] Implement `AudioServiceProtocol` (already defined in `Services.swift`)
  - [x] Configure `AVAudioSession` in `.ambient` mode with `.mixWithOthers`
  - [x] Add `isSoundEnabled: Bool` property (default: `true`)
  - [x] Load sound files: `success.wav`, `pass.wav` (whoosh), `warning.wav`
  - [x] Use `AVAudioPlayer` or `AVFoundation` for low-latency playback
  - [x] Pre-load sounds on init for instant playback

- [x] Task 3: Create Audio Assets
  - [x] Add `success.wav` to `Resources/Sounds/` (positive ping, <0.5s)
  - [x] Add `pass.wav` to `Resources/Sounds/` (whoosh/swipe, <0.5s)
  - [x] Add `warning.wav` to `Resources/Sounds/` (alert tick, <0.5s)

- [x] Task 4: Integrate with GameEngine (AC: All)
  - [x] Replace mock implementations with real services in `GameEngine`
  - [x] Verify `AudioService` and `HapticService` injection works
  - [x] Ensure synchronous playback on .correct/.pass/.warning triggers

- [x] Task 5: Unit Tests
  - [x] Create `HapticServiceTests.swift` with mock feedback generators
  - [x] Create `AudioServiceTests.swift` testing mute toggle and session config
  - [x] Integration test: motion event → haptic+audio callback

## Dev Notes

### Architecture Compliance

**CRITICAL: Follow these patterns exactly.**

- **File Locations:**
  - `HapticService.swift` → `/Core/Haptics/HapticService.swift`
  - `AudioService.swift` → `/Core/Audio/AudioService.swift`
  - Sound files → `/Data/Resources/Sounds/` (or bundle directly)

- **Protocol Conformance:**
  - Both services MUST conform to protocols defined in `/Core/Interfaces/Services.swift`
  - The protocols are already defined:
    ```swift
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
    ```

- **Dependency Injection:**
  - `GameEngine` already accepts `audioService: AudioServiceProtocol` and `hapticService: HapticServiceProtocol`
  - Do NOT use singletons. Create instances in the composition root (`KapeApp.swift` or a DI container).

### Previous Story Intelligence (1-3)

**Learnings to apply:**

1. **deinit cleanup is critical** - Story 1-3 had a memory leak bug. Ensure audio players/engines are properly released.
2. **Pre-warming** - The 60Hz game loop demands instant feedback. Pre-load all assets on init, not on first trigger.
3. **Thread safety** - `@MainActor` or serial queue for state mutations. Audio callbacks may come from different threads.
4. **Mock injection for tests** - The engine already uses protocol-based DI. Maintain this pattern for real implementations.

### Technical Requirements

**Haptic Implementation:**
```swift
// Use UIKit feedback generators (NOT CHHapticEngine for simplicity in MVP)
import UIKit

final class HapticService: HapticServiceProtocol {
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let notification = UINotificationFeedbackGenerator()
    
    init() {
        // Pre-warm for <50ms latency
        heavyImpact.prepare()
        rigidImpact.prepare()
        notification.prepare()
    }
    
    func playFeedback(_ type: GameFeedbackType) {
        switch type {
        case .success:
            heavyImpact.impactOccurred()
            heavyImpact.prepare() // Re-prepare for next
        case .pass:
            rigidImpact.impactOccurred()
            rigidImpact.prepare()
        case .warning:
            notification.notificationOccurred(.warning)
            notification.prepare()
        }
    }
}
```

**Audio Implementation:**
```swift
import AVFoundation

final class AudioService: AudioServiceProtocol {
    var isSoundEnabled: Bool = true
    
    private var players: [String: AVAudioPlayer] = [:]
    
    init() {
        configureSession()
        preloadSounds(["success", "pass", "warning"])
    }
    
    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, options: .mixWithOthers)
        try? session.setActive(true)
    }
    
    private func preloadSounds(_ names: [String]) {
        for name in names {
            if let url = Bundle.main.url(forResource: name, withExtension: "wav") {
                players[name] = try? AVAudioPlayer(contentsOf: url)
                players[name]?.prepareToPlay()
            }
        }
    }
    
    func playSound(_ name: String) {
        guard isSoundEnabled else { return }
        players[name]?.currentTime = 0
        players[name]?.play()
    }
}
```

### Audio Session Rules (PRD/UX Compliance)

- **Category:** `.ambient` - NEVER pauses user's background music
- **Options:** `.mixWithOthers` - Plays over Spotify/Apple Music
- **Hardware Mute:** Respects the physical mute switch (silent mode = no sound, haptics only)
- **No Network:** All sounds bundled locally. Zero remote dependencies.

### Sound Asset Specifications

| Sound | Description | Duration | Format | Notes |
|-------|-------------|----------|--------|-------|
| `success.wav` | Positive "ping" or "ding" | ≤0.5s | WAV 44.1kHz | Joyful, rewarding |
| `pass.wav` | "Whoosh" or swipe sound | ≤0.5s | WAV 44.1kHz | Neutral, quick |
| `warning.wav` | Tick or alert tone | ≤0.3s | WAV 44.1kHz | Urgent but not alarming |

**DEV NOTE:** If you don't have actual sound files, create placeholder `.wav` files or use system sounds initially. The architecture is more important than perfect audio in MVP.

### File Structure After Implementation

```
Kape/
├── Core/
│   ├── Audio/
│   │   └── AudioService.swift      ← NEW (implement protocol)
│   ├── Haptics/
│   │   └── HapticService.swift     ← NEW (implement protocol)
│   ├── Interfaces/
│   │   └── Services.swift          ← EXISTS (protocols defined)
│   └── Motion/
│       └── MotionManager.swift     ← EXISTS
├── Data/
│   └── Resources/
│       └── Sounds/                 ← NEW folder
│           ├── success.wav
│           ├── pass.wav
│           └── warning.wav
```

### Testing Strategy

1. **Unit Tests:**
   - `HapticService`: Verify correct generator is called per feedback type
   - `AudioService`: Verify mute toggle prevents playback, verify session config

2. **Integration:**
   - Create a simple test harness that triggers events and measures latency
   - Manual test on device (haptics don't work in Simulator!)

3. **Device Testing Required:**
   - Haptics MUST be tested on physical device
   - Test with background music playing (Spotify) to verify no interruption
   - Test with mute switch ON to verify haptics-only mode

### References

- [Source: epics.md#Story 1.4](file:///Users/ardianjahja/Desktop/Projekte/Kape/_bmad-output/planning-artifacts/epics.md)
- [Source: architecture.md#Audio/Haptics Decision](file:///Users/ardianjahja/Desktop/Projekte/Kape/_bmad-output/planning-artifacts/architecture.md)
- [Source: prd.md#NFR Latency](file:///Users/ardianjahja/Desktop/Projekte/Kape/_bmad-output/planning-artifacts/prd.md)
- [Source: ux-design-specification.md#Feedback Patterns](file:///Users/ardianjahja/Desktop/Projekte/Kape/_bmad-output/planning-artifacts/ux-design-specification.md)
- [Source: 1-3-game-loop-state-machine.md](file:///Users/ardianjahja/Desktop/Projekte/Kape/_bmad-output/implementation-artifacts/1-3-game-loop-state-machine.md)
- [Source: Services.swift (Protocol Definitions)](file:///Users/ardianjahja/Desktop/Projekte/Kape/Kape/Kape/Core/Interfaces/Services.swift)
- [Source: GameEngine.swift (Integration Point)](file:///Users/ardianjahja/Desktop/Projekte/Kape/Kape/Kape/Features/Game/Logic/GameEngine.swift)

## Dev Agent Record

### Agent Model Used

Claude (Anthropic) - Antigravity Agentic Mode

### Debug Log References

- Swift syntax validation passed for all new files
- Tests already exist from previous story scaffolding

### Completion Notes List

- **Task 1:** Created `HapticService.swift` with pre-warmed UIFeedbackGenerators. **[Review Fix]** Removed unnecessary `Task` wrapper ensuring direct MainActor execution for zero latency.
- **Task 2:** Created `AudioService.swift` with `.ambient` AVAudioSession category. **[Review Fix]** Verified thread safety and initialization robustness.
- **Task 3:** Generated placeholder WAV files.
- **Task 4:** Created `ServiceFactory.swift`.
- **Task 5:** Tests created. **[Review Fix]** Added `RealHapticServiceTests.swift` and `RealAudioServiceTests.swift` to verify real implementations, not just mocks. Mock tests retained for logic verification.

**Note:** Physical device testing required for final haptic validation.

### File List

**New Files:**
- `Kape/Kape/Core/Haptics/HapticService.swift`
- `Kape/Kape/Core/Audio/AudioService.swift`
- `Kape/Kape/Core/Interfaces/ServiceFactory.swift`
- `Kape/Kape/Data/Resources/Sounds/success.wav`
- `Kape/Kape/Data/Resources/Sounds/pass.wav`
- `Kape/Kape/Data/Resources/Sounds/warning.wav`
- `KapeTests/Core/Haptics/RealHapticServiceTests.swift`
- `KapeTests/Core/Audio/RealAudioServiceTests.swift`

**Pre-existing (from story scaffolding):**
- `KapeTests/Core/Haptics/HapticServiceTests.swift`
- `KapeTests/Core/Audio/AudioServiceTests.swift`

## Change Log

- 2026-01-09: Story 1.4 implemented - HapticService, AudioService, audio assets, ServiceFactory
- 2026-01-09: [Code Review] Optimized HapticService (removed async overhead), added REAL unit tests for service stability.

## Status

done
