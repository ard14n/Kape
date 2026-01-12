# Story 6.1: Tournament Setup UI

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a Host,
I want to enter the names of my friends and set the game length,
So that we can start a personalized competition.

## Acceptance Criteria

1. **Tournament Entry:** Tapping "Turne" (Tournament) in Main Menu presents the Setup Modal Sheet (avoids keyboard covering UI).
2. **Player Configuration:** Host can add 2 to 5 players.
3. **Default Names:** System provides default names ("Lojtari 1", "Lojtari 2") for quick start.
4. **Custom Names:** Host can input custom names (Min 2 chars).
5. **Round Configuration:** Host can select "Rounds per Player" (1, 3, 5), defaulting to 3.
6. **Validation:** "Start Tournament" button is disabled until valid (2-5 players, valid names, **unique names**).

## Tasks / Subtasks

- [x] Task 1: Clean Architecture Setup & Models (AC: N/A)
  - [x] Create `Features/Tournament` directory structure
  - [x] Define `TournamentConfig` struct (players, rounds per player)
  - [x] Define `Player` model (id, name, score, sessionHistory)
  - [x] Create `TournamentViewModel` (Observable) to manage setup state

- [x] Task 2: Tournament Setup UI - Basic Layout (AC: 1, 2)
  - [x] Add "Turne" button to `MainMenu.swift`
  - [x] Create `TournamentSetupView.swift` (Sheet presentation)
  - [x] Implement "Add Player" / "Remove Player" dynamic list logic (Min 2, Max 5)

- [x] Task 3: Input Handling & Validation (AC: 3, 4, 6)
  - [x] Implement TextField for player names with "Done" keyboard toolbar
  - [x] Add DEFAULT names logic ("Lojtari X") if text field is empty
  - [x] Add validation logic (min 2 chars, unique names if possible)
  - [x] Bind "Start Tournament" button state to validation logic

- [x] Task 4: Round Configuration (AC: 5)
  - [x] Implement Segmented Control or Menu for Rounds (1, 3, 5)
  - [x] Ensure default is set to 3

- [x] Task 5: Integration & Polish
  - [x] Apply "Electric Eagle" theme (Neon/Black) to the sheet
  - [x] Ensure keyboard handling (ScrollView readers or `.scrollDismissesKeyboard`)
  - [x] Connect "Start" button to Navigation (placeholder destination for now)
  - [x] Write Unit Tests for `TournamentViewModel` validation logic

## Dev Notes

- **Architecture:** Use Feature-First structure (`Features/Tournament`).
- **State Management:** Use `@Observable` (iOS 17+).
- **UI:** This is a `sheet` presentation from Main Menu based on UX specs.
- **Theming:** Must align with `Color+DesignSystem` (.neonRed, .neonGreen).
- **Validation:** Critical to prevent empty names.

### Project Structure Notes

- New Feature: `Features/Tournament`

### References

- [Source: epics.md#Story 6.1: Tournament Setup UI]

## Dev Agent Record

### Agent Model Used

Claude (Antigravity)

### Debug Log References

- Build succeeded with warnings only (StoreService Swift 6 concurrency)
- All tournament unit tests passing

### Completion Notes List

- Created Features/Tournament directory with Models/ Logic/ Views/ structure
- Implemented Player model with id, name, score, sessionHistory and default name factory
- Implemented TournamentConfig with isValid validation, canAddPlayer/canRemovePlayer helpers
- Implemented TournamentViewModel using @Observable for reactive state management
- Created TournamentSetupView with Electric Eagle theming (neonGreen, trueBlack)
- Added Turne button to DeckBrowserView toolbar (topBarLeading)
- Implemented dynamic player list with add/remove animations (2-5 players)
- Added segmented picker for rounds (1, 3, 5) with default 3
- Added keyboard toolbar with Done button and scrollDismissesKeyboard
- Wrote comprehensive unit tests covering all 6 acceptance criteria
- **Code Review Fix:** Implemented unique name validation in `TournamentConfig` ensuring no duplicate player names (case-insensitive).
- **Code Review Fix:** Added comprehensive tests for name duplication scenarios.

### File List

**New Files:**
- Kape/Features/Tournament/Models/Player.swift
- Kape/Features/Tournament/Models/TournamentConfig.swift
- Kape/Features/Tournament/Logic/TournamentViewModel.swift
- Kape/Features/Tournament/Views/TournamentSetupView.swift
- KapeTests/Features/Tournament/PlayerTests.swift
- KapeTests/Features/Tournament/TournamentConfigTests.swift
- KapeTests/Features/Tournament/TournamentViewModelTests.swift
- KapeTests/Features/Tournament/TournamentSetupViewTests.swift

**Modified Files:**
- Kape/Features/Game/Views/DeckBrowserView.swift (added Turne button and tournament sheet)

## Change Log

- 2026-01-12: Implemented Story 6.1 Tournament Setup UI - all ACs satisfied
- 2026-01-12: [Code Review] Fixed unique name validation and verified with tests

