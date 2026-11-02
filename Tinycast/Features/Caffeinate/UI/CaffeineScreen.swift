import SwiftUI

struct CaffeineScreen: PaletteScreen {
    let coordinator: CaffeineCoordinator
    let vm: PaletteState

    var rows: [CaffeineChoice] {
        switch coordinator.screen {
        case .duration:
            CaffeineChoice.durations(matching: vm.query)
        case .until:
            CaffeineChoice.deadlines(matching: vm.query, now: Date(), calendar: .current)
        case .process:
            CaffeineChoice.processes(
                matching: vm.query, apps: coordinator.apps, others: coordinator.processMatches)
        }
    }

    var primaryActionTitle: String { String(localized: "Caffeinate") }

    func hasPrimaryAction(at selection: Int) -> Bool { rows.indices.contains(selection) }

    func hasActions(at selection: Int) -> Bool { false }

    func activate(at selection: Int) {
        guard rows.indices.contains(selection) else { return }
        switch rows[selection].action {
        case .duration(let interval):
            coordinator.start(.until(Date().addingTimeInterval(interval)))
        case .until(let date):
            coordinator.start(.until(date))
        case .process(let process):
            coordinator.start(.whileRunning(pid: process.pid, name: process.name))
        }
    }

    func secondary(at selection: Int) -> Bool { false }

    func body(selection: Int, scroll: ScrollIntent) -> AnyView {
        AnyView(content(selection: selection, scroll: scroll))
    }

    @ViewBuilder
    private func content(selection: Int, scroll: ScrollIntent) -> some View {
        let rows = rows
        Group {
            if rows.isEmpty {
                EmptyResults(text: emptyText)
            } else {
                CaffeineList(rows: rows, selectedID: rows.indices.contains(selection) ? rows[selection].id : nil,
                    scroll: scroll) { row in
                    guard let index = rows.firstIndex(of: row) else { return }
                    activate(at: index)
                }
            }
        }
        .onChange(of: vm.query) {
            guard coordinator.screen == .process else { return }
            coordinator.refreshProcesses(matching: vm.query)
        }
    }

    private var emptyText: String {
        let query = vm.query.trimmingCharacters(in: .whitespacesAndNewlines)
        switch coordinator.screen {
        case .duration: return String(localized: "Type a duration, like 30m or 1h")
        case .until: return String(localized: "Type a time, like 5pm or 17:30")
        case .process:
            return query.isEmpty
                ? String(localized: "No running applications")
                : String(localized: "No matching apps or processes")
        }
    }
}

private struct CaffeineList: View {
    @Environment(\.metrics) private var metrics
    let rows: [CaffeineChoice]
    let selectedID: CaffeineChoice.ID?
    let scroll: ScrollIntent
    let onActivate: (CaffeineChoice) -> Void

    private var firstRowSelected: Bool { selectedID != nil && selectedID == rows.first?.id }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { ordinal, row in
                        CaffeineRow(row: row, selected: row.id == selectedID)
                            .resultSlotOrdinal(ordinal, overlay: false)
                            .selectionFrame(row.id == selectedID)
                            .contentShape(Rectangle())
                            .onTapGesture { onActivate(row) }
                    }
                }
                .padding(.horizontal, metrics.spacing.md)
                .padding(.vertical, metrics.spacing.md)
                .hideNativeScrollers()
                .scrollOriginAnchor()
            }
            .edgeDissolve()
            .thinScrollbar()
            .scrollFollowsSelection(scroll, row: selectedID, atOrigin: firstRowSelected, proxy: proxy)
        }
    }
}

private struct CaffeineRow: View {
    @Environment(\.metrics) private var metrics
    let row: CaffeineChoice
    let selected: Bool
    @Environment(\.resultSlotCharacter) private var slot
    @State private var hovered = false

    private var fill: Color {
        if selected { return Theme.Colors.selection }
        if hovered { return Theme.Colors.rowHover }
        return .clear
    }

    var body: some View {
        HStack(spacing: metrics.spacing.lg) {
            icon
                .frame(width: metrics.size.resultRowIcon, height: metrics.size.resultRowIcon)
            VStack(alignment: .leading, spacing: 0) {
                Text(row.title)
                    .font(metrics.typography.rowTitle)
                    .lineLimit(1)
                Text(row.subtitle)
                    .font(metrics.typography.rowTrailing)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: metrics.spacing.md)
            ResultSlotTrail(slot: slot) { EmptyView() }
        }
        .padding(.horizontal, metrics.spacing.md)
        .padding(.vertical, metrics.spacing.sm)
        .background(RoundedRectangle(cornerRadius: metrics.radius.row, style: .continuous).fill(fill))
        .armedHover($hovered)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(row.title)
        .accessibilityValue(row.subtitle)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    @ViewBuilder private var icon: some View {
        if let path = row.iconPath {
            EntryIconView(source: .file(stamp: 0), fileURL: URL(fileURLWithPath: path))
        } else {
            EntryIconView(source: .symbol(row.symbol))
        }
    }
}
