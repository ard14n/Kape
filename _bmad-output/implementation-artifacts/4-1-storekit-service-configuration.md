# Story 4.1: StoreKit Service Configuration

Status: done

## Story

As a Developer,
I want to establish the `StoreServiceProtocol` and a robust `MockStoreService`,
so that we can build and test the entire UI flow without waiting for App Store Connect.

## Acceptance Criteria

1. **Given** `StoreServiceProtocol`
   **When** defined
   **Then** it must abstract `fetchProducts()`, `purchase(productId:)`, `currentEntitlements`, and a `transactionUpdates` stream using `async/await`.

2. **Given** `MockStoreService`
   **When** initialized
   **Then** it must return configured mock products (e.g., "VIP Deck") immediately.
   **And** allow simulating `.success`, `.failed`, and `.cancelled` purchase results.
   **And** allow resetting purchase state for testing isolation.

3. **Given** the dependency injection pattern
   **When** `ServiceFactory` is updated
   **Then** it must provide `makeStoreService()` that returns `StoreServiceProtocol`.

4. **Given** the Xcode project
   **When** configured for StoreKit testing
   **Then** a `StoreKitConfiguration.storekit` file must exist with "VIP Deck" product defined.

## Tasks / Subtasks

- [x] **Task 1: Define StoreService Protocol** (AC: 1)
  - [x] Create `Kape/Kape/Core/Store/StoreServiceProtocol.swift`
  - [x] Define `KapeProduct` model (id, displayName, displayPrice, productType)
  - [x] Define `StoreServiceError` enum (productNotFound, purchaseFailed, etc.)
  - [x] Define protocol methods (see Dev Notes)

- [x] **Task 2: Create Mock Implementation** (AC: 2)
  - [x] Create `Kape/Kape/Data/Services/MockStoreService.swift`
  - [x] Implement in-memory `purchasedProductIds: Set<String>`
  - [x] Add `simulateResult: PurchaseResult` toggle
  - [x] Add `reset()` for test isolation

- [x] **Task 3: Create StoreKit Configuration File** (AC: 4)
  - [x] Add `Kape/StoreKitConfiguration.storekit` via Xcode (File > New > StoreKit Configuration)
  - [x] Define product: `com.kape.vip` (Non-Consumable, $2.99)
  - [x] Enable "Enable StoreKit Testing in Xcode" scheme option

- [x] **Task 4: Update ServiceFactory** (AC: 3)
  - [x] Modify `Kape/Kape/Core/Interfaces/ServiceFactory.swift`
  - [x] Add `static func makeStoreService() -> StoreServiceProtocol`

- [x] **Task 5: Unit Tests**
  - [x] Create `KapeTests/Core/Store/MockStoreServiceTests.swift`
  - [x] Test `fetchProducts()` returns mock products
  - [x] Test `purchase()` with success/failure/cancelled
  - [x] Test `reset()` clears state

## Dev Notes

### Protocol Definition (Critical)

```swift
// Kape/Kape/Core/Store/StoreServiceProtocol.swift
import Foundation

struct KapeProduct: Identifiable, Sendable {
    let id: String
    let displayName: String
    let displayPrice: String
    let productType: ProductType
    
    enum ProductType: Sendable {
        case nonConsumable
    }
}

enum PurchaseResult: Sendable {
    case success
    case cancelled
    case pending
}

enum StoreServiceError: Error, Sendable {
    case productNotFound
    case purchaseFailed(Error)
    case notEntitled
}

protocol StoreServiceProtocol: Sendable {
    /// Fetches available products from the store.
    func fetchProducts() async throws -> [KapeProduct]
    
    /// Attempts to purchase a product.
    func purchase(productId: String) async throws -> PurchaseResult
    
    /// Checks if a product is currently entitled.
    func isEntitled(productId: String) async -> Bool
    
    /// Async stream for real-time transaction updates.
    var transactionUpdates: AsyncStream<String> { get }
}
```

### Mock Implementation Pattern

```swift
// KapeTests/Helpers/Mocks/MockStoreService.swift
final class MockStoreService: StoreServiceProtocol, @unchecked Sendable {
    var purchasedProductIds: Set<String> = []
    var simulatedResult: PurchaseResult = .success
    var shouldThrowOnPurchase: StoreServiceError?
    
    func fetchProducts() async throws -> [KapeProduct] {
        return [KapeProduct(id: "com.kape.vip", displayName: "VIP Deck", displayPrice: "$2.99", productType: .nonConsumable)]
    }
    
    func purchase(productId: String) async throws -> PurchaseResult {
        if let error = shouldThrowOnPurchase { throw error }
        if simulatedResult == .success { purchasedProductIds.insert(productId) }
        return simulatedResult
    }
    
    func isEntitled(productId: String) async -> Bool {
        purchasedProductIds.contains(productId)
    }
    
    var transactionUpdates: AsyncStream<String> {
        AsyncStream { _ in } // Empty stream for mock
    }
    
    func reset() {
        purchasedProductIds.removeAll()
        simulatedResult = .success
        shouldThrowOnPurchase = nil
    }
}
```

### ServiceFactory Update

```swift
// Add to ServiceFactory.swift
static func makeStoreService() -> StoreServiceProtocol {
    // For now, return mock. Real implementation in Story 4.5.
    return MockStoreService()
}
```

### StoreKit Configuration File

Create via Xcode: **File > New > File... > StoreKit Configuration File**

**Product Definition:**
- Reference Name: `VIP Deck`
- Product ID: `com.kape.vip`
- Type: Non-Consumable
- Price: $2.99

**Enable in Scheme:**
Product > Scheme > Edit Scheme > Run > Options > StoreKit Configuration: `StoreKitConfiguration.storekit`

### Integration with DeckService (Future Story 4.2)

The `DeckService.proDecks` computed property currently returns all decks where `isPro == true`. In Story 4.2, this will be enhanced to check `StoreServiceProtocol.isEntitled("com.kape.vip")` to determine locked/unlocked state.

**DO NOT modify `DeckService` in this story.** Focus only on protocol + mock + tests.

### Previous Story Learning (Story 3.4)

- Use `Sendable` for all protocol types to ensure thread safety.
- Keep mock implementations in `KapeTests/Helpers/Mocks/`.
- Follow `@unchecked Sendable` pattern for mocks with mutable state.

### References

- [PRD: Monetization FR13-FR15](file:///Users/ardianjahja/Desktop/Projekte/Kape/_bmad-output/planning-artifacts/prd.md#L244)
- [Architecture: Data Layer](file:///Users/ardianjahja/Desktop/Projekte/Kape/_bmad-output/planning-artifacts/architecture.md#L102)
- [Epic 4: Story 4.1](file:///Users/ardianjahja/Desktop/Projekte/Kape/_bmad-output/planning-artifacts/epics.md#L352)
- [ServiceFactory.swift](file:///Users/ardianjahja/Desktop/Projekte/Kape/Kape/Kape/Core/Interfaces/ServiceFactory.swift)
- [DeckService.swift](file:///Users/ardianjahja/Desktop/Projekte/Kape/Kape/Kape/Data/Services/DeckService.swift)
- [Apple StoreKit 2 Docs](https://developer.apple.com/documentation/storekit/in-app_purchase)

## Dev Agent Record

### Agent Model Used
Gemini 2.5 Pro

### Debug Log References
N/A

### Completion Notes List
- All 5 tasks completed
- Protocol, mock, and tests implemented
- Code review fixes applied (Equatable, @testable import removed)

### File List
- `Kape/Kape/Core/Store/StoreServiceProtocol.swift` [NEW]
- `Kape/Kape/Data/Services/MockStoreService.swift` [NEW]
- `Kape/Kape/Core/Interfaces/ServiceFactory.swift` [MODIFIED]
- `Kape/StoreKitConfiguration.storekit` [NEW]
- `KapeTests/Core/Store/MockStoreServiceTests.swift` [NEW]
- `KapeTests/Helpers/Factories.swift` [MODIFIED]
