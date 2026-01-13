# Story 3.5: Result Screen Navigation Update

**Status:** in-progress
**Epic:** 3 - Social & Viral Validation
**Previous Story:** [3-4-native-sharing-integration](file:///Users/ardianjahja/Projekte/Kape/_bmad-output/implementation-artifacts/3-4-native-sharing-integration.md)

## Story

As a Player,
I want to be able to return to the main menu from the result screen,
So that I am not forced to play again if I want to stop.

## Acceptance Criteria

### 1. Exit Navigation
- **Given** the Result Screen
- **When** displayed
- **Then** it must show a "Home" / "Exit" button
- **And** the button style must be secondary (smaller or less prominent than "Play Again")
- **And** tapping it must navigate back to the Main Menu (pop to root)

## Tasks / Subtasks

- [x] Task 1: UI Implementation
  - [x] Add "Home" button to `ResultScreen.swift`
  - [x] Ensure button hierarchy (Play Again > Share > Home)
  - [x] Use `NavigationPath` or `dismiss` environment to handle navigation

- [x] Task 2: Unit Tests
  - [x] Verify `ResultScreen` can be initialized and action triggers callback (if using callbacks)

## Dev Notes

- **Architecture:** `Features/Summary/Views/ResultScreen.swift`
- **Design:** Use `NeonButton` with a `.secondary` style or a simple text/icon button to avoid clutter.
- **Navigation:** The app likely uses a Coordinator or NavigationStack. Ensure we pop correctly.

## Dev Agent Record

### File List
- Kape/Kape/Features/Game/Views/DeckBrowserView.swift
- Kape/Kape/Features/Summary/Views/ResultScreen.swift
- Kape/KapeTests/Features/Summary/ResultScreenNavigationTests.swift

### Change Log
- Wired Home button callback from ResultScreen to DeckBrowserView so "Ballina" dismisses the result cover back to main menu.
- Added unit test to assert `onHome` callback is invokable.
