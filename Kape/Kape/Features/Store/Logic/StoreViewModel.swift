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
            alertMessage = "Gabim në ngarkim: \(error.localizedDescription)"
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
                alertMessage = "Blerja po pritet."
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
            alertMessage = "Blerja dështoi: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Story 4.4: Restore Purchases
    
    func restorePurchases() async {
        isRestoring = true
        defer { isRestoring = false }
        
        do {
            try await storeService.restorePurchases()
            await checkEntitlement()
            alertMessage = isVIPUnlocked ? "Blerjet u rikthyen!" : "Nuk u gjetën blerje VIP në këtë llogari."
        } catch {
            alertMessage = "Rikthimi dështoi: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Transaction Listener
    
    private func startListeningForTransactions() {
        guard transactionTask == nil else { return }
        // Read synchronously before returning; updates can arrive before this task first runs.
        let updates = storeService.transactionUpdates
        transactionTask = Task { [weak self] in
            for await productId in updates {
                guard !Task.isCancelled else { break }
                if productId == Self.vipProductId {
                    await self?.checkEntitlement()
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
