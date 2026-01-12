import SwiftUI

/// Settings screen with Restore Purchases functionality
/// Story 4.4: Restore Purchases
struct SettingsView: View {
    @ObservedObject var storeViewModel: StoreViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Blerjet") {
                    Button {
                        Task {
                            await storeViewModel.restorePurchases()
                        }
                    } label: {
                        HStack {
                            Text("Rikthe Blerjet")
                            Spacer()
                            if storeViewModel.isRestoring {
                                ProgressView()
                            }
                        }
                    }
                    .accessibilityIdentifier("restorePurchasesButton")
                    .disabled(storeViewModel.isRestoring)
                }
                
                Section("Rreth") {
                    HStack {
                        Text("Versioni")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Cilësimet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Mbyll") {
                        dismiss()
                    }
                    .accessibilityIdentifier("settingsDoneButton")
                }
            }
        }
    }
}

#Preview {
    SettingsView(storeViewModel: StoreViewModel())
}
