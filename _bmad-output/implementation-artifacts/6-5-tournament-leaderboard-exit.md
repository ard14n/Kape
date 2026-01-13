# Story 6.5: Tournament Leaderboard Exit

**Status:** in-progress
**Epic:** 6 - Party Tournament Mode
**Previous Story:** [6-4-tournament-state-persistence](file:///Users/ardianjahja/Projekte/Kape/_bmad-output/implementation-artifacts/6-4-tournament-state-persistence.md)

## Story

As a Group,
We want to exit the tournament mode after seeing the results,
So that we can play a normal game or do something else.

## Acceptance Criteria

### 1. Exit Navigation
- **Given** the Tournament Leaderboard
- **When** displayed
- **Then** it must show a "Close" or "Exit" button
- **And** tapping it must clear the tournament state and return to Main Menu
- **And** it must NOT inadvertently start a new tournament

## Tasks / Subtasks

- [x] Task 1: UI Implementation
  - [x] Add "Exit" button to `LeaderboardView.swift`
  - [x] Position it appropriately (e.g., top right or below main actions)
  - [x] Ensure it calls `viewModel.resetTournament()` or dismisses the flow

- [x] Task 2: Unit Tests
  - [x] Verify exit action clears state

## Dev Notes

- **Architecture:** `Features/Tournament/Views/LeaderboardView.swift`
- **Logic:** `TournamentViewModel.swift` may need a `quitTournament()` function if `reset` assumes replay.

## Dev Agent Record

### File List
- Kape/Kape/Features/Tournament/Views/LeaderboardView.swift
- Kape/Kape/Features/Tournament/Views/TournamentContainerView.swift
- Kape/Kape/Features/Tournament/Logic/TournamentViewModel.swift
- Kape/KapeTests/Features/Tournament/LeaderboardExitTests.swift

### Change Log
- Prevented tournament reset from auto-opening setup when exiting leaderboard; now clears state and dismisses to main menu.
- Added unit test to assert `onExit` callback invocation.
