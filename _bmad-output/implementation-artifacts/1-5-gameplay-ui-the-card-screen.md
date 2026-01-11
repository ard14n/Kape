# Story 1.5: Gameplay UI (The Card Screen)

Status: implemented

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a Guesser,
I want the game screen to be highly legible and reactive,
So that my friends can read the words easily while I hold the phone on my forehead.

## Acceptance Criteria

1. **Given** the Game View
   **When** a card is displayed
   **Then** the text must be White on Black, dynamically sized (min 80pt)
   **And** text must scale down automatically if the word is too long (using `.minimumScaleFactor(0.5)`)

2. **Given** a `.correct` state trigger
   **When** rendering
   **Then** the background must flash Neon Green (`#39FF14`) for ~0.3 seconds
   **And** the card transition must animate off-screen (direction down)

3. **Given** a `.pass` state trigger
   **When** rendering
   **Then** the background must flash Neon Orange (`#FF9500`) for ~0.3 seconds
   **And** the card transition must animate off-screen (direction up)

4. **Given** the game is in `buffer` state (3-second countdown)
   **When** the screen is displayed
   **Then** it must show "Ready..." or countdown text
   **And** display instructions to place phone on forehead

5. **Given** the game timer
   **When** time is remaining
   **Then** a timer indicator must be visible to the audience (optional: can be subtle)
   **And** score must be displayed (correct count)

6. **Given** the 10-second warning has triggered
   **When** rendering
   **Then** the UI may show visual urgency (e.g., pulsing timer or color shift)

7. **Given** the game is in `finished` state
   **When** rendering
   **Then** it must transition to a result summary or dismiss the game view

8. **Given** accessibility requirements
   **When** `UIAccessibility.isReduceMotionEnabled` is true
   **Then** screen flashes must be replaced with simple fades

## Tasks / Subtasks

- [x] Task 1: Create GameScreen View (AC: 1, 4, 5, 7)
  - [x] Create `/Features/Game/Views/GameScreen.swift`
  - [x] Inject `GameEngine` as `@Observable` via environment or init
  - [x] Implement state-based rendering (idle, buffer, playing, finished)
  - [x] Create card display with huge text (80pt SF Pro Rounded Heavy)
  - [x] Add timer display and score counter

- [x] Task 2: Implement KapeCard Component (AC: 1, 8)
  - [x] Create `/DesignSystem/Components/KapeCard.swift` (or in `/Core/DesignSystem/`)
  - [x] Use dynamic text sizing with `.minimumScaleFactor(0.5)`
  - [x] Implement White text on Black background (True Black)
  - [x] Support Dynamic Type scaling

- [x] Task 3: Implement Background Flash Effect (AC: 2, 3, 8)
  - [x] Create a `FlashOverlay` view or modifier
  - [x] Implement Green flash for `.success` events
  - [x] Implement Orange flash for `.pass` events
  - [x] Respect `accessibilityReduceMotion` preference
  - [x] Flash duration: ~0.3s with fade-out

- [x] Task 4: Implement Card Transitions (AC: 2, 3)
  - [x] Add card exit animation (slide down for correct, slide up for pass)
  - [x] Use `.transition(.move(edge:))` or custom animation
  - [x] Ensure animation is snappy/bouncy (not slow cinematic)

- [x] Task 5: Buffer State UI (AC: 4)
  - [x] Create countdown overlay for 3-second buffer
  - [x] Display "Place on Forehead" instruction
  - [x] Optional: Show rotating phone icon (SF Symbol)

- [x] Task 6: Warning State Visual (AC: 6)
  - [x] Implement visual urgency at 10-second mark
  - [x] Options: pulsing timer, color shift, or screen edge glow

- [x] Task 7: Connect to GameEngine (AC: All)
  - [x] Observe `gameState` and `currentRound` from `GameEngine`
  - [x] Wire up state changes to trigger flash/animation effects
  - [x] Handle `finished` state transition (present Result view or callback)

- [x] Task 8: Integration & Testing
  - [x] Create preview with mock data
  - [x] Test on physical device (orientation, haptic timing)
  - [x] Verify accessibility: Dynamic Type, Reduce Motion

## Dev Notes

### Architecture Compliance

**CRITICAL: Follow these patterns exactly.**

- **File Locations:**
  - `GameScreen.swift` → `/Features/Game/Views/GameScreen.swift`
  - `KapeCard.swift` → `/Core/DesignSystem/Components/KapeCard.swift` (or keep DesignSystem flat)
  - `MotionManager.swift` → `/Core/Motion/MotionManager.swift`
  - Use existing design tokens from `/Core/DesignSystem/Colors.swift` and `Modifiers.swift`

- **Pattern Conformance:**
  - Views observe `@Observable` models (GameEngine)
  - Never put game logic inside View body
  - Use existing `.neonGlow()` modifier for effects
  - Use existing colors: `.neonGreen`, `.neonOrange`, `.trueBlack`

- **Dependency Injection:**
  - `GameScreen` receives `GameEngine` via environment or init parameter
  - Do NOT create GameEngine instances inside the view

### Technical Requirements

**Motion Detection (Updated):**
- Switched to Gravity Vector Z-Axis for robust tilt detection
- Includes Auto-Calibration on game start (post-buffer)

### File Structure After Implementation

```
Kape/
├── Core/
│   ├── DesignSystem/
│   │   ├── Colors.swift         ← EXISTS
│   │   ├── Modifiers.swift      ← EXISTS
│   │   └── Components/          ← NEW folder
│   │       └── KapeCard.swift   ← NEW
│   ├── Motion/
│   │   └── MotionManager.swift  ← UPDATED
├── Features/
│   ├── Game/
│   │   ├── Logic/
│   │   │   ├── GameEngine.swift ← UPDATED
│   │   │   └── GameModels.swift ← EXISTS
│   │   └── Views/               ← NEW folder
│   │       ├── GameScreen.swift ← NEW (main view)
│   │       ├── BufferView.swift ← NEW (countdown)
│   │       └── FlashOverlay.swift ← NEW (feedback effect)
```

## Dev Agent Record

### Agent Model Used

Amelia (Dev Agent)

### Completion Notes List

- Implemented full Gameplay UI including `GameScreen`, `BufferView`, and `FlashOverlay`.
- Refactored `MotionManager` to use Gravity Z-Axis for reliable tilt detection in any landscape starting position.
- Added Auto-Calibration (Tare) logic to prevent immediate triggers on start.
- Fixed `ContentView` navigation logic using `.fullScreenCover(item:)` to solve "Black Screen" issue.
- Added Test Automation with `GameUITests` and Data Factories.

### File List

- /Kape/Features/Game/Views/GameScreen.swift
- /Kape/Features/Game/Views/BufferView.swift
- /Kape/Features/Game/Views/FlashOverlay.swift
- /Kape/Core/DesignSystem/Components/KapeCard.swift
- /Kape/Core/Motion/MotionManager.swift
- /Kape/Features/Game/Logic/GameEngine.swift
- /Kape/ContentView.swift
- /KapeUITests/GameUITests.swift
- /KapeTests/Helpers/Factories.swift
- /KapeTests/Features/Game/GameEngineTests.swift

## Change Log

- 2026-01-10: Code Review Pass - Fixed 5 issues (debug prints, unused property, DispatchQueue→Task, countdown logic, doc comments)
- 2026-01-09: Story 1.5 implemented completely.
- 2026-01-09: Story 1.5 created - Gameplay UI (The Card Screen)
