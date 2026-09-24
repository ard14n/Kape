import SwiftUI

/// The rule for every turn in a session, independent of how points are counted.
enum CharadesPlayStyle: String, Codable, CaseIterable, Identifiable {
    case freeChoice, pantomime, explaining

    var id: String { rawValue }
    var title: String {
        switch self {
        case .freeChoice: "Zgjedhje e lirë"
        case .pantomime: "Pantomimë"
        case .explaining: "Shpjegim"
        }
    }
    var symbol: String {
        switch self {
        case .freeChoice: "sparkles"
        case .pantomime: "theatermasks"
        case .explaining: "bubble.left.and.bubble.right"
        }
    }
    var summary: String {
        switch self {
        case .freeChoice: "Pantomimë ose shpjegim – ti zgjedh për çdo fjalë."
        case .pantomime: "Paraqite fjalën vetëm me gjeste, pa folë."
        case .explaining: "Përshkruje me fjalë, pa e thanë fjalën apo pjesë të saj."
        }
    }
    var shortSummary: String {
        switch self {
        case .freeChoice: "Gjeste ose shpjegim."
        case .pantomime: "Vetëm me gjeste."
        case .explaining: "Përshkruje me fjalë."
        }
    }
    var rule: String {
        switch self {
        case .freeChoice: "Zgjedh gjeste pa folë ose shpjegim pa e thanë fjalën apo pjesë të saj."
        case .pantomime: "Vetëm me gjeste. Mos fol dhe mos bo tinguj."
        case .explaining: "Shpjegoje pa e thanë fjalën apo pjesë të saj."
        }
    }
    var action: String {
        switch self {
        case .freeChoice: "Ti zgjedh."
        case .pantomime: "Luj me gjeste."
        case .explaining: "Shpjego."
        }
    }
}

struct CharadesStylePicker: View {
    let selected: CharadesPlayStyle
    var choose: (CharadesPlayStyle) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            CharadesPage {
                CharadesHeading(eyebrow: "Mënyra e lojës", title: "Si don me lujt?",
                                detail: "Zgjedhe një rregull për krejt grupin në këtë lojë.")
                ForEach(CharadesPlayStyle.allCases) { style in
                    Button { choose(style) } label: {
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: style.symbol).font(.system(size: 24, weight: .bold))
                                .foregroundStyle(CharadesTheme.accent).neonGlow(CharadesTheme.accent, radius: 4).frame(width: 30)
                            VStack(alignment: .leading, spacing: 8) {
                                Text(style.title).font(.system(.headline, design: .rounded, weight: .heavy))
                                Text(style.summary).font(.subheadline).foregroundStyle(CharadesTheme.muted)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: selected == style ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundStyle(selected == style ? CharadesTheme.accent : CharadesTheme.muted)
                        }.charadesPanel(selected == style ? CharadesTheme.accent : nil)
                    }
                    .buttonStyle(.plain).accessibilityIdentifier("PlayStyle-\(style.rawValue)")
                    .accessibilityLabel("\(style.title). \(style.summary)")
                    .accessibilityAddTraits(selected == style ? .isSelected : [])
                }
            }
            .navigationTitle("Mënyra e lojës").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Mbyll") { dismiss() } } }
        }.tint(CharadesTheme.accent)
    }
}
