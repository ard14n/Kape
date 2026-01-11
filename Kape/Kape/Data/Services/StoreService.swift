import Foundation
import StoreKit

actor StoreService: StoreServiceProtocol {
    
    // MARK: - Constants
    
    nonisolated static let vipProductId = "com.kape.vip"
    
    // MARK: - State
    
    private var products: [Product] = []
    
    /// Stream continuation for transaction updates
    private var transactionContinuation: AsyncStream<String>.Continuation?
    
    /// Task to keep the transaction listener alive
    private var transactionListenerTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init() {
        // Start transaction listener immediately upon initialization
        startTransactionListener()
    }
    
    deinit {
        transactionListenerTask?.cancel()
    }
    
    // MARK: - Fetch Products
    
    func fetchProducts() async throws -> [KapeProduct] {
        do {
            // Fetch products from App Store (or local config in dev)
            let storeProducts = try await Product.products(for: [Self.vipProductId])
            self.products = storeProducts
            
            // Map to internal KapeProduct model
            return storeProducts.map { product in
                KapeProduct(
                    id: product.id,
                    displayName: product.displayName,
                    displayPrice: product.displayPrice, // Localized price string
                    productType: .nonConsumable
                )
            }
        } catch {
            print("StoreService: Failed to fetch products: \(error)")
            throw StoreServiceError.productNotFound
        }
    }
    
    // MARK: - Purchase
    
    func purchase(productId: String) async throws -> PurchaseResult {
        // Ensure we have the product object (fetched previously)
        guard let product = products.first(where: { $0.id == productId }) else {
            throw StoreServiceError.productNotFound
        }
        
        do {
            // Initiate purchase flow
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Verify the transaction
                switch verification {
                case .verified(let transaction):
                    // ⚠️ CRITICAL: Finish ONLY after delivering content (or confirming entitlement)
                    await transaction.finish()
                    
                    // Notify listeners (UI) that a transaction occurred
                    transactionContinuation?.yield(transaction.productID)
                    
                    return .success
                    
                case .unverified(_, let error):
                    // Transaction failed verification (JWS signature invalid, etc.)
                   print("StoreService: Transaction unverified: \(error)")
                    throw StoreServiceError.purchaseFailed(
                        NSError(domain: "StoreKit", code: -1, 
                               userInfo: [NSLocalizedDescriptionKey: "Transaction verification failed"])
                    )
                }
                
            case .pending:
                // Ask to Buy or other pending state
                return .pending
                
            case .userCancelled:
                return .cancelled
                
            @unknown default:
                return .cancelled
            }
        } catch {
            throw StoreServiceError.purchaseFailed(error)
        }
    }
    
    // MARK: - Entitlement Check
    
    func isEntitled(productId: String) async -> Bool {
        // Check current entitlements for non-consumables
        // StoreKit 2 maintains this cache automatically
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                // Check if this is the product we're looking for
                if transaction.productID == productId {
                    // Check revocation status (though currentEntitlements usually filters revoked info)
                    if transaction.revocationDate == nil {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    // MARK: - Transaction Updates Stream
    
    nonisolated var transactionUpdates: AsyncStream<String> {
        AsyncStream { continuation in
            // Capture the continuation. 
            // Note: Since 'transactionContinuation' is actor-isolated, we need a way to set it.
            // The simplified pattern in Dev Notes had a slight race/isolation issue.
            // Proper way: Store it in the actor via a method or property.
            // However, AsyncStream builder is synchronous.
            // We'll use a property that we update. But since this prop is nonisolated computed...
            // Fix: We need to set the actor's continuation.
            
            // Actually, best pattern: The actor *has* the stream.
            // But strict Swift 6 actor isolation makes sharing the continuation hard.
            // Let's use the Dev Notes pattern but fix isolation if needed.
            // We'll call an async method to register the continuation? No, AsyncStream is pull or push.
            
            // Alternative: Return a new stream and merge?
            // Simplest functional approach for Kape MVP:
            // Just use a static/global broadcast or let the actor manage its own internal stream 
            // and expose it.
            
            // To match the Protocol 'var transactionUpdates: AsyncStream<String>'
            // We can't strictly share one stream for multiple listeners unless we use multicast.
            // But StoreViewModel is the main listener.
            
            // Implementation:
            Task {
                await self.setContinuation(continuation)
            }
        }
    }
    
    // Helper to escape isolation for setting continuation
    private func setContinuation(_ continuation: AsyncStream<String>.Continuation) {
        self.transactionContinuation = continuation
    }
    
    private func startTransactionListener() {
        transactionListenerTask = Task(priority: .background) {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    // Transaction updated (background, asking buy approved, etc.)
                    await transaction.finish()
                    transactionContinuation?.yield(transaction.productID)
                }
            }
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async throws {
        // Force sync with App Store.
        // Entitlements update automatically via Transaction.updates or currentEntitlements
        try await AppStore.sync()
    }
}
