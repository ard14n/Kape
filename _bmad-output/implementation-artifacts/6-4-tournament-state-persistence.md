# Story 6.4: Tournament State Persistence (Crash Recovery)

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a Host,
I want the tournament to resume exactly where we left off if the app crashes,
So that we don't lose our scores in the middle of a heated party.

## Acceptance Criteria

1. **Tournament State Serialization**
   - **Given** an active tournament session (in progress)
   - **When** the app is terminated (Crash, Force Quit, or Backgrounded for extended time)
   - **Then** the complete `TournamentState` must be serialized to `Documents/current_tournament.json`
   - **And** the state must include: List of Players, Current Scores, Round Index, Current Active Player Index

2. **Resume Prompt on Launch**
   - **Given** the App Launch (didFinishLaunch)
   - **When** a valid `current_tournament.json` file is detected in Documents
   - **Then** the app must present a prompt: "Turne i papërfunduar u gjet. Dëshiron ta vazhdosh?" (Unfinished tournament found. Resume?)
   - **And** options must be "Vazhdo" (Resume) and "Fillo të ri" (Start New)

3. **State Restoration**
   - **Given** the user chooses "Vazhdo"
   - **When** restoration occurs
   - **Then** the app must deserialize the JSON
   - **And** restore the `TournamentManager` state entirely
   - **And** navigate directly to the Interstitial Screen for the correct pending player
   - **And** ensure the Leaderboard reflects the restored scores

4. **State Cleanup**
   - **Given** a Tournament
   - **When** the Final Round completes and the Winner is declared (Game Over)
   - **Then** the `current_tournament.json` file must be deleted or cleared
   - **And** if the user chooses "Fillo të ri" at the resume prompt, the old file must be overwritten/deleted

## Tasks / Subtasks

- [x] Implement `TournamentPersistenceService`
  - [x] Define `Codable` struct for `TournamentSnapshot` (mirroring `TournamentManager` state)
  - [x] Implement `save(state:)` writing to Documents directory (JSON)
  - [x] Implement `load() -> TournamentSnapshot?` reading from Documents directory
  - [x] Implement `clear()` to remove the file
- [x] Integrate Persistence into `TournamentManager`
  - [x] Call `save()` on every state change (End of Turn, Score Update)
  - [x] Call `clear()` on Tournament Completion
- [x] Implement Resume Logic in `App/KapeApp.swift` or `MainMenuView`
  - [x] Check for existence of persistence file on `onAppear` or app launch
  - [x] Show Alert/Sheet if file exists
- [x] Implement Restoration Navigation
  - [x] Inject restored state into `EnvironmentObject` (TournamentManager)
  - [x] Programmatically navigate to `InterstitialView`

## Dev Notes

- **Persistence Strategy:** Use `FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)` to store `current_tournament.json`. This is distinct from the read-only `decks.json` in the Bundle.
- **Timing:** Saving on every turn end is sufficient and performant enough (JSON size is tiny). No need for debounce unless saving on every score increment.
- **Error Handling:** If JSON is corrupt, silently fail (log error) and do not show the resume prompt. Treat it as a fresh start.
- **Testing:** Simulate crash by stopping the app in Xcode, or killing it in the simulator.

### Project Structure Notes

- `TournamentPersistenceService.swift` should live in `Features/Tournament/Logic/` or `Core/Persistence/` if generic (but likely specific to Tournament). Let's keep it feature-co-located: `Features/Tournament/Logic/TournamentPersistenceService.swift`.
- Ensure strict adherence to `Codable` conformity for all nested types in `TournamentState`.

### References

- [Architecture Decision: Tournament Persistence](_bmad-output/planning-artifacts/architecture.md#core-architectural-decisions) - "TournamentState serialized to `Documents/current_tournament.json` on every state change."
- [Epic 6 Requirements](_bmad-output/planning-artifacts/epics.md#story-64-tournament-state-persistence-crash-recovery)

## Dev Agent Record

### Agent Model Used

GPT-5.1-Codex-Max

### Debug Log References

- xcodebuild test (TournamentViewModelTests) — failed to start simulator: Supported platforms empty (destination iPhone 15)

### Completion Notes List

- Added snapshot-based persistence (save/load/clear) with automatic cleanup on finished tournaments.
- Integrated persistence into tournament lifecycle (start, turn transitions, finish, reset) plus resume restore helper.
- Added launch-time resume prompt in DeckBrowser with Albanian copy; resume opens tournament flow, start new clears stale data.
- Wired TournamentSetupView start button to launch TournamentContainerView flow; reuse shared view model.
- Added tests covering persistence clearing and ignoring finished snapshots; attempted targeted xcodebuild test (blocked by simulator config).

### File List
- _bmad-output/implementation-artifacts/sprint-status.yaml
- _bmad-output/implementation-artifacts/6-4-tournament-state-persistence.md
- Kape/Features/Game/Views/DeckBrowserView.swift
- Kape/Features/Tournament/Logic/TournamentPersistenceService.swift
- Kape/Features/Tournament/Logic/TournamentViewModel.swift
- Kape/Features/Tournament/Models/TournamentStateDTO.swift
- Kape/Features/Tournament/Views/TournamentSetupView.swift
- Kape/Features/Tournament/Views/TournamentContainerView.swift
- KapeTests/Features/Tournament/TournamentViewModelTests.swift
