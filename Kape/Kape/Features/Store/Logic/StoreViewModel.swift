import Foundation
import Combine

@MainActor
final class StoreViewModel: ObservableObject {
    static let vipProductId = "com.kape.vip" // CR-FIX: specific constants
    
    private let storeService: StoreServiceProtocol
    private var transactionTask: Task<Void, Never>?
    
    @Published private(set) var vipProduct: KapeProduct?
    @Published private(set) var isVIPUnlocked: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isRestoring: Bool = false
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
            vipProduct = products.first { $0.id == Self.vipProductId }
        } catch {
            // CR-FIX: User-facing error handling
            print("Failed to fetch products: \(error)")
            alertMessage = "Failed to load store: \(error.localizedDescription)"
        }
        
        await checkEntitlement()
    }
    
    func checkEntitlement() async {
        isVIPUnlocked = await storeService.isEntitled(productId: Self.vipProductId)
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
    
    // MARK: - Story 4.4: Restore Purchases
    
    func restorePurchases() async {
        isRestoring = true
        defer { isRestoring = false }
        
        do {
            try await storeService.restorePurchases()
            await checkEntitlement()
            alertMessage = "Purchases restored successfully!"
        } catch {
            alertMessage = "Restore failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Transaction Listener
    
    private func startListeningForTransactions() {
        transactionTask?.cancel()
        transactionTask = Task { [weak self] in
            guard let self = self else { return }
            for await productId in self.storeService.transactionUpdates {
                if productId == Self.vipProductId {
                    await self.checkEntitlement()
                }
            }
        }
    }
}

// Add to StoreViewModel.swift (outside class or inside based on Swift style, using outside for cleanliness)
enum PurchaseState: Equatable {
    case idle
    case purchasing
    case succeeded
    case failed(String) // Error message for alert
    case cancelled
}
