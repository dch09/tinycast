import Foundation

/// One row on a caffeinate screen. The action is what Return starts.
struct CaffeineChoice: Identifiable, Equatable, Sendable {
    enum Action: Equatable, Sendable {
        case duration(TimeInterval)
        case until(Date)
        case process(CaffeineProcess)
    }

    var id: String
    var title: String
    var subtitle: String
    var symbol: String
    var action: Action

    var iconPath: String? {
        guard case .process(let process) = action else { return nil }
        return process.iconPath
    }

    static func durations(matching raw: String) -> [CaffeineChoice] {
        let query = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let intervals = query.isEmpty ? CaffeineDuration.presets : [CaffeineDuration.parse(query)].compactMap { $0 }
        return intervals.map { interval in
            CaffeineChoice(
                id: "duration-\(Int(interval))", title: CaffeineDuration.phrase(interval),
                subtitle: String(localized: "Keep the Mac awake"), symbol: "timer",
                action: .duration(interval))
        }
    }

    static func deadlines(matching raw: String, now: Date, calendar: Calendar) -> [CaffeineChoice] {
        guard let date = CaffeineDeadline.parse(raw, now: now, calendar: calendar) else { return [] }
        return [
            CaffeineChoice(
                id: "until-\(Int(date.timeIntervalSince1970))",
                title: CaffeineStatus.untilTitle(date, now: now, calendar: calendar),
                subtitle: String(localized: "Keep the Mac awake"), symbol: "clock", action: .until(date))
        ]
    }

    /// An empty query lists apps only. A typed pid matches even when the name does not contain it.
    static func processes(
        matching raw: String, apps: [CaffeineProcess], others: [CaffeineProcess]
    ) -> [CaffeineChoice] {
        let query = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty { return apps.map(row) }
        let pid = Int32(query)
        let appIDs = Set(apps.map(\.pid))
        let matched = apps.filter { matches($0, query: query, pid: pid) }
        let extra = others.filter { !appIDs.contains($0.pid) && matches($0, query: query, pid: pid) }
        return (matched + extra).map(row)
    }

    private static func matches(_ process: CaffeineProcess, query: String, pid: Int32?) -> Bool {
        process.pid == pid || process.name.localizedCaseInsensitiveContains(query)
    }

    private static func row(_ process: CaffeineProcess) -> CaffeineChoice {
        let subtitle = process.iconPath == nil
            ? String(localized: "Process \(String(process.pid))")
            : String(localized: "Application")
        return CaffeineChoice(
            id: "process-\(process.pid)", title: process.name, subtitle: subtitle, symbol: "cpu",
            action: .process(process))
    }
}
