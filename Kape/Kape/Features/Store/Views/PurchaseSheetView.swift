import SwiftUI

struct PurchaseSheetView: View {
    let product: KapeProduct
    let onPurchase: () async -> Void
    let onDismiss: () -> Void
    
    @State private var isPurchasing = false
    
    var body: some View {
        ZStack {
            Color.trueBlack.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                Image(systemName: "crown.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.neonRed)
                    .neonGlow(color: .neonRed)
                
                Text("Unlock VIP Content")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(product.displayName)
                    .font(.headline)
                    .foregroundStyle(.gray)
                
                Text(product.displayPrice)
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundStyle(Color.neonGreen)
                    .neonGlow(color: .neonGreen)
                
                // Purchase Button
                Button {
                    Task {
                        isPurchasing = true
                        await onPurchase()
                        isPurchasing = false
                    }
                } label: {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    } else {
                        Text("PURCHASE")
                            .font(.headline)
                            .fontWeight(.heavy)
                    }
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.neonGreen)
                .clipShape(Capsule())
                .neonGlow(color: .neonGreen)
                .disabled(isPurchasing)
                .accessibilityIdentifier("PurchaseButton")
                
                // Dismiss Button
                Button("Maybe Later") {
                    onDismiss()
                }
                .foregroundStyle(.gray)
                .accessibilityIdentifier("DismissButton")
            }
            .padding(32)
        }
    }
}

#Preview {
    PurchaseSheetView(
        product: KapeProduct(
            id: "com.kape.vip",
            displayName: "VIP Deck",
            displayPrice: "$2.99",
            productType: .nonConsumable
        ),
        onPurchase: {
            try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
        },
        onDismiss: {}
    )
}
