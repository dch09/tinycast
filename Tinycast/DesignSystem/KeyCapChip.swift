import SwiftUI

/// A single keycap chip: `.outline` for hotkey hints on rows, `.filled` for footer shortcuts.
struct KeyCapChip: View {
    struct Label: View {
        let text: String
        var prefix: String?
        var spacing: CGFloat = Theme.Spacing.xxs

        var body: some View {
            if let prefix {
                HStack(spacing: spacing) {
                    Text(prefix).textScale(.secondary)
                    KeyCapChip.legend(text)
                }
            } else {
                KeyCapChip.legend(text)
            }
        }
    }

    nonisolated static func inlineText(_ caps: [String], separator: String = "") -> Text {
        caps.dropFirst().reduce(legend(caps.first ?? "")) { line, cap in
            Text("\(line)\(separator)\(legend(cap))")
        }
    }

    private nonisolated static func legend(_ text: String) -> Text {
        symbolLegends[text].map { Text(Image(systemName: $0)) } ?? Text(text)
    }

    private nonisolated static let symbolLegends = ["🎤": "mic"]

    enum Style {
        case outline
        case filled
    }

    /// Sanctioned cap sizes, so a bigger or smaller one is a named choice, not a stray frame.
    enum Scale {
        case compact
        case standard
        case hero

        func side(_ metrics: InterfaceMetrics) -> CGFloat {
            switch self {
            case .compact: metrics.size.compactKeyCap
            case .standard: metrics.size.keyCap
            case .hero: metrics.size.heroKeyCap
            }
        }

        @MainActor
        func font(_ metrics: InterfaceMetrics) -> Font {
            switch self {
            case .compact: metrics.typography.compactKeyCap
            case .standard: metrics.typography.keyCap
            case .hero: metrics.typography.heroKeyCap
            }
        }
    }

    let text: String
    var style: Style = .filled
    var scale: Scale = .standard
    var prefix: String?
    @Environment(\.metrics) private var metrics

    /// "↵" falls back to another face that seats high, so nudge it render-only.
    private static let returnGlyphDrop: CGFloat = 1.1

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: metrics.radius.keyCap, style: .continuous)
        Label(text: text, prefix: prefix, spacing: metrics.spacing.xxs)
            .font(scale.font(metrics))
            .foregroundStyle(Theme.Colors.textSecondary)
            .offset(y: text == "↵" ? Self.returnGlyphDrop : 0)
            .padding(.horizontal, metrics.spacing.xs)
            .frame(minWidth: scale.side(metrics), minHeight: scale.side(metrics))
            .background {
                switch style {
                case .filled: shape.fill(Theme.Colors.controlSurface)
                case .outline: shape.strokeBorder(Theme.Colors.border, lineWidth: 1)
                }
            }
    }
}

/// The chord and the trailing label share one slot, so the title does not jump.
struct ResultSlotTrail<Accessory: View>: View {
    @Environment(\.metrics) private var metrics
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(PaletteState.self) private var palette
    let slot: Character?
    var scale: KeyCapChip.Scale = .standard
    @ViewBuilder var accessory: () -> Accessory

    private var shown: Bool { slot != nil && palette.commandHeld }

    var body: some View {
        ZStack(alignment: .trailing) {
            accessory()
                .opacity(shown ? 0 : 1)
                .accessibilityHidden(shown)
            if let slot, shown {
                HStack(spacing: metrics.spacing.xxs) {
                    KeyCapChip(text: "⌘", style: .outline, scale: scale)
                    KeyCapChip(text: String(slot), style: .outline, scale: scale)
                }
                .transition(reveal)
                .accessibilityHidden(true)
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: Theme.Duration.hover), value: shown)
        .allowsHitTesting(false)
    }

    /// A short slide with the fade. Reduce Motion keeps the fade and drops the move.
    private var reveal: AnyTransition {
        guard !reduceMotion else { return .opacity }
        return .opacity.combined(with: .offset(x: metrics.spacing.sm))
    }
}
