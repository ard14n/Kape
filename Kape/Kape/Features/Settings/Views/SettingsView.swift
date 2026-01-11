import SwiftUI

/// Settings screen with Restore Purchases functionality
/// Story 4.4: Restore Purchases
struct SettingsView: View {
    @ObservedObject var storeViewModel: StoreViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Purchases") {
                    Button {
                        Task {
                            await storeViewModel.restorePurchases()
                        }
                    } label: {
                        HStack {
                            Text("Restore Purchases")
                            Spacer()
                            if storeViewModel.isRestoring {
                                ProgressView()
                            }
                        }
                    }
                    .accessibilityIdentifier("restorePurchasesButton")
                    .disabled(storeViewModel.isRestoring)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
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
