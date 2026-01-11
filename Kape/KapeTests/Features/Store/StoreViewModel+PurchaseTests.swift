
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
        let product = KapeProduct(id: StoreViewModel.vipProductId, displayName: "VIP", displayPrice: "$2.99", productType: .nonConsumable)
        
        // When
        await sut.purchase(product: product)
        
        // Then
        XCTAssertTrue(sut.isVIPUnlocked)
        XCTAssertEqual(sut.purchaseState, .succeeded)
    }
    
    func testPurchase_WhenCancelled_StateIsCancelled() async {
        // Given
        mockService.simulatedResult = .cancelled
        let product = KapeProduct(id: StoreViewModel.vipProductId, displayName: "VIP", displayPrice: "$2.99", productType: .nonConsumable)
        
        // When
        await sut.purchase(product: product)
        
        // Then
        XCTAssertFalse(sut.isVIPUnlocked)
        XCTAssertEqual(sut.purchaseState, .cancelled)
    }
    
    func testPurchase_WhenError_SetsAlertMessage() async {
        // Given
        mockService.shouldThrowOnPurchase = .purchaseFailed(NSError(domain: "", code: 0))
        let product = KapeProduct(id: StoreViewModel.vipProductId, displayName: "VIP", displayPrice: "$2.99", productType: .nonConsumable)
        
        // When
        await sut.purchase(product: product)
        
        // Then
        XCTAssertNotNil(sut.alertMessage)
        XCTAssertTrue(sut.purchaseState.isFailed)
    }
    func testTransactionListener_WhenUpdateReceived_RefreshesEntitlement() async {
        // Given
        // Ensure stream is accessed so continuation is captured
        _ = mockService.transactionUpdates
        
        let product = KapeProduct(id: StoreViewModel.vipProductId, displayName: "VIP", displayPrice: "$2.99", productType: .nonConsumable)
        mockService.mockProducts = [product]
        
        // When
        // Start listener via loadProductsAndEntitlements
        await sut.loadProductsAndEntitlements()
        
        // Simulate external purchase (e.g. from another device)
        mockService.purchasedProductIds.insert(StoreViewModel.vipProductId)
        mockService.emitTransaction(StoreViewModel.vipProductId)
        
        // Allow async task to process
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertTrue(sut.isVIPUnlocked)
    }
}

// Add helper to PurchaseState for test assertions
extension PurchaseState {
    var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }
}

// MARK: - Pending State Tests (TEA Automation Expansion)
extension StoreViewModelPurchaseTests {
    func testPurchase_WhenPending_SetsAlertAndResetsState() async {
        // Given
        mockService.simulatedResult = .pending
        let product = KapeProduct(id: StoreViewModel.vipProductId, displayName: "VIP", displayPrice: "$2.99", productType: .nonConsumable)
        
        // When
        await sut.purchase(product: product)
        
        // Then
        XCTAssertEqual(sut.purchaseState, .idle) // Resets to idle on pending
        XCTAssertNotNil(sut.alertMessage)
        XCTAssertTrue(sut.alertMessage?.contains("pending") == true)
    }
}
