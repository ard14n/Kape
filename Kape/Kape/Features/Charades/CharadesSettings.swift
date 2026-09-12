import SwiftUI

struct CharadesSettings: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("kape.sound") private var sound = true
    @State private var help = false
    var body: some View {
        NavigationStack {
            CharadesPage {
                CharadesHeading(eyebrow: "Cilësimet", title: "Sipas dëshirës.", detail: "Rregulloje për grupin tand.")
                VStack(alignment: .leading, spacing: 20) {
                    Toggle("Tingujt e lojës", isOn: $sound).tint(CharadesTheme.success).accessibilityIdentifier("SoundToggle")
                    Text("Dëgjon tingull kur nis ose mbaron koha. Kur telefoni është pa zë, loja s’bon zhurmë.")
                        .font(.footnote).foregroundStyle(CharadesTheme.muted)
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
