import XCTest
@testable import Kape

@MainActor
final class StoreViewModelTests: XCTestCase {
    
    var viewModel: StoreViewModel!
    var mockStore: MockStoreService!
    
    override func setUp() async throws {
        mockStore = MockStoreService()
        viewModel = await StoreViewModel(storeService: mockStore)
    }
    
    func testCheckEntitlement_WhenEntitled_UpdatesStatus() async {
        // Given
        mockStore.purchasedProductIds = ["com.kape.vip"]
        
        // When
        await viewModel.checkEntitlement()
        
        // Then
        let isUnlocked = await viewModel.isVIPUnlocked
        XCTAssertTrue(isUnlocked)
    }
    
    func testCheckEntitlement_WhenNotEntitled_StatusIsLocked() async {
        // Given
        mockStore.purchasedProductIds = []
        
        // When
        await viewModel.checkEntitlement()
        
        // Then
        let isUnlocked = await viewModel.isVIPUnlocked
        XCTAssertFalse(isUnlocked)
    }
    
    // CR4.2-03 FIX: Added test for loadProductsAndEntitlements
    func testLoadProductsAndEntitlements_SetsVIPProduct() async {
        // Given
        let expectedProduct = KapeProduct(
            id: "com.kape.vip",
            displayName: "VIP Deck",
            displayPrice: "$2.99",
            productType: .nonConsumable
        )
        mockStore.mockProducts = [expectedProduct]
        mockStore.purchasedProductIds = []
        
        // When
        await viewModel.loadProductsAndEntitlements()
        
        // Then
        XCTAssertNotNil(viewModel.vipProduct)
        XCTAssertEqual(viewModel.vipProduct?.id, "com.kape.vip")
        XCTAssertFalse(viewModel.isVIPUnlocked)
    }
    
    // CR4.2-03 FIX: Test for error handling path
    func testLoadProductsAndEntitlements_WhenFetchFails_ProductIsNil() async {
        // Given
        mockStore.simulatedError = StoreServiceError.productNotFound
        
        // When
        await viewModel.loadProductsAndEntitlements()
        
        // Then
        XCTAssertNil(viewModel.vipProduct)
    }
}
