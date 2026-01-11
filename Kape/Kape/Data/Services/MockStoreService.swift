import Foundation

final class MockStoreService: StoreServiceProtocol, @unchecked Sendable {
    // MARK: - State
    
    /// The set of product IDs currently considered "purchased" by the mock.
    var purchasedProductIds: Set<String> = []
    
    /// The result to return from the next `purchase()` call.
    var simulatedResult: PurchaseResult = .success
    
    /// If set, the next `purchase()` call will throw this error instead of returning a result.
    var shouldThrowOnPurchase: StoreServiceError?
    
    /// CR4.2-03 FIX: Custom products to return from fetchProducts()
    var mockProducts: [KapeProduct]?
    
    /// CR4.2-03 FIX: Error to throw from fetchProducts()
    var simulatedError: StoreServiceError?
    
    /// If set, the next `restorePurchases()` call will throw this error.
    var shouldThrowOnRestore: StoreServiceError?
    
    /// Continuation for the transaction stream
    private var transactionContinuation: AsyncStream<String>.Continuation?
    
    // MARK: - Protocol Implementation
    
    func fetchProducts() async throws -> [KapeProduct] {
        // CR4.2-03 FIX: Check for simulated error first
        if let error = simulatedError {
            throw error
        }
        
        // Return custom mock products if set, otherwise default
        if let products = mockProducts {
            return products
        }
        
        // Return a standard mock product for consistency
        return [
            KapeProduct(
                id: "com.kape.vip",
                displayName: "VIP Deck",
                displayPrice: "$2.99",
                productType: .nonConsumable
            )
        ]
    }
    
    func purchase(productId: String) async throws -> PurchaseResult {
        if let error = shouldThrowOnPurchase {
            throw error
        }
        
        switch simulatedResult {
        case .success:
            purchasedProductIds.insert(productId)
            // Emit update to stream
            transactionContinuation?.yield(productId)
            return .success
        case .cancelled, .pending:
            return simulatedResult
        }
    }
    
    func isEntitled(productId: String) async -> Bool {
        return purchasedProductIds.contains(productId)
    }
    
    var transactionUpdates: AsyncStream<String> {
        AsyncStream { continuation in
            self.transactionContinuation = continuation
        }
    }
    
    func restorePurchases() async throws {
        if let error = shouldThrowOnRestore {
            throw error
        }
        // CR4.4-M1 FIX: Use constant instead of hardcoded string
        purchasedProductIds.insert(StoreViewModel.vipProductId)
    }
    
    // MARK: - Test Helpers
    
    /// Resets the mock to its initial state.
    func reset() {
        purchasedProductIds.removeAll()
        simulatedResult = .success
        shouldThrowOnPurchase = nil
        shouldThrowOnRestore = nil
        // Note: Stream continuation remains valid
    }
    /// Helper to manually emit a transaction update
    func emitTransaction(_ productId: String) {
        transactionContinuation?.yield(productId)
    }
}
