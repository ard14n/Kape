import SwiftUI

struct CharadesSettings: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("kape.sound") private var sound = true
    @AppStorage("kape.appearance") private var appearance = "system"
    @State private var help = false
    var body: some View {
        NavigationStack {
            CharadesPage {
                CharadesHeading(eyebrow: "Cilësimet", title: "Sipas dëshirës.", detail: "Rregullojeni për grupin tuaj.")
                VStack(alignment: .leading, spacing: 20) {
                    Toggle("Tingujt e lojës", isOn: $sound).accessibilityIdentifier("SoundToggle")
                    Text("Tingull kur fillon ose mbaron koha. Respekton mënyrën pa zë të telefonit.")
                        .font(.footnote).foregroundStyle(CharadesTheme.muted)
                    Picker("Pamja", selection: $appearance) {
                        Text("Si telefoni").tag("system")
                        Text("E çelët").tag("light")
                        Text("E errët").tag("dark")
                    }.pickerStyle(.menu).accessibilityIdentifier("AppearancePicker")
                }.charadesPanel()
                Button("Si luhet?") { help = true }.buttonStyle(CharadesButtonStyle(prominent: false))
                VStack(alignment: .leading, spacing: 16) {
                    Link(destination: URL(string: "https://onebytemedia.de/kape#ndihme")!) {
                        Label("Ndihmë & kontakt", systemImage: "questionmark.bubble")
                            .frame(minHeight: 44)
                    }.accessibilityIdentifier("SupportLink")
                    Link(destination: URL(string: "https://onebytemedia.de/kape#privatesia")!) {
                        Label("Privatësia", systemImage: "hand.raised")
                            .frame(minHeight: 44)
                    }.accessibilityIdentifier("PrivacyLink")
                }.charadesPanel()
                Text("Kape! · \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")\nFjalët dhe loja ruhen në këtë telefon.")
                    .font(.footnote).foregroundStyle(CharadesTheme.muted)
            }
            .navigationTitle("Cilësimet").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Mbyll") { dismiss() }.accessibilityIdentifier("CloseSettings") } }
            .sheet(isPresented: $help) { CharadesInstructions { help = false } }
        }.tint(CharadesTheme.accent)
    }
}
