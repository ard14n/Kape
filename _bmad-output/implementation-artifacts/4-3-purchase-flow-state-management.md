# Story 4.3: Purchase Flow & State Management

Status: done

## Story

As a Player,
I want to buy a deck and play it immediately,
so that there is no friction in the party flow.

## Acceptance Criteria

1. **Given** the Purchase Sheet
   **When** the user confirms purchase via FaceID
   **Then** the app must wait for the StoreKit `.success` result
   **And** crucially, it must UNLOCK the deck immediately in the UI without app restart
   **And** it must handle `.userCancelled` or `.error` states gracefully (Alerts)

## Tasks / Subtasks

- [x] **Task 1: Add purchase logic to StoreViewModel** (AC: 1)
  - [ ] Add `@Published var purchaseState: PurchaseState` enum (`idle`, `purchasing`, `succeeded`, `failed(Error)`, `cancelled`)
  - [ ] Add `@Published var alertMessage: String?` for user-facing error alerts
  - [ ] Add `func purchase(product: KapeProduct) async` method
  - [ ] Call `storeService.purchase(productId:)` and handle all `PurchaseResult` cases
  - [ ] On `.success`: immediately call `checkEntitlement()` to update `isVIPUnlocked`
  - [ ] On `.cancelled`: update `purchaseState` to `.cancelled`
  - [ ] On error: update `purchaseState` to `.failed(error)` and set `alertMessage`

- [x] **Task 2: Add transaction listener to StoreViewModel** (AC: 1)
  - [ ] Add `private var transactionTask: Task<Void, Never>?`
  - [ ] Add `func startListeningForTransactions()` method
  - [ ] Listen to `storeService.transactionUpdates` stream
  - [ ] On transaction update: call `checkEntitlement()` to refresh unlock state
  - [ ] Call `startListeningForTransactions()` in `loadProductsAndEntitlements()`
  - [ ] Add `deinit` to cancel `transactionTask`

- [x] **Task 3: Wire PurchaseSheetView to StoreViewModel** (AC: 1)
  - [ ] Modify `Kape/Kape/Features/Game/Views/DeckBrowserView.swift`
  - [ ] Replace the current `onPurchase: {}` stub with actual purchase call
  - [ ] Call `storeViewModel.purchase(product:)` from `onPurchase` callback
  - [ ] Dismiss sheet on success (when `purchaseState == .succeeded`)
  - [ ] Show `.alert` modifier for `alertMessage` when not nil

- [x] **Task 4: Add User Feedback for Purchase States** (AC: 1)
  - [ ] Add alert modifier to `DeckBrowserView` bound to `storeViewModel.alertMessage`
  - [ ] Clear `alertMessage` on dismiss to reset state
  - [ ] Consider haptic feedback on success (optional, use `HapticService` if desired)

- [x] **Task 5: Unit Tests** (AC: 1)
  - [ ] Create `KapeTests/Features/Store/StoreViewModel+PurchaseTests.swift`
  - [ ] Test `purchase()` with `.success` updates `isVIPUnlocked` to `true`
  - [ ] Test `purchase()` with `.cancelled` sets `purchaseState` to `.cancelled`
  - [ ] Test `purchase()` with error sets `alertMessage`
  - [ ] Test transaction listener updates entitlement on stream event

- [x] **Task 6: UI Tests** (AC: 1)
  - [ ] Update `KapeUITests/Features/Store/LockedContentUITests.swift`
  - [ ] Test purchase flow: tap locked deck → sheet appears → tap Purchase → deck unlocks
  - [ ] Test cancel flow: tap locked deck → sheet appears → tap Maybe Later → no change

## Dev Notes

### PurchaseState Enum

```swift
// Add to StoreViewModel.swift
enum PurchaseState: Equatable {
    case idle
    case purchasing
    case succeeded
    case failed(String) // Error message for alert
    case cancelled
}
```

### StoreViewModel Updates (CRITICAL)

```swift
// Kape/Kape/Features/Store/Logic/StoreViewModel.swift
import Foundation

@MainActor
final class StoreViewModel: ObservableObject {
    private let storeService: StoreServiceProtocol
    private var transactionTask: Task<Void, Never>?
    
    @Published private(set) var vipProduct: KapeProduct?
    @Published private(set) var isVIPUnlocked: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published var purchaseState: PurchaseState = .idle
    @Published var alertMessage: String?
    
    init(storeService: StoreServiceProtocol? = nil) {
        if let service = storeService {
            self.storeService = service
        } else {
            self.storeService = ServiceFactory.makeStoreService()
        }
    }
    
    deinit {
        transactionTask?.cancel()
    }
    
    func loadProductsAndEntitlements() async {
        isLoading = true
        defer { isLoading = false }
        
        startListeningForTransactions()
        
        do {
            let products = try await storeService.fetchProducts()
            vipProduct = products.first { $0.id == "com.kape.vip" }
        } catch {
            print("Failed to fetch products: \(error)")
        }
        
        await checkEntitlement()
    }
    
    func checkEntitlement() async {
        isVIPUnlocked = await storeService.isEntitled(productId: "com.kape.vip")
    }
    
    // MARK: - Story 4.3: Purchase Flow
    
    func purchase(product: KapeProduct) async {
        purchaseState = .purchasing
        
        do {
            let result = try await storeService.purchase(productId: product.id)
            
            switch result {
            case .success:
                await checkEntitlement()
                purchaseState = .succeeded
            case .cancelled:
                purchaseState = .cancelled
            case .pending:
                // Transaction pending approval (Ask to Buy, etc.)
                purchaseState = .idle
                alertMessage = "Purchase is pending approval."
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
            alertMessage = "Purchase failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Transaction Listener
    
    private func startListeningForTransactions() {
        transactionTask?.cancel()
        transactionTask = Task { [weak self] in
            guard let self = self else { return }
            for await productId in self.storeService.transactionUpdates {
                if productId == "com.kape.vip" {
                    await self.checkEntitlement()
                }
            }
        }
    }
}
```

### DeckBrowserView Integration (CRITICAL)

The `DeckBrowserView` already has `showPurchaseSheet` and `selectedProductForPurchase` state. Update the `PurchaseSheetView` integration:

```swift
// In DeckBrowserView.swift
.sheet(isPresented: $showPurchaseSheet) {
    if let product = selectedProductForPurchase {
        PurchaseSheetView(
            product: product,
            onPurchase: {
                await storeViewModel.purchase(product: product)
                if storeViewModel.purchaseState == .succeeded {
                    showPurchaseSheet = false
                }
            },
            onDismiss: {
                showPurchaseSheet = false
            }
        )
    }
}
.alert("Purchase Error", isPresented: Binding(
    get: { storeViewModel.alertMessage != nil },
    set: { if !$0 { storeViewModel.alertMessage = nil } }
)) {
    Button("OK") {
        storeViewModel.alertMessage = nil
    }
} message: {
    Text(storeViewModel.alertMessage ?? "")
}
.onChange(of: storeViewModel.purchaseState) { oldValue, newValue in
    if newValue == .succeeded {
        showPurchaseSheet = false
    }
}
```

### Testing Patterns from Story 4.1

```swift
// KapeTests/Features/Store/StoreViewModel+PurchaseTests.swift
import XCTest
@testable import Kape

@MainActor
final class StoreViewModelPurchaseTests: XCTestCase {
    var mockService: MockStoreService!
    var sut: StoreViewModel!
    
    override func setUp() {
        super.setUp()
        mockService = MockStoreService()
        sut = StoreViewModel(storeService: mockService)
    }
    
    func testPurchase_WhenSuccess_UnlocksVIP() async {
        // Given
        mockService.simulatedResult = .success
        let product = KapeProduct(id: "com.kape.vip", displayName: "VIP", displayPrice: "$2.99", productType: .nonConsumable)
        
        // When
        await sut.purchase(product: product)
        
        // Then
        XCTAssertTrue(sut.isVIPUnlocked)
        XCTAssertEqual(sut.purchaseState, .succeeded)
    }
    
    func testPurchase_WhenCancelled_StateIsCancelled() async {
        // Given
        mockService.simulatedResult = .cancelled
        let product = KapeProduct(id: "com.kape.vip", displayName: "VIP", displayPrice: "$2.99", productType: .nonConsumable)
        
        // When
        await sut.purchase(product: product)
        
        // Then
        XCTAssertFalse(sut.isVIPUnlocked)
        XCTAssertEqual(sut.purchaseState, .cancelled)
    }
    
    func testPurchase_WhenError_SetsAlertMessage() async {
        // Given
        mockService.shouldThrowOnPurchase = .purchaseFailed(NSError(domain: "", code: 0))
        let product = KapeProduct(id: "com.kape.vip", displayName: "VIP", displayPrice: "$2.99", productType: .nonConsumable)
        
        // When
        await sut.purchase(product: product)
        
        // Then
        XCTAssertNotNil(sut.alertMessage)
        XCTAssertTrue(sut.purchaseState.isFailed)
    }
}

// Add helper to PurchaseState for test assertions
extension PurchaseState {
    var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }
}
```

### Project Structure Notes

**Files to Modify:**
- `Kape/Kape/Features/Store/Logic/StoreViewModel.swift` - Add purchase logic and transaction listener
- `Kape/Kape/Features/Game/Views/DeckBrowserView.swift` - Wire up purchase callback and alerts

**New Files:**
- `KapeTests/Features/Store/StoreViewModel+PurchaseTests.swift` - Purchase flow unit tests

**Dependencies:**
- Uses existing `StoreServiceProtocol.purchase(productId:)` from Story 4.1
- Uses existing `PurchaseSheetView` from Story 4.2
- Uses existing `MockStoreService` for testing

### Architecture Compliance

- **@MainActor**: `StoreViewModel` is already `@MainActor` - all UI updates are thread-safe
- **Sendable**: All types used across async boundaries are `Sendable`
- **No Logic in Views**: All purchase logic lives in `StoreViewModel`, not in SwiftUI body
- **Dependency Injection**: `StoreServiceProtocol` injected for testability
- **Transaction Listener**: Properly cancelled in `deinit` to avoid memory leaks

### Previous Story Learnings (Story 4.2)

- Removed unused `import Combine` - check for unnecessary imports
- Lock icon logic was buggy - ensure state reflects actual purchase status
- Use `accessibilityIdentifier` for all interactive elements for UI testing
- File list must be complete in Dev Agent Record

### References

- [StoreServiceProtocol](file:///Users/ardianjahja/Desktop/Projekte/Kape/Kape/Kape/Core/Store/StoreServiceProtocol.swift)
- [MockStoreService](file:///Users/ardianjahja/Desktop/Projekte/Kape/Kape/Kape/Data/Services/MockStoreService.swift)
- [StoreViewModel](file:///Users/ardianjahja/Desktop/Projekte/Kape/Kape/Kape/Features/Store/Logic/StoreViewModel.swift)
- [PurchaseSheetView](file:///Users/ardianjahja/Desktop/Projekte/Kape/Kape/Kape/Features/Store/Views/PurchaseSheetView.swift)
- [DeckBrowserView](file:///Users/ardianjahja/Desktop/Projekte/Kape/Kape/Kape/Features/Game/Views/DeckBrowserView.swift)
- [Epic 4 Story 4.3](file:///Users/ardianjahja/Desktop/Projekte/Kape/_bmad-output/planning-artifacts/epics.md#L384)
- [Apple StoreKit 2 Purchases](https://developer.apple.com/documentation/storekit/in-app_purchase/implementing_a_store_in_your_app_using_the_storekit_api)

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List
- Implemented `StoreViewModel` purchase logic with `PurchaseState` enum.
- Added transaction listener to handle external updates and refresh `isVIPUnlocked` immediately.
- Integrated `PresentationSheetView` with `DeckBrowserView`, including success/cancel/error handling and alerts.
- Added unit tests for purchase flow and transaction listener.
- Added UI tests for purchase success and cancel flows using `MockStoreService` defaults.
- Updated `MockStoreService` with `emitTransaction` helper for testing consistency.

### File List
- Kape/Kape/Features/Store/Logic/StoreViewModel.swift
- KapeTests/Features/Store/StoreViewModel+PurchaseTests.swift
- Kape/Kape/Features/Game/Views/DeckBrowserView.swift
- KapeUITests/Features/Store/LockedContentUITests.swift
- Kape/Kape/Data/Services/MockStoreService.swift

### Code Review Fixes (AI)
- [x] Refactored `StoreViewModel` to use `static let vipProductId` constant instead of hardcoded strings.
- [x] Improved `loadProductsAndEntitlements` error handling to update `alertMessage` instead of silent failure.
- [x] Simplified `DeckBrowserView` sheet dismissal logic to rely on `purchaseState` changes (removed redundant closure logic).
- [x] Updated Unit Tests to use new constants.

