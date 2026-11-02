import Foundation

/// One hold at a time. Closing the palette does not release it; quitting the app does.
@MainActor
@Observable
final class CaffeineCoordinator {
    enum Screen: Equatable, Sendable {
        case duration
        case until
        case process
    }

    private(set) var screen: Screen = .duration
    private(set) var hold: CaffeineHold?
    private(set) var apps: [CaffeineProcess] = []
    private(set) var processMatches: [CaffeineProcess] = []

    @ObservationIgnored private unowned let core: AppCore
    @ObservationIgnored private let assertion = CaffeineAssertion()
    @ObservationIgnored private let menuBar = CaffeineMenuBar()
    @ObservationIgnored private var clock: Task<Void, Never>?
    @ObservationIgnored private var processSource: (any DispatchSourceProcess)?

    init(core: AppCore) {
        self.core = core
        menuBar.onDecaffeinate = { [weak self] in
            self?.stop(announcing: true, dismiss: false)
        }
    }

    var searchPrompt: String {
        switch screen {
        case .duration: String(localized: "5 minutes, 90m, 1h 30m…")
        case .until: String(localized: "5pm, 17:30, tomorrow 9am…")
        case .process: String(localized: "Search running apps and processes…")
        }
    }

    /// One mode covers three screens, so opening a different one must not close the palette.
    func show(_ screen: Screen) {
        let showing = core.paletteCoordinator.isShowing(.caffeinate)
        if showing, self.screen == screen {
            hidePalette()
            return
        }
        self.screen = screen
        if screen == .process { refreshProcesses(matching: "") }
        guard !showing else {
            core.palette.query = ""
            core.palette.selection = 0
            return
        }
        core.paletteCoordinator.showPalette(mode: .caffeinate, seeding: "")
    }

    func refreshProcesses(matching query: String) {
        apps = CaffeineProcessList.runningApps()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        processMatches = trimmed.isEmpty
            ? [] : CaffeineProcessList.matching(trimmed, excluding: Set(apps.map(\.pid)))
    }

    func start(_ limit: CaffeineLimit) {
        let targets = currentTargets()
        guard !targets.isEmpty else {
            core.showMessage(
                String(localized: "Choose what to keep awake in Settings."), tone: .danger)
            hidePalette()
            return
        }
        if case .whileRunning(let pid, _) = limit, !CaffeineProcessList.isAlive(pid) {
            core.showMessage(String(localized: "That process isn't running."), tone: .danger)
            hidePalette()
            return
        }
        let now = Date()
        let reason = CaffeineStatus.summary(limit, now: now, calendar: .current)
        guard assertion.swap(targets: targets, reason: reason, timeout: timeout(for: limit, now: now))
        else {
            core.showMessage(String(localized: "Couldn't keep the Mac awake."), tone: .danger)
            hidePalette()
            return
        }
        cancelWatchers()
        hold = CaffeineHold(targets: targets, limit: limit)
        arm(limit)
        updateMenuBar()
        core.showMessage(reason)
        hidePalette()
    }

    func stop(announcing: Bool, dismiss: Bool) {
        let wasOn = hold != nil
        clear()
        if announcing {
            core.showMessage(String(localized: "The Mac can sleep."), tone: .neutral)
        }
        if dismiss, wasOn || announcing { hidePalette() }
    }

    func toggle() {
        if hold == nil {
            start(.indefinite)
        } else {
            stop(announcing: true, dismiss: true)
        }
    }

    func showStatus() {
        let message: String
        if let hold {
            message = CaffeineStatus.summary(hold.limit, now: Date(), calendar: .current)
        } else {
            message = String(localized: "The Mac can sleep.")
        }
        core.showMessage(message, tone: hold == nil ? .neutral : .success)
        hidePalette()
    }

    /// Settings can change under a live hold, including from settings.json with no pane open.
    func applySettings() {
        let targets = currentTargets()
        guard var current = hold else {
            menuBar.hide()
            return
        }
        guard current.targets != targets else {
            updateMenuBar()
            return
        }
        guard !targets.isEmpty else {
            clear()
            core.showMessage(
                String(localized: "Choose what to keep awake in Settings."), tone: .danger)
            return
        }
        let now = Date()
        let reason = CaffeineStatus.summary(current.limit, now: now, calendar: .current)
        guard assertion.swap(
            targets: targets, reason: reason, timeout: timeout(for: current.limit, now: now))
        else {
            clear()
            core.showMessage(String(localized: "Couldn't keep the Mac awake."), tone: .danger)
            return
        }
        current.targets = targets
        hold = current
        updateMenuBar()
    }

    private func arm(_ limit: CaffeineLimit) {
        switch limit {
        case .indefinite:
            break
        case .until(let date):
            clock = Task { [weak self] in
                while !Task.isCancelled {
                    let remaining = date.timeIntervalSinceNow
                    guard let self, case .until(let current) = self.hold?.limit, current == date
                    else { return }
                    if remaining <= 0 {
                        self.stop(announcing: true, dismiss: false)
                        return
                    }
                    self.updateMenuBar()
                    let slice = remaining > 60 ? min(remaining, 30) : min(remaining, 1)
                    try? await Task.sleep(for: .seconds(slice))
                }
            }
        case .whileRunning(let pid, _):
            let source = DispatchSource.makeProcessSource(
                identifier: pid, eventMask: .exit, queue: .main)
            source.setEventHandler { [weak self] in
                Task { @MainActor in
                    guard let self, case .whileRunning(let current, _) = self.hold?.limit,
                        current == pid
                    else { return }
                    self.stop(announcing: true, dismiss: false)
                }
            }
            processSource = source
            source.resume()
        }
    }

    private func currentTargets() -> CaffeineTargets {
        var targets: CaffeineTargets = []
        if core.settings.caffeinatePreventDisplaySleep { targets.insert(.display) }
        if core.settings.caffeinatePreventSystemSleep { targets.insert(.system) }
        if core.settings.caffeinatePreventDiskSleep { targets.insert(.disk) }
        return targets
    }

    private func timeout(for limit: CaffeineLimit, now: Date) -> TimeInterval? {
        guard case .until(let date) = limit else { return nil }
        let seconds = date.timeIntervalSince(now)
        return seconds > 0 ? seconds : nil
    }

    private func updateMenuBar() {
        guard core.settings.caffeinateShowsMenuBar, let hold else {
            menuBar.hide()
            return
        }
        let now = Date()
        menuBar.update(
            title: CaffeineStatus.menuTitle(hold.limit, now: now),
            summary: CaffeineStatus.summary(hold.limit, now: now, calendar: .current))
    }

    private func clear() {
        hold = nil
        cancelWatchers()
        assertion.release()
        menuBar.hide()
    }

    private func cancelWatchers() {
        clock?.cancel()
        clock = nil
        processSource?.cancel()
        processSource = nil
    }

    private func hidePalette() {
        guard core.paletteCoordinator.isVisible else { return }
        core.paletteCoordinator.hidePalette(restoreFocus: false)
    }

    isolated deinit {
        clock?.cancel()
        processSource?.cancel()
        assertion.release()
        menuBar.hide()
    }
}
