import Foundation
import StoreKit

actor StoreService: StoreServiceProtocol {
    
    // MARK: - Constants
    
    nonisolated static let vipProductId = "com.kape.vip"
    
    // MARK: - State
    
    private var products: [Product] = []
    
    /// One buffered stream for the lifetime of the service and its single consumer.
    nonisolated let transactionUpdates: AsyncStream<String>
    private let transactionContinuation: AsyncStream<String>.Continuation
    private var transactionListenerTask: Task<Void, Never>?

    init() {
        let channel = AsyncStream<String>.makeStream(bufferingPolicy: .bufferingNewest(16))
        transactionUpdates = channel.stream
        transactionContinuation = channel.continuation
        // Capture only the continuation: the service must not retain itself through this task.
        transactionListenerTask = Task(priority: .background) { [continuation = channel.continuation] in
            for await result in Transaction.updates {
                guard !Task.isCancelled else { break }
                if case .verified(let transaction) = result,
                   transaction.productID == Self.vipProductId {
                    continuation.yield(transaction.productID)
                    await transaction.finish()
                }
            }
        }
    }

    deinit {
        transactionListenerTask?.cancel()
        transactionContinuation.finish()
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
                    transactionContinuation.yield(transaction.productID)
                    
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
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async throws {
        // Force sync with App Store.
        // Entitlements update automatically via Transaction.updates or currentEntitlements
        try await AppStore.sync()
    }
}
