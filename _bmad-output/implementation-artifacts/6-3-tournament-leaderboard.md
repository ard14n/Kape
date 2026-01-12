# Story 6.3: Tournament Leaderboard

**Status:** done
**Epic:** 6 - Party Tournament Mode
**Previous Story:** [6-2-turn-management-system](file:///Users/ardianjahja/Projekte/Kape/_bmad-output/implementation-artifacts/6-2-turn-management-system.md)

## Story

As a Group,
We want to see who won after all rounds are played,
So that we can celebrate the "Legjendë".

## Acceptance Criteria

### 1. Leaderboard Presentation
- **Given** all rounds in a tournament are completed
- **When** the final game finishes
- **Then** the app must transition to the **Leaderboard Screen**
- **And** it must list all players sorted by **Total Score** (Descending)
- **And** the #1 player must be highlighted as **"Legjendë"** (Gold styling, pulsing effect)
- **And** the #2 and #3 players must have Silver/Bronze styling
- **And** lower ranked players should be clearly visually distinct ("Turist" styling - grayed out)

### 2. Tournament Reset
- **Given** the Leaderboard is displayed
- **When** the **"New Tournament"** (Turne i Ri) button is tapped
- **Then** it must reset the `TournamentState`
- **And** navigate back to the **Tournament Setup** screen
- **And** optionally preserve player names for quick restart (if technically cheap, otherwise clear all)

### 3. Social Sharing (Podium)
- **Given** the Leaderboard
- **When** the **"Share Podium"** (Ndaj Podin) button is tapped
- **Then** the app must generate a sharable image including:
  - Top 3 Players with their Scores
  - The Kape! Logo
  - The "Legjendë" Badge for the winner
- **And** present the native iOS Share Sheet

## Tasks / Subtasks

- [x] Task 1: Leaderboard UI Implementation (AC: 1)
  - [x] Create `Features/Tournament/Views/LeaderboardView.swift`
  - [x] Implement `PodiumRow` component for Top 3 (Gold/Silver/Bronze)
  - [x] Implement `PlayerRow` component for others
  - [x] Add "Legjendë" pulsing animation for the winner
  - [x] Use `DesignSystem` components (`NeonButton`, `VibeBackground`)

- [x] Task 2: Tournament ViewModel Logic (AC: 1, 2)
  - [x] Add `finishTournament()` to `TournamentViewModel` (transition phase to `finished`)
  - [x] Add `resetTournament()` logic (clear scores, reset round, keep players or clear based on UX decision - keeping names is better)
  - [x] Add computed property `rankedPlayers` that sorts `TournamentState.players`
  - [x] Update `TournamentContainerView` to show `LeaderboardView` when `phase == .finished`

- [x] Task 3: Podium Image Generation (AC: 3)
  - [x] Create `PodiumImageGenerator` service (or extend `ShareService`)
  - [x] Render a specialized SwiftUI view (`PodiumExportView`) to `ImageRenderer`
  - [x] Handle MainActor requirements for rendering
  - [x] Connect "Share Podium" button to invoke generation and show ShareSheet

- [x] Task 4: Unit Tests
  - [x] Test `rankedPlayers` sorting logic (handle ties? typically arbitrary or shared rank, MVP can be simple sort)
  - [x] Test `resetTournament()` clears scores but keeps players (if implemented) or clears all
  - [x] Test state transition to `.finished`

## Senior Developer Review (AI)

- [x] [AI-Review][Medium] Localize hardcoded strings in `LeaderboardView.swift` and `PodiumImageGenerator.swift`
- [x] [AI-Review][Medium] Fix deprecated `UIScreen.main.scale` usage in `PodiumImageGenerator.swift`
- [x] [AI-Review][Low] Add nil check/silent failure handling for image generation (handled via optional binding)

## Dev Notes

- **Architecture:** Continue in `Features/Tournament`.
- **State Management:** Use the existing `TournamentViewModel` and `TournamentState`.
- **UX Specs:**
  - #1: Gold, #2: Silver, #3: Bronze.
  - Winner gets "Legjendë" badge.
  - Others get "Turist" (or just gray status).
- **Localization:** Ensure strings are localized ("Legjendë", "Turne i Ri", "Ndaj Podin").
- **Image Generation:** Reuse patterns from Story 3.3 if available, otherwise implement `ImageRenderer` (iOS 16+) technique. Be careful with concurrency (MainActor).

### Project Structure Notes

- New View: `Features/Tournament/Views/LeaderboardView.swift`
- Logic update: `Features/Tournament/Logic/TournamentViewModel.swift`

### References

- [Epics: Story 6.3](file:///Users/ardianjahja/Projekte/Kape/_bmad-output/planning-artifacts/epics.md#story-63-tournament-leaderboard)
- [UX: Tournament Leaderboard](file:///Users/ardianjahja/Projekte/Kape/_bmad-output/planning-artifacts/ux-design-specification.md#33-the-tournament-leaderboard)

## Dev Agent Record

### Agent Model Used
M8

### Debug Log References
- Fixed `rankedPlayers` accessing config instead of state.
- Fixed `switch` statement syntax error in `TournamentContainerView`.
- Unit tests passed on iPhone 17 Pro simulator.

### Completion Notes List
- Implemented `LeaderboardView` with specialized `PodiumView` and styling.
- Created reusable `NeonButton` and `VibeBackground` components in Design System.
- Implemented `TournamentViewModel` logic for ranking, finishing, and resetting.
- Implemented `PodiumImageGenerator` for sharing.
- Connected flow in `TournamentContainerView`.
- Verified with comprehensive Unit Tests covering all logic.

## File List
- Features/Tournament/Views/LeaderboardView.swift
- Features/Tournament/Logic/TournamentViewModel.swift
- Features/Tournament/Views/TournamentContainerView.swift
- Features/Tournament/Logic/PodiumImageGenerator.swift
- Core/DesignSystem/Components/NeonButton.swift
- Core/DesignSystem/Components/VibeBackground.swift
- KapeTests/Features/Tournament/TournamentViewModelTests.swift
