import XCTest
@testable import Kape

/// Unit tests for StoreViewModel restore purchases functionality
/// Story 4.4: Restore Purchases
@MainActor
final class StoreViewModelRestoreTests: XCTestCase {
    var mockService: MockStoreService!
    var sut: StoreViewModel!
    
    override func setUp() {
        super.setUp()
        mockService = MockStoreService()
        sut = StoreViewModel(storeService: mockService)
    }
    
    override func tearDown() {
        mockService = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Restore Success Tests
    
    func testRestorePurchases_WhenSuccess_UpdatesIsVIPUnlocked() async {
        // Given
        XCTAssertFalse(sut.isVIPUnlocked, "VIP should not be unlocked initially")
        
        // When
        await sut.restorePurchases()
        
        // Then
        XCTAssertTrue(sut.isVIPUnlocked, "VIP should be unlocked after successful restore")
    }
    
    func testRestorePurchases_WhenSuccess_ShowsSuccessAlert() async {
        // When
        await sut.restorePurchases()
        
        // Then
        XCTAssertEqual(sut.alertMessage, "Blerjet u rikthyen!")
    }
    
    func testRestorePurchases_SetsIsRestoringDuringOperation() async {
        // Given
        XCTAssertFalse(sut.isRestoring, "Should not be restoring initially")
        
        // When/Then - isRestoring should be false after completion due to defer
        await sut.restorePurchases()
        XCTAssertFalse(sut.isRestoring, "Should not be restoring after completion")
    }
    
    // MARK: - Restore Failure Tests
    
    func testRestorePurchases_WhenError_ShowsErrorAlert() async {
        // Given
        mockService.shouldThrowOnRestore = .purchaseFailed(NSError(domain: "TestError", code: 1))
        
        // When
        await sut.restorePurchases()
        
        // Then
        XCTAssertNotNil(sut.alertMessage)
        XCTAssertTrue(sut.alertMessage!.contains("Rikthimi dështoi"), "Alert should indicate restore failure")
    }
    
    func testRestorePurchases_WhenError_DoesNotUnlockVIP() async {
        // Given
        mockService.shouldThrowOnRestore = .purchaseFailed(NSError(domain: "TestError", code: 1))
        
        // When
        await sut.restorePurchases()
        
        // Then
        XCTAssertFalse(sut.isVIPUnlocked, "VIP should remain locked after failed restore")
    }
    
    func testRestorePurchases_WhenError_ResetsIsRestoring() async {
        // Given
        mockService.shouldThrowOnRestore = .purchaseFailed(NSError(domain: "TestError", code: 1))
        
        // When
        await sut.restorePurchases()
        
        // Then
        XCTAssertFalse(sut.isRestoring, "Should not be restoring after error")
    }
}
