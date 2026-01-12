# Story 5.2: Navigation & Exit Strategy

**Epic:** 5 - Visual Experience Upgrade (Scope expanded to include UX Fixes)
**Status:** done

## User Story
**As a** Player,
**I want** to pause or exit the game loop easily,
**So that** I don't feel "trapped" and can change decks or handle interruptions without killing the app.

## Context
User testing revealed a critical "dead end" UX. Once a game starts, there is no UI affordance to leave. Users felt "trapped". While "immersiveness" was a goal, control is a necessity.

## Acceptance Criteria

### 1. Pause UI Affordance
**Given** the Game View is active (playing state)
**When** the user looks at the screen
**Then** a small, unobtrusive "Pause" (||) or "X" button must be visible in the top-leading or top-trailing safe area
**And** it must not interfere with the card text (Z-index higher)

### 2. Pause State Behavior
**Given** the Pause button is tapped
**When** triggered
**Then** the `GameEngine` must enter a `.paused` state
**And** the Timer must stop ticking immediately
**And** the Motion Manager updates should be ignored

### 3. Pause Menu Overlay
**Given** the game is paused
**When** the state changes
**Then** a blurred overlay should appear
**And** it must offer two clear options:
  1. **"Resume"** (Large, primary action) - returns to game
  2. **"End Game"** (Secondary, destructive) - returns to Main Menu/Deck Browser

### 4. Exit Logic
**Given** "End Game" is chosen
**When** confirmed
**Then** the app must navigate back to the Deck Browser
**And** the current game session data should be discarded (no partial result screen)
**And** audio/haptics must stop immediately

## Technical Notes
- `GameEngine` needs a `paused` state case.
- `GameView` needs a `ZStack` for the overlay.
- Ensure the button hit area is large enough (min 44pt) even if the icon is small.

## Tasks

- [x] Implement Pause UI Button (AC 1) <!-- id: 0 -->
    - [x] Add pause button to GameView overlay <!-- id: 1 -->
    - [x] Ensure proper z-index and safe area placement <!-- id: 2 -->
- [x] Implement Game Engine Pause State (AC 2) <!-- id: 3 -->
    - [x] Add .paused state to GameEngine state machine <!-- id: 4 -->
    - [x] Handle state transitions (playing -> paused -> playing) <!-- id: 5 -->
    - [x] Ensure timer pauses/resumes correctly <!-- id: 6 -->
- [x] Implement Pause Menu Overlay (AC 3) <!-- id: 7 -->
    - [x] Create blurred background overlay <!-- id: 8 -->
    - [x] Add Resume button functionality <!-- id: 9 -->
    - [x] Add End Game button functionality <!-- id: 10 -->
- [x] Implement Exit Logic (AC 4) <!-- id: 11 -->
    - [x] Wire up End Game navigation (back to root/browser) <!-- id: 12 -->
    - [x] Ensure cleanup of audio/haptics <!-- id: 13 -->

## Dev Agent Record

### Review Follow-ups (AI)
- [ ] [AI-Review][Low] Audio Cleanup: `GameEngine.finishGame` relies on task cancellation. Consider adding `stop()` to `AudioServiceProtocol` for robust cleanup. [GameEngine.swift:235]

### Debug Log

### Completion Notes

## File List
