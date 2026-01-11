# Story 3.1: Result & Status Calculation Logic

Status: done

## Story

As a **Player**,
I want **to see my score and rank immediately after the game**,
so that **I know how well I performed compared to my friends**.

## Acceptance Criteria

1. **Given** a finished game session
   - **When** the result is calculated
   - **Then** it must compute:
     - **Score** = Correct answers (`GameRound.score`)
     - **Total** = Score + Passed (`GameRound.score + GameRound.passed`)
     - **Accuracy** = Score / Total (guard against divide-by-zero → 0%)
   - **And** assign a Rank Title:
     - 0-4: **"Mish i Huaj"**
     - 5-9: **"Shqipe"**
     - 10+: **"Legjendë"**

## Tasks / Subtasks

- [x] **Task 1: Create `GameResult` Model** (AC: All)
  - [x] Create `/Data/Models/GameResult.swift`
  - [x] Properties: `score: Int`, `passed: Int`, `date: Date`
  - [x] Computed: `var total: Int { score + passed }`
  - [x] Computed: `var accuracy: Double { total > 0 ? Double(score) / Double(total) : 0 }`
  - [x] Computed: `var rank: Rank { Rank.from(score: score) }`
  - [x] Factory: `static func from(_ round: GameRound) -> GameResult`

- [x] **Task 2: Create `Rank` Enum** (AC: Rank Title)
  - [x] Add to `GameResult.swift` or `GameModels.swift`
  - [x] Cases: `.mishIHuaj`, `.shqipe`, `.legjende`
  - [x] Property: `var title: String` ("Mish i Huaj", "Shqipe", "Legjendë")
  - [x] Property: `var color: Color` (use Design System: `.white`, `.neonOrange`, `.neonGreen`)
  - [x] Static: `func from(score: Int) -> Rank`

- [x] **Task 3: Integrate with GameEngine** (AC: Compute Score)
  - [x] `GameRound` already exists in `Features/Game/Logic/GameModels.swift` with `score` and `passed`
  - [x] In `GameEngine.finishGame()`: Create `GameResult.from(currentRound!)` before setting `.finished`
  - [x] Add `var result: GameResult?` to `GameEngine` (published for View consumption)

- [x] **Task 4: Update GameScreen Callback** (AC: Pass Result)
  - [x] `GameScreen.swift` line 11 has `onFinished: ((GameRound) -> Void)?`
  - [x] Change to `onFinished: ((GameResult) -> Void)?` OR keep GameRound and let caller derive GameResult
  - [x] **Recommended:** Keep `GameRound` callback, create `GameResult` in navigation layer (simpler)

- [x] **Task 5: Unit Tests**
  - [x] `RankTests`: `score=4 → .mishIHuaj`, `score=5 → .shqipe`, `score=9 → .shqipe`, `score=10 → .legjende`
  - [x] `GameResultTests`: Accuracy with `total=0` returns `0.0` (no crash)
  - [x] `GameResultTests`: Factory `from(GameRound)` correctly maps fields

## Dev Notes

### Existing Code Context

| File | Key Info |
|------|----------|
| `Features/Game/Logic/GameModels.swift` | `GameRound` has `score: Int`, `passed: Int` |
| `Features/Game/Logic/GameEngine.swift` | `finishGame()` sets `.finished`, has `currentRound: GameRound?` |
| `Features/Game/Views/GameScreen.swift` | `onFinished: ((GameRound) -> Void)?` called when state becomes `.finished` |

### Architecture Compliance

- `GameResult` → `/Data/Models/GameResult.swift` (new file)
- `Rank` enum → same file or `GameModels.swift`
- Logic in model extensions, NOT in Views
- `@Observable` pattern for `GameEngine.result` if adding

### Design System Colors for Rank

```swift
extension Rank {
    var color: Color {
        switch self {
        case .mishIHuaj: return .white.opacity(0.6)
        case .shqipe: return .neonOrange
        case .legjende: return .neonGreen
        }
    }
}
```

### Test Boundary Values

| Score | Expected Rank |
|-------|---------------|
| 0 | Mish i Huaj |
| 4 | Mish i Huaj |
| 5 | Shqipe |
| 9 | Shqipe |
| 10 | Legjendë |
| 15 | Legjendë |

### References

- [GameModels.swift](file:///Users/ardianjahja/Desktop/Projekte/Kape/Kape/Kape/Features/Game/Logic/GameModels.swift) - Existing `GameRound`
- [GameEngine.swift](file:///Users/ardianjahja/Desktop/Projekte/Kape/Kape/Kape/Features/Game/Logic/GameEngine.swift) - Integration point
- [Epics.md: Story 3.1](_bmad-output/planning-artifacts/epics.md)

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4 (with extended thinking)

### Completion Notes List

- ✅ Created `GameResult.swift` with Rank enum and GameResult model
- ✅ Implemented all computed properties with divide-by-zero guard for accuracy
- ✅ Integrated `GameResult` calculation in `GameEngine.finishGame()`
- ✅ Created `RankTests.swift` with 12 test cases covering all boundary values (including negative)
- ✅ Created `GameResultTests.swift` with 13 test cases covering accuracy, rank, factory method
- ✅ Build succeeds without errors
- ✅ Followed story recommendation to keep `GameScreen.onFinished` callback unchanged
- ✅ All acceptance criteria satisfied

#### Code Review Fixes Applied (2026-01-10)

- [FIXED] Added `passed` parameter to `GameRound` test helper init
- [FIXED] Removed unused `deck` variable in `GameResultTests`
- [FIXED] Added negative score edge case test in `RankTests`
- [FIXED] Updated `Rank.from()` to handle negative scores explicitly
- [FIXED] Improved factory tests with proper passed cards verification

### File List

- Kape/Kape/Data/Models/GameResult.swift (NEW)
- Kape/Kape/Features/Game/Logic/GameEngine.swift (MODIFIED)
- Kape/Kape/Features/Game/Logic/GameModels.swift (MODIFIED - test helper)
- Kape/KapeTests/Data/RankTests.swift (NEW)
- Kape/KapeTests/Data/GameResultTests.swift (NEW)
