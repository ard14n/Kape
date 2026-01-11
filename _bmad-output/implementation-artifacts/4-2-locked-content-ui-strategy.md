# Story 4.2: Locked Content UI Strategy

Status: done

## Story

As a Player,
I want to clearly see which decks are premium and locked,
so that I feel the desire to unlock them and understand the value proposition.

## Acceptance Criteria

1. **Given** the Deck Browser
   **When** a deck is PRO (VIP) and NOT purchased
   **Then** it must show a "Lock" icon overlay
   **And** the visuals should be slightly dimmed to indicate "unavailable"

2. **Given** a locked PRO deck in the Deck Browser
   **When** tapped
   **Then** it must trigger the Purchase Sheet instead of starting the game
   **And** the purchase sheet must show the product price and name

3. **Given** the Purchase Sheet
   **When** displayed for a locked deck
   **Then** it must display the product display name ("VIP Deck")
   **And** it must display the price ("$2.99")
   **And** it must have a "Purchase" button and "Cancel/Maybe Later" option

4. **Given** a PRO deck that IS purchased/entitled
   **When** the Deck Browser loads
   **Then** the deck must appear unlocked (no lock icon, no dimming)
   **And** tapping it must start the game normally

## Tasks / Subtasks

- [x] **Task 1: Create PurchaseSheetView** (AC: 2, 3)
  - [x] Create `Kape/Kape/Features/Store/Views/PurchaseSheetView.swift`
  - [x] Accept `KapeProduct` as input for display name and price
  - [x] Add "Purchase" button with `.neonGlow()` styling
  - [x] Add "Maybe Later" dismiss button
  - [x] Include async `onPurchase` callback for Story 4.3 integration

- [x] **Task 2: Create StoreViewModel** (AC: 4)
  - [x] Create `Kape/Kape/Features/Store/Logic/StoreViewModel.swift`
  - [x] Inject `StoreServiceProtocol` via initializer
  - [x] Add `@Published var isVIPUnlocked: Bool` property
  - [x] Add `func checkEntitlement()` async method
  - [x] Add `func fetchVIPProduct()` async method

- [x] **Task 3: Update DeckRowView with Locked State** (AC: 1)
  - [x] Modify `Kape/Kape/Features/Game/Views/Components/DeckRowView.swift`
  - [x] Add `isLocked: Bool` parameter (derived from `deck.isPro && !isVIPUnlocked`)
  - [x] Apply 50% opacity dimming when `isLocked == true`
  - [x] Ensure existing `lock.fill` icon displays with `.neonRed` color

- [x] **Task 4: Update DeckBrowserView for Pro Decks** (AC: 1, 2, 4)
  - [x] Modify `Kape/Kape/Features/Game/Views/DeckBrowserView.swift`
  - [x] Inject `StoreViewModel` as `@StateObject`
  - [x] Add pro decks section displaying `deckService.proDecks`
  - [x] Add `@State private var showPurchaseSheet: Bool`
  - [x] Add `@State private var selectedProductForPurchase: KapeProduct?`
  - [x] Implement tap handler: if locked → show sheet; if unlocked → select deck

- [x] **Task 5: Unit Tests**
  - [x] Create `KapeTests/Features/Store/StoreViewModelTests.swift`
  - [x] Test `checkEntitlement()` returns correct state from mock
  - [x] Test VIP unlock state updates correctly
  - [x] Update `DeckRowViewTests.swift` to test locked/unlocked visual states
  - [x] Update `DeckBrowserViewTests.swift` to test pro deck display

## Dev Notes

(Moved to Dev Agent Record for brevity)

## Dev Agent Record

### Agent Model Used

gemini-2.5-pro

### Code Review Fixes Applied (2026-01-11)

- **CR4.2-01 (HIGH)**: Fixed lock icon logic in `DeckRowView.swift` to use `isLocked` instead of `deck.isPro` (AC4 compliance)
- **CR4.2-03 (MEDIUM)**: Added `testLoadProductsAndEntitlements_SetsVIPProduct()` and `testLoadProductsAndEntitlements_WhenFetchFails_ProductIsNil()` to `StoreViewModelTests.swift`
- **CR4.2-05 (LOW)**: Removed unused `import Combine` from `StoreViewModel.swift`
- **CR4.2-02/04 (MEDIUM)**: Populated File List below

### File List

**New Files:**
- `Kape/Kape/Features/Store/Views/PurchaseSheetView.swift`
- `Kape/Kape/Features/Store/Logic/StoreViewModel.swift`
- `Kape/Kape/Features/Game/Logic/DeckBrowserViewModel.swift`
- `Kape/KapeTests/Features/Store/StoreViewModelTests.swift`
- `Kape/KapeTests/Features/Game/Logic/DeckBrowserViewModelTests.swift`
- `Kape/KapeUITests/Features/Store/LockedContentUITests.swift`

**Modified Files:**
- `Kape/Kape/Features/Game/Views/DeckBrowserView.swift`
- `Kape/Kape/Features/Game/Views/Components/DeckRowView.swift`
- `Kape/Kape/Data/Services/MockStoreService.swift`
- `Kape/KapeTests/Features/Game/Views/DeckRowViewTests.swift`
- `Kape/KapeTests/Features/Game/Views/DeckBrowserViewTests.swift`
