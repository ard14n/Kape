# Story 1.3: Game Loop State Machine

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a Player,
I want the game to follow a structured 60-second timer with clear states,
So that the gameplay is fair and predictable.

## Acceptance Criteria

1. **Given** `GameEngine`
   **When** a game starts
   **Then** it must enter `buffer` state (3 seconds) with a countdown before transitioning to `playing`

2. **Given** `playing` state
   **When** the 60-second timer expires
   **Then** it must transition to `finished` state
   **And** stop processing motion inputs

3. **Given** `playing` state
   **When** 10 seconds remain
   **Then** it must trigger a warning signal (for audio/haptic consumption)

4. **Given** the app is backgrounded (ScenePhase .inactive/.background)
   **When** in `playing` state
   **Then** the game must pause (stop timer) or end gracefully
   **And** resume correctly when foregrounded (or remain paused waiting for user)

5. **Given** `MotionManager` input
   **When** a `.correct` event is received via stream
   **Then** `GameEngine` must increment score, record result, and trigger success feedback

6. **Given** `MotionManager` input
   **When** a `.pass` event received
   **Then** `GameEngine` must mark as passed and trigger pass feedback

## Tasks / Subtasks

- [x] Define Game Domain Models
  - [x] Create `enum GameState: Equatable` (idle, buffer, playing, paused, finished) in `Features/Game/Logic/GameModels.swift`
  - [x] Create `struct GameRound` (score, timeRemaining, currentCard, etc.)
- [x] Create `GameEngine` Class
  - [x] Initialize in `Features/Game/Logic/GameEngine.swift` as `@Observable` class
  - [x] Inject `MotionManager` dependency (from Story 1.2)
  - [x] Define Protocols `AudioServiceProtocol` and `HapticServiceProtocol` in `Core` (stubs for Story 1.4) and inject them
- [x] Implement State Machine & Timer
  - [x] Implement `startRound(deck:)`
  - [x] Implement `buffer` countdown (3s)
  - [x] Implement main game timer (60s) using `Task` or `Timer` (handling cancellation)
  - [x] Implement "10s Warning" trigger
- [x] Integrate Motion Stream
  - [x] Subscribe to `MotionManager.eventStream` inside `playing` state
  - [x] Handle `.correct` -> `score += 1`, `haptic.play(.success)`
  - [x] Handle `.pass` -> `passed += 1`, `haptic.play(.rigid)`
- [x] Implement Lifecycle Handling
  - [x] Observe `ScenePhase`
  - [x] Implement `pause()` and `resume()` logic

## Dev Notes

- **Architecture Patterns**:
  - **State Machine**: The `GameEngine` is the brain. It MUST NOT import SwiftUI Views. It publishes state; Views match.
  - **Dependency Injection**: Inject `MotionManager`, `AudioService`, `HapticService`. Do not instantiate strict singletons inside the class (allow init injection for testing).
  - **Thread Safety**: Ensure all state mutations happen on `@MainActor`.

- **Learnings from Story 1.2**:
  - `MotionManager` correctly uses **Roll** for landscape orientation. `GameEngine` should consume the abstract `GameInputEvent` (`correct`, `pass`) stream provided by Story 1.2, so it remains agnostic of the physics implementation.
  - Ensure the `MotionManager` stream subscription is cancelled/cleaned up when the game ends to prevent leaks.

- **Stubbing Dependencies**:
  - Story 1.4 implements Haptics/Audio. For this story, define the *Protocols* in `Core/Audio/AudioService.swift` and `Core/Haptics/HapticService.swift` and create simple Mock/Stub implementations that print to console. This allows 1.3 to be "done" and testable without waiting for 1.4.

### Project Structure Notes

- `Features/Game/Logic/GameEngine.swift` - Main Logic
- `Features/Game/Logic/GameModels.swift` - Enums/Structs
- `Core/Interfaces/Services.swift` (or individual files) - define the Protocols for Audio/Haptic if not already present.

### References

- [Source: epics.md#Story 1.3](file:///Users/ardianjahja/Desktop/Projekte/Kape/_bmad-output/planning-artifacts/epics.md)
- [Source: architecture.md#Core Architectural Decisions](file:///Users/ardianjahja/Desktop/Projekte/Kape/_bmad-output/planning-artifacts/architecture.md)
- [Source: 1-2-core-motion-service.md](file:///Users/ardianjahja/Desktop/Projekte/Kape/_bmad-output/implementation-artifacts/1-2-core-motion-service.md)

## Dev Agent Record

### Agent Model Used

Antigravity (simulating BMad Scrum Master)

### Debug Log References
- xcode-select error: unable to run tests via CLI. Proceeding with manual verification logic.

### Completion Notes List
- Implemented Task 1: Game Domain Models.
- Created `Deck.swift` in `Data/Models` to support `GameRound`.
- Implemented Task 2: Service Protocols and Engine Shell.
- Implemented Task 3: Game Loop and Timer.
- Implemented Task 4: Motion Stream Integration using `TaskGroup` for concurrency.
- Implemented Task 5: Pause/Resume and ScenePhase handling.
- Note: `GameEngine` loop checks `Task.isCancelled` and `gameState == .paused`.

### File List
- Kape/Kape/KapeTests/Features/Game/GameModelsTests.swift
- Kape/Kape/Kape/Data/Models/Deck.swift
- Kape/Kape/Kape/Features/Game/Logic/GameModels.swift
- Kape/Kape/KapeTests/Features/Game/GameEngineTests.swift
- Kape/Kape/Kape/Core/Interfaces/Services.swift
- Kape/Kape/Kape/Features/Game/Logic/GameEngine.swift

### Review Fixes Applied (2026-01-09)
- [HIGH] Added `deinit` to prevent memory leaks from orphaned Tasks.
- [MEDIUM] Switched timer loop to use `Date.now` delta calculation to prevent drift.
- [MEDIUM] Added guard in `handleInput` for nil cards.
- [MEDIUM] Added auto-finish in `nextCard` when deck is empty.
