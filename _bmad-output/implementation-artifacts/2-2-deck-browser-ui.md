# Story 2.2: Deck Browser UI

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a Player,
I want to browse and select a specific deck (e.g., "Gurbet"),
so that I can customize the game vibe for my current group.

## Acceptance Criteria

1. **Given** the Main Menu view
   **When** the app launches
   **Then** it must display a horizontal or vertical list of available decks
   **And** each deck must show its Title, Icon, and Description

2. **Given** a selected Deck
   **When** "Start" is tapped
   **Then** it must navigate to the Game View and inject the selected Deck

3. **Given** the visual design system
   **When** rendering deck items
   **Then** they must use the "Electric Eagle" aesthetic (Neon Glow, Dark Backgrounds)
   **And** confirm SF Symbol compatibility for icons

## Tasks / Subtasks

- [x] Task 1: Create Deck Card Component (UI) (AC: 1, 3)
  - [x] Create `Features/Game/Views/Components/DeckRowView.swift`
  - [x] Display Title, Description, and Icon
  - [x] Apply `.neonGlow()` modifier and Design System colors
  - [x] Support "Selected" state visual feedback

- [x] Task 2: Implement Deck Browser Screen (AC: 1)
  - [x] Create `Features/Game/Views/DeckBrowserView.swift`
  - [x] Inject `DeckService` via `@Environment`
  - [x] Display list of `freeDecks` using `DeckRowView`
  - [x] Add "Choose Your Vibe" header

- [x] Task 3: Navigation Logic (AC: 2)
  - [x] Implement `NavigationStack` or bind to existing root navigation
  - [x] Add `Start Game` button (disabled if no selection, if applicable, or auto-start on tap)
  - [x] Pass `selectedDeck` to `GameScreen` via initialization or Environment overrides

## Dev Notes

- **Architecture Pattern:**
  - `DeckBrowserView` is a View, not a full cleaner architecture "Module" yet (keep it simple MVP).
  - Use `DeckService` from Story 2.1 (verified working).
- **Design System:**
  - Use `Color.neonBlue` or `Color.neonGreen` for deck highlights.
  - Background defaults to `Color.trueBlack`.
- **Testing:**
  - Create a Snapshot test for the Browser View if possible, or ViewInspector test.
  - Verify `DeckService` integration in Previews using `DeckService(decks: [...])`.

### Project Structure Notes

- `Features/Game/Views/` is the correct location.
- Ensure `ContentView` is updated to show `DeckBrowserView` as the entry point (or home screen).

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.2]
- [Source: Kape/Data/Services/DeckService.swift]

## Dev Agent Record

### Agent Model Used

Claude 3.5 Sonnet (Scrum Master Agent)

### Debug Log References

### Completion Notes List

- Task 1: Created `DeckRowView` with Neon styling and basic unit test. Verified composition.
- Task 2: Implemented `DeckBrowserView` handling DeckService injection and deck selection logic.
- Task 3: Integrated Navigation and Start Game logic. Updated `ContentView` to host the browser. Verified integration with unit tests.

### File List

- Kape/Features/Game/Views/Components/DeckRowView.swift
- KapeTests/Features/Game/Views/DeckRowViewTests.swift
- Kape/Features/Game/Views/DeckBrowserView.swift
- KapeTests/Features/Game/Views/DeckBrowserViewTests.swift
- Kape/ContentView.swift

### Code Review Record (2026-01-10)

**Reviewer:** Dev Agent (Code Review Workflow)

**Issues Found:** 3 High, 3 Medium, 1 Low

**Fixes Applied:**
- [x] CR-01: Fixed `DeckBrowserViewTests` by adding `@MainActor` and improving assertions
- [x] CR-02: Enhanced test assertions in `DeckRowViewTests` to validate deck properties
- [x] CR-04: Refactored `DeckBrowserView` into subviews for clarity
- [x] CR-05: Added accessibility identifiers (`DeckBrowserHeader`, `DeckRow_*`, `StartGameButton`)
- [x] CR-06: Moved `@State gameEngine` to top of struct with other state properties

**Deferred (Low Priority):**
- [ ] CR-03: Document AC1 design decision (vertical list chosen for MVP)
- [ ] CR-07: Clean up unclear comment in DeckBrowserView (cosmetic)

