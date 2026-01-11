import Foundation

/// Represents a product available for purchase in Kape.
struct KapeProduct: Identifiable, Sendable {
    let id: String
    let displayName: String
    let displayPrice: String
    let productType: ProductType
    
    enum ProductType: Sendable {
        case nonConsumable
    }
}

/// The result of a purchase attempt.
enum PurchaseResult: Sendable {
    case success
    case cancelled
    case pending
}

/// Errors that can occur within the StoreService.
enum StoreServiceError: Error, Sendable, Equatable {
    case productNotFound
    case purchaseFailed(Error)
    case notEntitled
    
    static func == (lhs: StoreServiceError, rhs: StoreServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.productNotFound, .productNotFound): return true
        case (.notEntitled, .notEntitled): return true
        case (.purchaseFailed, .purchaseFailed): return true
        default: return false
        }
    }
}

/// Defines the contract for StoreKit interactions.
/// Abstracts the underlying StoreKit 2 implementation for testability and decoupling.
protocol StoreServiceProtocol: Sendable {
    /// Fetches available products from the store.
    func fetchProducts() async throws -> [KapeProduct]
    
    /// Attempts to purchase a product.
    func purchase(productId: String) async throws -> PurchaseResult
    
    /// Checks if a product is currently entitled.
    func isEntitled(productId: String) async -> Bool
    
    /// Async stream for real-time transaction updates.
    /// Emits the distinct Product ID of the transaction.
    var transactionUpdates: AsyncStream<String> { get }
    
    /// Forces a sync with App Store to restore purchases.
    /// Use when user explicitly requests to restore their purchases after reinstalling.
    func restorePurchases() async throws
}
