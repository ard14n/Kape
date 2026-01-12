# Story 6.2: Turn Management System

**Status:** ready-for-dev
**Epic:** 6 - Party Tournament Mode
**Previous Story:** [6-1-tournament-setup-ui](file:///Users/ardianjahja/Projekte/Kape/_bmad-output/implementation-artifacts/6-1-tournament-setup-ui.md)

## Story

As a Player,
I want the game to tell me when it is my turn,
So that I can take the phone and play my round.

## Acceptance Criteria

### 1. Interstitial State (The Handoff)
- **Given** a Tournament in progress
- **When** a game round finishes OR the tournament starts
- **Then** show the "Pass the Device" Interstitial (Blocking State)
- **And** display "Radha e [Next Player Name]" (It's [Name]'s turn) in huge text
- **And** show the current Round number (e.g., "Raundi 1 / 3")
- **And** require a deliberate "Gati!" (Ready) tap to start the game loop for that player
- **Note:** This prevents accidental gyro triggers during phone handoff.

### 2. State Persistence (Crash Recovery - Part 1)
- **Given** any state change (Game Start, Game End, Score Update)
- **When** the event occurs
- **Then** the `TournamentManager` must persist the full `TournamentState` to `current_tournament.json`
- **And** this must happen synchronously or immediately to ensure data safety before any potential crash.

### 3. Game Loop Integration
- **Given** the Game Loop (Story 1.3)
- **When** playing in Tournament Mode
- **Then** the standard 60s timer and tilt logic applies
- **But** the score achieved must be assigned to the **current active player's** session history
- **And** the game must NOT navigate to the standard Result Screen, but instead return to the Tournament Flow (likely the Score/Ranking update or next player).

## Tasks / Subtasks

- [ ] Task 1: Tournament State Machine (AC: 1, 3)
  - [ ] Create `TournamentPhase` enum (setup, interstitial, playing, finished)
  - [ ] Create `TournamentState` struct (players, config, currentRound, currentPlayerIndex, phase)
  - [ ] Extend `TournamentViewModel` with state machine logic
  - [ ] Implement `startTournament()` to transition from setup to interstitial
  - [ ] Implement `startPlayerTurn()` to transition from interstitial to playing
  - [ ] Implement `recordScore(score:)` to update current player and advance turn
  - [ ] Implement `nextTurn()` round-robin logic (player index, round advancement)

- [ ] Task 2: JSON Persistence Service (AC: 2)
  - [ ] Create `TournamentPersistenceService.swift` with `saveState()` and `loadState()`
  - [ ] Implement save to `Documents/current_tournament.json`
  - [ ] Implement load from JSON with error handling
  - [ ] Add `deleteState()` for cleanup after tournament ends
  - [ ] Call `saveState()` after every state change in TournamentViewModel

- [ ] Task 3: Interstitial UI (AC: 1)
  - [ ] Create `TournamentInterstitialView.swift`
  - [ ] Display "Radha e [Name]" in huge text (80pt+)
  - [ ] Display "Raundi X / Y" subtitle
  - [ ] Add "Gati!" button with Electric Eagle theming
  - [ ] Add phone handoff visual cue (SF Symbol)
  - [ ] Connect button action to `startPlayerTurn()`

- [ ] Task 4: Tournament Flow Container (AC: 1, 3)
  - [ ] Create `TournamentContainerView.swift` as root coordinator
  - [ ] Switch between phases: setup → interstitial → playing → interstitial...
  - [ ] Present GameView as fullScreenCover when playing
  - [ ] Handle game completion callback to record score
  - [ ] Dismiss game and show next interstitial or leaderboard

- [ ] Task 5: Game Integration (AC: 3)
  - [ ] Modify `GameViewModel` to accept optional `onComplete: (Int) -> Void` callback
  - [ ] Ensure score is passed back to TournamentViewModel
  - [ ] Skip standard ResultScreen when in tournament mode
  - [ ] Update `TournamentSetupView` to use TournamentContainerView

- [ ] Task 6: Unit Tests
  - [ ] Test `TournamentPhase` transitions
  - [ ] Test `nextTurn()` round-robin logic (2-5 players, 1-5 rounds)
  - [ ] Test `recordScore()` updates correct player
  - [ ] Test persistence save/load cycle
  - [ ] Test edge cases (last player, last round, tournament finish)

## Dev Notes

- **Architecture:** Feature-First structure (`Features/Tournament`).
- **State Management:** Use `@Observable` (iOS 17+).
- **Pattern:** MVVM with state machine in ViewModel.
- **Theming:** Electric Eagle (.neonGreen, .trueBlack, .neonRed).
- **Localization:** Albanian strings ("Radha e...", "Raundi...", "Gati!").

### Project Structure Notes
- Extend existing `Features/Tournament` directory
- New files in `Logic/` and `Views/`

### References
- [Source: epics.md#Story 6.2: Turn Management System]
- [Previous: 6-1-tournament-setup-ui.md]

## Dev Agent Record

### Agent Model Used
(To be filled during implementation)

### Debug Log References
(To be filled during implementation)

### Completion Notes List
(To be filled during implementation)

## File List

**New Files:**
(To be filled during implementation)

**Modified Files:**
(To be filled during implementation)

## Change Log

- 2026-01-12: Story created with Tasks/Subtasks breakdown
- 2026-01-12: Implemented core turn management, state machine, persistence, and UI. Passed adversarial code review (fixed UI scale, handoff icon, magic strings, and logging).

