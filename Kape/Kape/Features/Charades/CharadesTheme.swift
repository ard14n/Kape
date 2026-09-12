import SwiftUI
import CoreText

/// Kuq e Flakë: warm black, red party graphics, yellow actions and clear green/red answers.
enum CharadesTheme {
    static let background = hex(0x160B0E)
    static let panel = hex(0x32151D)
    static let ink = hex(0xFFF3DD)
    static let muted = hex(0xDDBBB5)
    static let accent = ink
    static let brand = hex(0xF32640)
    /// Slightly deeper than the decorative red so small cream text stays readable.
    static let hero = hex(0xD41633)
    static let brandShadow = hex(0x7D192A)
    static let action = hex(0xFFD84D)
    static let success = hex(0x79F3A2)
    static let failure = hex(0xFF6B7B)
    static let warning = failure
    static let onAccent = hex(0x201016)
    static let card = hex(0xFFF0D5)
    static let cardMuted = hex(0x6C4140)
    static let soft = action.opacity(0.12)
    static let line = hex(0x553137)

    /// Each colour follows the category's meaning, so the grid reads at a glance.
    static let deckPalette: [String: UInt32] = [
        "pantomime": 0xE4EBAA,
        "mix-shqip": 0xFFD84D,
        "gurbet": 0xFFAC78,
        "muzike": 0xFFC1C5,
        "sport": 0xDCECAF,
        "humor-tv": 0xFFC886,
        "dasma-tradita": 0xF5B4CC,
        "femijeria": 0xFFDBA8,
        "nena-shqiptare": 0xFFA886,
        "historia": 0xEBC59C,
        "politike": 0xF0D9C6,
        "social-media": 0xFFC2A0,
    ]
    static let celebration = [brand, action, success]

    static func deckColor(_ id: String) -> Color { deckPalette[id].map(hex) ?? accent }

    /// Bungee is bundled with its SIL Open Font License; body copy keeps the native Dynamic Type font.
    static func logoFont(size: CGFloat) -> Font {
        _ = logoFontRegistered
        return .custom("Bungee-Regular", size: size, relativeTo: .largeTitle)
    }
    static let logoFontRegistered: Bool = {
        guard let url = Bundle.main.url(forResource: "Bungee-Regular", withExtension: "ttf") else { return false }
        return CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }()

    static func hex(_ rgb: UInt32) -> Color {
        Color(red: Double((rgb >> 16) & 255) / 255, green: Double((rgb >> 8) & 255) / 255, blue: Double(rgb & 255) / 255)
    }
}

struct CharadesButtonStyle: ButtonStyle {
    var prominent = true
    /// No frame at all: used where a second framed button would fight the first one for attention.
    var bare = false
    var color: Color? = nil
    var font: Font? = nil
    var fillsHeight = false
    /// Outcome answers keep green/red neon outlines; primary navigation has a solid yellow face.
    var outlined = false
    @Environment(\.isEnabled) private var enabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        let tint = color ?? (prominent ? CharadesTheme.action : CharadesTheme.accent)
        let filled = prominent && !bare && !outlined
        return configuration.label
            .font(font ?? .system(prominent ? .title3 : .headline, design: .rounded, weight: .heavy))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 28, maxHeight: fillsHeight ? .infinity : nil)
            .padding(.horizontal, 16).padding(.vertical, prominent ? 15 : 12)
            .contentShape(RoundedRectangle(cornerRadius: 18))
            .foregroundStyle(filled ? CharadesTheme.onAccent : tint)
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(bare ? Color.clear : filled ? tint : tint.opacity(configuration.isPressed ? 0.18 : 0.07))
                    .shadow(color: filled ? tint.opacity(0.45) : .clear, radius: 0, y: configuration.isPressed ? 1 : 4)
            }
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(bare ? Color.clear : tint, lineWidth: 2)
                .neonGlow(bare ? Color.clear : tint, radius: enabled ? (filled ? 6 : prominent ? 10 : 4) : 0))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.22, dampingFraction: 0.6), value: configuration.isPressed)
            .opacity(enabled ? (bare && configuration.isPressed ? 0.6 : 1) : 0.4)
    }
}

/// Matching side columns center both titles on the button while keeping the symbols aligned.
struct CharadesResponseLabel: View {
    var guessed: Bool
    private var title: String { guessed ? "U gjet" : "Nuk u gjet" }
    private var color: Color { guessed ? CharadesTheme.success : CharadesTheme.failure }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: guessed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 28, weight: .semibold))
                .symbolRenderingMode(.palette)
                .foregroundStyle(CharadesTheme.onAccent, color)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
            Text(title)
                .frame(maxWidth: .infinity)
                .fixedSize(horizontal: false, vertical: true)
            Color.clear
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
    }
}

/// The two fast answers always receive the larger of their measured heights.
struct CharadesAnswerStack: Layout {
    var spacing: CGFloat = 16
    private func height(width: CGFloat?, subviews: Subviews) -> CGFloat {
        subviews.map { $0.sizeThatFits(ProposedViewSize(width: width, height: nil)).height }.max() ?? 0
    }
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        return CGSize(width: width, height: height(width: width, subviews: subviews) * CGFloat(subviews.count)
                      + spacing * CGFloat(max(0, subviews.count - 1)))
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rowHeight = height(width: bounds.width, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX, y: bounds.minY + CGFloat(index) * (rowHeight + spacing)),
                          proposal: ProposedViewSize(width: bounds.width, height: rowHeight))
        }
    }
}

struct CharadesPage<Content: View>: View {
    /// Game screens centre their content on the stage instead of leaving the lower half empty.
    var centered = false
    /// The home screen spreads its content over the whole height so no hole opens above the actions.
    var stretched = false
    var party = false
    @ViewBuilder var content: Content
    var body: some View {
        GeometryReader { geometry in
            let visibleHeight = max(0, geometry.size.height - geometry.safeAreaInsets.top - geometry.safeAreaInsets.bottom)
            ScrollView {
                VStack(alignment: centered ? .center : .leading, spacing: 24) { content }
                    .multilineTextAlignment(centered ? .center : .leading)
                    .frame(maxWidth: 560, minHeight: stretched ? max(0, visibleHeight - 48) : nil,
                           alignment: centered ? .center : .leading)
                    .padding(.horizontal, 24).padding(.vertical, 24)
                    .frame(maxWidth: .infinity, minHeight: centered ? visibleHeight : nil)
            }
        }
        .background {
            ZStack {
                CharadesTheme.background
                if party {
                    RadialGradient(colors: [CharadesTheme.brandShadow.opacity(0.6), .clear],
                                   center: .topTrailing, startRadius: 0, endRadius: 520)
                }
            }
            .ignoresSafeArea(.container, edges: .top)
        }
        .charadesNavigationBar()
        .foregroundStyle(CharadesTheme.ink)
    }
}

struct CharadesHeading: View {
    var eyebrow: String
    var title: String
    var detail: String
    var symbol: String? = nil
    var celebrate = false
    var color: Color = CharadesTheme.accent
    /// A coloured title glows like a neon sign; nil keeps the plain white title.
    var titleColor: Color? = nil
    @State private var bounce = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// On a centred game stage (see CharadesPage) the heading grows so it reads from across the table.
    @Environment(\.multilineTextAlignment) private var textAlignment
    @ScaledMetric(relativeTo: .largeTitle) private var stageTitleSize: CGFloat = 42
    var body: some View {
        let stage = textAlignment == .center
        VStack(alignment: stage ? .center : .leading, spacing: 12) {
            if let symbol {
                Image(systemName: symbol).font(.system(size: stage ? 38 : 28, weight: .bold))
                    .foregroundStyle(color)
                    .symbolEffect(.bounce, options: .nonRepeating, value: bounce)
                    .frame(width: stage ? 84 : 62, height: stage ? 84 : 62)
                    .background(color.opacity(0.07), in: Circle())
                    .overlay(Circle().stroke(color.opacity(0.3), lineWidth: 1))
                    .accessibilityHidden(true)
                    .onAppear { if celebrate && !reduceMotion { bounce.toggle() } }
            }
            Text(eyebrow.uppercased()).font(.system(stage ? .headline : .caption, design: .rounded, weight: .heavy))
                .tracking(1.5).foregroundStyle(color)
            Text(title).font(stage ? .system(size: stageTitleSize, weight: .heavy, design: .rounded) : .system(.largeTitle, design: .rounded, weight: .heavy))
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(titleColor ?? CharadesTheme.ink)
                .accessibilityAddTraits(.isHeader)
            if !detail.isEmpty {
                Text(detail).font(.body).foregroundStyle(CharadesTheme.muted).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

extension View {
    /// Each presented navigation stack keeps the same background and readable system controls.
    func charadesNavigationBar() -> some View {
        toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }

    /// Two soft shadows in the same colour read as a glowing neon tube.
    func neonGlow(_ color: Color, radius: CGFloat = 8) -> some View {
        shadow(color: color.opacity(0.8), radius: radius * 0.5)
            .shadow(color: color.opacity(0.5), radius: radius * 1.5)
    }

    /// Information and selections stay quieter than the glowing action outlines.
    func charadesPanel(_ color: Color? = nil) -> some View {
        padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(CharadesTheme.panel, in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(color?.opacity(0.35) ?? CharadesTheme.line, lineWidth: 1))
    }
}

/// A short burst of neon sparks after a guessed word; skipped when Reduce Motion is on.
struct CharadesCelebration: View {
    private struct Piece {
        let fromLeft = Bool.random()
        let angle = Double.random(in: (-Double.pi * 0.9)...(-Double.pi * 0.1))
        let speed = Double.random(in: 280...560)
        let spin = Double.random(in: -8...8)
        let size = Double.random(in: 5...10)
        let color = CharadesTheme.celebration.randomElement() ?? CharadesTheme.accent
    }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pieces = (0..<42).map { _ in Piece() }
    @State private var start = Date.now
    @State private var done = false
    private let duration = 1.6

    var body: some View {
        Group {
            if !reduceMotion && !done {
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSince(start)
                    Canvas { context, size in
                        for piece in pieces {
                            let origin = CGPoint(x: size.width * (piece.fromLeft ? 0.08 : 0.92), y: size.height * 0.15)
                            var layer = context
                            layer.opacity = max(0, 1 - t / duration)
                            layer.addFilter(.shadow(color: piece.color, radius: 4))
                            layer.translateBy(x: origin.x + cos(piece.angle) * piece.speed * t,
                                              y: origin.y + sin(piece.angle) * piece.speed * t + 600 * t * t)
                            layer.rotate(by: .radians(piece.spin * t))
                            let s = piece.size
                            layer.fill(Self.spark(in: CGRect(x: -s * 0.6, y: -s, width: s * 1.2, height: s * 2)), with: .color(piece.color))
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task {
            try? await Task.sleep(for: .seconds(duration))
            done = true
        }
    }

    private static func spark(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.closeSubpath()
        }
    }
}
