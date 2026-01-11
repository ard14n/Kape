# Bug: Malloc Crash in DeckFactory Tests

Status: **wontfix** (iOS Runtime Bug)

## Problem Description

Several unit tests crash with a memory allocation error when using `DeckFactory.make()`:

```
Kape(XXXX,0x204a52bc0) malloc: *** error for object 0x204a52bc0: pointer being freed was not allocated
```

**Important:** This crash ONLY occurs on **physical devices** (iPhone von Ardian). Tests pass 100% on the **iOS Simulator**.

## Investigation Findings

| Attempted Fix | Result |
|---------------|--------|
| Replace UUID() with atomic counters | ❌ Still crashes |
| Add @MainActor to DeckService | ❌ Still crashes |
| Add @MainActor to DeckServiceTests | ❌ Still crashes |
| **Refactor to ObservableObject (remove macro)** | ❌ **Still crashes** |

**Conclusion:**
The crash persists even after completely removing the `@Observable` macro and converting the app to use `ObservableObject` / `@Published`. This rules out the Swift 5.9 Observation framework as the root cause.

The issue is definitively a **low-level iOS Runtime / Memory Management bug** on the specific physical device (`iPhone von Ardian`), likely related to:
1. `malloc` corruption in the test runner process
2. Specific arm64 optimizations interacting with `XCTest`

**Action:**
- Kept the `ObservableObject` refactor as it is more stable and compatible.
- Kept thread-safe factories.
- Use Simulator for reliable testing.


The crash occurs when tests create multiple `Deck` objects using `DeckFactory.make()`. Possible causes:

1. **UUID Generation**: `UUID().uuidString` may have thread-safety issues in test parallelization
2. **Struct Copy Semantics**: Swift's copy-on-write may have edge cases with nested arrays (`[Card]`)
3. **Test Parallelization**: XCTest may run tests in parallel causing memory contention

## Investigation Steps

- [ ] Add `@MainActor` to affected tests
- [ ] Replace `UUID().uuidString` with static test IDs
- [ ] Check if disabling test parallelization resolves the issue
- [ ] Run tests in isolation vs full suite
- [ ] Use Instruments with Address Sanitizer to identify root cause

## Acceptance Criteria

1. **Given** the affected tests
   **When** run on physical device (iPhone von Ardian)
   **Then** all tests pass without malloc crashes

2. **Given** the full KapeTests suite
   **When** run sequentially
   **Then** no memory-related crashes occur

## Technical Notes

### Relevant Files

- `KapeTests/Helpers/Factories.swift` - Contains DeckFactory and CardFactory
- `Kape/Data/Models/Deck.swift` - Deck and Card structs
- `Kape/Data/Services/DeckService.swift` - Uses Deck models

### DeckFactory Implementation

```swift
struct DeckFactory {
    static func make(
        id: String = UUID().uuidString,  // <-- Potential issue
        title: String = "Test Deck",
        description: String = "A test deck",
        iconName: String = "star.fill",
        difficulty: Int = 1,
        isPro: Bool = false,
        cards: [Card]? = nil
    ) -> Deck {
        let defaultCards = [
            CardFactory.make(text: "Card 1"),
            CardFactory.make(text: "Card 2"),
            CardFactory.make(text: "Card 3")
        ]
        return Deck(...)
    }
}
```

### Potential Fix

Replace UUID generation with deterministic test IDs:

```swift
private static var counter = 0

static func make(...) -> Deck {
    counter += 1
    let testId = id ?? "test-deck-\(counter)"
    // ...
}
```

## Priority

**Medium** - Tests are failing but this doesn't affect production code. The ShuffleTests (Story 2.3) work correctly.

## Labels

- bug
- testing
- memory-management
- tech-debt
