import XCTest
@testable import Kape

final class MockStoreServiceTests: XCTestCase {
    var service: MockStoreService!
    
    override func setUp() {
        super.setUp()
        service = MockStoreService()
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    // MARK: - Fetch Products
    
    func testFetchProducts_ReturnsMockProducts() async throws {
        let products = try await service.fetchProducts()
        
        XCTAssertEqual(products.count, 1)
        XCTAssertEqual(products.first?.id, "com.kape.vip")
        XCTAssertEqual(products.first?.displayName, "VIP Deck")
    }
    
    // MARK: - Purchase Flow
    
    func testPurchase_Success_UpdatesEntitlement() async throws {
        // Given
        service.simulatedResult = .success
        let productId = "com.kape.vip"
        
        // When
        let result = try await service.purchase(productId: productId)
        
        // Then
        XCTAssertEqual(result, .success)
        let isEntitled = await service.isEntitled(productId: productId)
        XCTAssertTrue(isEntitled)
    }
    
    func testPurchase_Cancelled_DoesNotEntitle() async throws {
        // Given
        service.simulatedResult = .cancelled
        let productId = "com.kape.vip"
        
        // When
        let result = try await service.purchase(productId: productId)
        
        // Then
        XCTAssertEqual(result, .cancelled)
        let isEntitled = await service.isEntitled(productId: productId)
        XCTAssertFalse(isEntitled)
    }
    
    func testPurchase_Pending_DoesNotEntitle() async throws {
        // Given
        service.simulatedResult = .pending
        let productId = "com.kape.vip"
        
        // When
        let result = try await service.purchase(productId: productId)
        
        // Then
        XCTAssertEqual(result, .pending)
        let isEntitled = await service.isEntitled(productId: productId)
        XCTAssertFalse(isEntitled)
    }
    
    func testPurchase_ThrowsError_WhenConfigured() async throws {
        // Given
        service.shouldThrowOnPurchase = .productNotFound
        
        // When/Then
        do {
            _ = try await service.purchase(productId: "unknown")
            XCTFail("Should have thrown error")
        } catch let error as StoreServiceError {
            XCTAssertEqual(error, .productNotFound)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Reset
    
    func testReset_ClearsPurchases() async throws {
        // Given
        let productId = "com.kape.vip"
        _ = try await service.purchase(productId: productId)
        var isEntitled = await service.isEntitled(productId: productId)
        XCTAssertTrue(isEntitled)
        
        // When
        service.reset()
        
        // Then
        isEntitled = await service.isEntitled(productId: productId)
        XCTAssertFalse(isEntitled)
        XCTAssertTrue(service.purchasedProductIds.isEmpty)
    }
    
    // MARK: - Transaction Stream
    
    func testTransactionUpdates_EmitsOnPurchase() async throws {
        // Given
        let productId = "com.kape.vip"
        let expectation = XCTestExpectation(description: "Stream emits product ID")
        
        // Create a task to listen to the stream
        let streamTask = Task {
            for await id in service.transactionUpdates {
                if id == productId {
                    expectation.fulfill()
                    return
                }
            }
        }
        
        // Wait briefly for stream listener to be active
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
        // When
        _ = try await service.purchase(productId: productId)
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        streamTask.cancel()
    }
    
    func testPurchase_Concurrent_HandledCorrectly() async throws {
        // Given
        service.simulatedResult = .success
        let productId1 = "com.kape.vip.1"
        let productId2 = "com.kape.vip.2"
        
        // When: Two purchases triggered concurrently
        async let result1 = service.purchase(productId: productId1)
        async let result2 = service.purchase(productId: productId2)
        
        let (r1, r2) = try await (result1, result2)
        
        // Then
        XCTAssertEqual(r1, .success)
        XCTAssertEqual(r2, .success)
        
        let entitled1 = await service.isEntitled(productId: productId1)
        let entitled2 = await service.isEntitled(productId: productId2)
        
        XCTAssertTrue(entitled1)
        XCTAssertTrue(entitled2)
    }
}
