import SwiftUI

private struct ResultSlotCharacterKey: EnvironmentKey {
    static let defaultValue: Character? = nil
}

extension EnvironmentValues {
    /// The chord for this row, set by `resultSlot`. Nil when the row is past the run.
    var resultSlotCharacter: Character? {
        get { self[ResultSlotCharacterKey.self] }
        set { self[ResultSlotCharacterKey.self] = newValue }
    }
}

extension View {
    /// A corner draws this chord. A list row opts out and reads `resultSlotCharacter`.
    func resultSlot(
        _ slot: Character?, alignment: Alignment = .trailing, scale: KeyCapChip.Scale = .standard,
        overlay: Bool = true
    ) -> some View {
        modifier(ResultSlotMark(slot: slot, alignment: alignment, scale: scale, drawsOverlay: overlay))
    }

    func resultSlotOrdinal(
        _ ordinal: Int, alignment: Alignment = .trailing, scale: KeyCapChip.Scale = .standard,
        overlay: Bool = true
    ) -> some View {
        modifier(ResultSlotOrdinal(ordinal: ordinal, alignment: alignment, scale: scale, overlay: overlay))
    }
}

private struct ResultSlotMark: ViewModifier {
    let slot: Character?
    var alignment: Alignment = .trailing
    var scale: KeyCapChip.Scale = .standard
    var drawsOverlay = true

    func body(content: Content) -> some View {
        content
            .environment(\.resultSlotCharacter, slot)
            .overlay(alignment: alignment) {
                if drawsOverlay {
                    ResultSlotOverlay(slot: slot, alignment: alignment, scale: scale)
                }
            }
    }
}

private struct ResultSlotOverlay: View {
    @Environment(\.metrics) private var metrics
    let slot: Character?
    let alignment: Alignment
    var scale: KeyCapChip.Scale = .standard

    var body: some View {
        ResultSlotTrail(slot: slot, scale: scale) { EmptyView() }
            .padding(.trailing, metrics.spacing.md)
            .padding(.top, alignment == .topTrailing ? metrics.spacing.sm : 0)
    }
}

private struct ResultSlotOrdinal: ViewModifier {
    @Environment(PaletteState.self) private var palette
    let ordinal: Int
    var alignment: Alignment = .trailing
    var scale: KeyCapChip.Scale = .standard
    var overlay = true

    func body(content: Content) -> some View {
        content.resultSlot(
            palette.resultListDigit(at: ordinal), alignment: alignment, scale: scale, overlay: overlay)
    }
}
