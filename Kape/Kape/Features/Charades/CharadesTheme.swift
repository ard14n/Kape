import SwiftUI

enum CharadesTheme {
    static let background = adaptive(0xFAF7F2, 0x151719)
    static let panel = adaptive(0xFFFFFF, 0x22262A)
    static let ink = adaptive(0x20242A, 0xF5F3EE)
    static let muted = adaptive(0x5C626A, 0xB8BDC4)
    static let accent = adaptive(0xB52739, 0xFF9B91)
    static let onAccent = adaptive(0xFFFFFF, 0x30130F)
    static let soft = adaptive(0xFBE9E6, 0x352322)
    static let line = adaptive(0xE1DDD6, 0x41464D)

    private static func adaptive(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let rgb = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((rgb >> 16) & 255) / 255,
                           green: CGFloat((rgb >> 8) & 255) / 255,
                           blue: CGFloat(rgb & 255) / 255, alpha: 1)
        })
    }
}

struct CharadesButtonStyle: ButtonStyle {
    var prominent = true
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 28)
            .padding(.horizontal, 16).padding(.vertical, 14)
            .foregroundStyle(prominent ? CharadesTheme.onAccent : CharadesTheme.ink)
            .background(prominent ? CharadesTheme.accent : CharadesTheme.panel, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(prominent ? .clear : CharadesTheme.line, lineWidth: 1))
            .opacity(enabled ? (configuration.isPressed ? 0.78 : 1) : 0.45)
    }
}

struct CharadesPage<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) { content }
                .frame(maxWidth: 560, alignment: .leading)
                .padding(.horizontal, 24).padding(.vertical, 24)
                .frame(maxWidth: .infinity)
        }
        .background(CharadesTheme.background)
        .foregroundStyle(CharadesTheme.ink)
    }
}

struct CharadesHeading: View {
    var eyebrow: String
    var title: String
    var detail: String
    var symbol: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let symbol {
                Image(systemName: symbol).font(.system(size: 32, weight: .medium))
                    .foregroundStyle(CharadesTheme.accent)
                    .frame(width: 64, height: 64).background(CharadesTheme.soft, in: RoundedRectangle(cornerRadius: 20))
                    .accessibilityHidden(true)
            }
            Text(eyebrow.uppercased()).font(.system(.caption, design: .rounded, weight: .bold))
                .tracking(1.5).foregroundStyle(CharadesTheme.accent)
            Text(title).font(.system(.largeTitle, design: .rounded, weight: .bold)).fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if !detail.isEmpty {
                Text(detail).font(.body).foregroundStyle(CharadesTheme.muted).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

extension View {
    func charadesPanel() -> some View {
        self.padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(CharadesTheme.panel, in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(CharadesTheme.line, lineWidth: 1))
    }
}
