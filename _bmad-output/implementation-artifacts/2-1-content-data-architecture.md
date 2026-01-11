# Story 2.1: Content Data Architecture

Status: review

## Story

As a Developer,
I want a robust data layer for loading Decks and Cards,
So that the app can function offline with reliable content.

## Acceptance Criteria

1. **Given** the `Deck` and `Card` models
   **When** `decks.json` is loaded from the Bundle
   **Then** it must parse correctly into Swift structs
   **And** models must use `CodingKeys` to map `snake_case` JSON → `camelCase` Swift

2. **Given** malformed or missing JSON
   **When** parsing is attempted
   **Then** it must fail gracefully with descriptive errors
   **And** unit tests must validate this behavior

3. **Given** the `DeckService`
   **When** initialization occurs
   **Then** all decks must be available in memory immediately (synchronous load allowed for local JSON)
   **And** the service must expose a `decks: [Deck]` property

4. **Given** a `Deck` has `isPro: true`
   **When** displayed
   **Then** the model must correctly expose this property for UI lock logic (Epic 4)

5. **Given** the architecture requirement for `@Observable`
   **When** `DeckService` is implemented
   **Then** it must use `@Observable` macro for state management
   **And** be injectable via SwiftUI environment

## Tasks / Subtasks

- [x] Task 1: Expand Deck & Card Models (AC: 1, 4)
  - [x] Update `/Data/Models/Deck.swift` with full properties
  - [x] Add `description: String`, `difficulty: Int`, `isPro: Bool` to `Deck`
  - [x] Add `iconName: String` for SF Symbol support with neon glow
  - [x] Add `CodingKeys` enum for snake_case mapping
  - [x] Update `Card` with optional metadata fields

- [x] Task 2: Create DeckService (AC: 3, 5)
  - [x] Create `/Data/Services/DeckService.swift`
  - [x] Implement `@Observable` class with `decks: [Deck]` property
  - [x] Load and parse `decks.json` from Bundle in init
  - [x] Make synchronous (blocking) load acceptable for local JSON
  - [x] Expose computed properties: `freeDecks`, `proDecks`

- [x] Task 3: Create decks.json Content File (AC: 1, 2)
  - [x] Create `/Data/Resources/decks.json`
  - [x] Use snake_case for all JSON keys
  - [x] Include 2+ test decks: "Mix Shqip" (free), "Muzikë" (pro)
  - [x] Each deck must have 5+ cards for testing

- [x] Task 4: Error Handling & Validation (AC: 2)
  - [x] Implement descriptive `DecodingError` handling
  - [x] Add `fatalError` or fallback for missing bundle resource
  - [x] Create unit test for malformed JSON parsing

- [x] Task 5: Unit Tests (AC: 1, 2, 3)
  - [x] Create `/KapeTests/Data/DeckServiceTests.swift`
  - [x] Test successful JSON parsing
  - [x] Test missing file handling
  - [x] Test malformed JSON handling
  - [x] Test `freeDecks` / `proDecks` computed properties
  - [x] [AI-Fix] Refactor tests to use `init(decks:)` for deterministic logic verification (no flaky bundle tests)

- [x] Task 6: Environment Integration
  - [x] Add `DeckService` to environment in `KapeApp.swift`
  - [x] Verify accessibility from `ContentView`
  - [x] Create preview helpers for tests

## Dev Notes

### CRITICAL: Architecture Compliance

**File Locations (MUST follow exactly):**
- `Deck.swift` → `/Data/Models/Deck.swift` ✅ EXISTS (expand it)
- `DeckService.swift` → `/Data/Services/DeckService.swift` ← NEW
- `decks.json` → `/Data/Resources/decks.json` ← NEW
- Tests → `/KapeTests/Data/DeckServiceTests.swift` ← NEW

**Pattern Conformance:**
- JSON uses `snake_case` (e.g., `icon_name`, `is_pro`)
- Swift uses `camelCase` with `CodingKeys` mapping
- Use `@Observable` macro (NOT `ObservableObject`)
- Use `@Environment` for injection (NOT singletons)

### Technical Requirements

**JSON Schema (Defined in Architecture):**
```json
{
  "decks": [
    {
      "id": "mix-shqip",
      "title": "Mix Shqip",
      "description": "Gjithçka shqip – filma, muzikë, ushqim!",
      "icon_name": "sparkles",
      "difficulty": 1,
      "is_pro": false,
      "cards": [
        { "id": "ms-001", "text": "Qebapa" },
        { "id": "ms-002", "text": "Flori Mumajesi" }
      ]
    }
  ]
}
```

**Swift Model Expansion:**
```swift
struct Deck: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let iconName: String  // SF Symbol name
    let difficulty: Int   // 1-3
    let isPro: Bool
    let cards: [Card]
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, cards, difficulty
        case iconName = "icon_name"
        case isPro = "is_pro"
    }
}

struct Card: Identifiable, Codable, Equatable {
    let id: String
    let text: String
}
```

**DeckService Pattern:**
```swift
import Observation

@Observable
final class DeckService {
    private(set) var decks: [Deck] = []
    
    var freeDecks: [Deck] { decks.filter { !$0.isPro } }
    var proDecks: [Deck] { decks.filter { $0.isPro } }
    
    init(bundle: Bundle = .main) {
        loadDecks(from: bundle)
    }
    
    private func loadDecks(from bundle: Bundle) {
        // Synchronous Bundle load is acceptable for local JSON
    }
}
```

### Previous Story Intelligence

**From Story 1.5 Code Review:**
- Use `Task { @MainActor in }` instead of `DispatchQueue.main.async`
- Remove all debug `print()` statements before commit
- Add proper documentation comments
- Follow existing project patterns in `/Core/` folder

**Established Patterns:**
- Colors defined in `/Core/DesignSystem/Colors.swift`
- Use existing `.neonGlow()` modifier for deck icons
- HapticService and AudioService patterns show proper `@Observable` usage

### File Structure After Implementation

```
Kape/
├── Data/
│   ├── Models/
│   │   └── Deck.swift           ← UPDATED (add description, isPro, etc.)
│   ├── Services/                ← NEW folder
│   │   └── DeckService.swift    ← NEW
│   └── Resources/
│       ├── Sounds/              ← EXISTS
│       └── decks.json           ← NEW

KapeTests/
├── Data/                        ← NEW folder
│   └── DeckServiceTests.swift   ← NEW
```

### References

- [Source: _bmad-output/planning-artifacts/architecture.md#Data Architecture]
- [Source: _bmad-output/planning-artifacts/prd.md#Content Engine]
- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.1]
- [Source: Kape/Data/Models/Deck.swift] - Existing stub model

### Integration Notes

**Forward Dependencies (Epic 2):**
- Story 2.2 (Deck Browser UI) will consume `DeckService`
- Story 2.3 (Deck Logic) will use shuffling on `Deck.cards`
- Story 2.4 (Content Population) will expand `decks.json` to 50+ cards per deck

**Backward Dependencies (Epic 1):**
- `GameEngine` currently uses hardcoded cards - will be updated in Story 2.3 to consume Decks

## Dev Agent Record

### Agent Model Used

Claude 4 Sonnet (Amelia - Dev Agent)

### Debug Log References

- Updated Deck model references in 8 files to accommodate new model signature

### Completion Notes List

- ✅ Expanded `Deck.swift` with `description`, `iconName`, `difficulty`, `isPro` and `CodingKeys`
- ✅ Created `DeckService.swift` with `@Observable` macro and error handling
- ✅ Created `decks.json` with 3 test decks (Mix Shqip, Gurbet, Muzikë)
- ✅ Created `DeckServiceTests.swift` with 11 unit tests
- ✅ Integrated DeckService into SwiftUI environment in `KapeApp.swift`
- ✅ Fixed backward compatibility: Updated Deck usages in ContentView, GameScreen, GameModels, Factories, AudioServiceTests, HapticServiceTests
- ✅ [Review] Refactored `DeckServiceTests` to use `init(decks:)` instead of flaky `Bundle` tests
- ✅ All 20+ tests passing 100%

### File List

- Kape/Data/Models/Deck.swift (UPDATED)
- Kape/Data/Services/DeckService.swift (NEW)
- Kape/Data/Resources/decks.json (NEW)
- Kape/KapeApp.swift (UPDATED)
- Kape/ContentView.swift (UPDATED - Deck model compatibility)
- Kape/Features/Game/Views/GameScreen.swift (UPDATED - Deck model compatibility)
- Kape/Features/Game/Logic/GameModels.swift (UPDATED - Deck model compatibility)
- KapeTests/Data/DeckServiceTests.swift (NEW)
- KapeTests/Helpers/Factories.swift (UPDATED - Deck model compatibility)
- KapeTests/Core/Audio/AudioServiceTests.swift (UPDATED - Deck model compatibility)
- KapeTests/Core/Haptics/HapticServiceTests.swift (UPDATED - Deck model compatibility)

## Change Log

- 2026-01-10: Code Review completed - tests fixed
- 2026-01-10: Story 2.1 implementation complete
- 2026-01-10: Story 2.1 created - Content Data Architecture
