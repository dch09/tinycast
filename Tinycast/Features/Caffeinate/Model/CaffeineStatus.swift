import Foundation

/// The sentences the HUD, the menu bar and the Until rows share.
enum CaffeineStatus {
    static func summary(_ limit: CaffeineLimit, now: Date, calendar: Calendar) -> String {
        switch limit {
        case .indefinite:
            String(localized: "Keeping the Mac awake")
        case .until(let date):
            keepingAwake(until: date, now: now, calendar: calendar)
        case .whileRunning(_, let name):
            String(localized: "Keeping the Mac awake while \(name) is running")
        }
    }

    static func untilTitle(_ date: Date, now: Date, calendar: Calendar) -> String {
        let clock = date.formatted(date: .omitted, time: .shortened)
        if calendar.isDateInTomorrow(date) {
            return String(localized: "Until tomorrow at \(clock)")
        }
        if calendar.isDate(date, equalTo: now, toGranularity: .day) {
            return String(localized: "Until \(clock)")
        }
        let day = date.formatted(date: .abbreviated, time: .omitted)
        return String(localized: "Until \(day) at \(clock)")
    }

    /// Empty for an open-ended hold: the menu bar cup is the whole label.
    static func menuTitle(_ limit: CaffeineLimit, now: Date) -> String {
        switch limit {
        case .indefinite: ""
        case .until(let date): CaffeineDuration.remaining(date.timeIntervalSince(now))
        case .whileRunning(_, let name): name
        }
    }

    private static func keepingAwake(until date: Date, now: Date, calendar: Calendar) -> String {
        let clock = date.formatted(date: .omitted, time: .shortened)
        if calendar.isDateInTomorrow(date) {
            return String(localized: "Keeping the Mac awake until tomorrow at \(clock)")
        }
        if calendar.isDate(date, equalTo: now, toGranularity: .day) {
            return String(localized: "Keeping the Mac awake until \(clock)")
        }
        let day = date.formatted(date: .abbreviated, time: .omitted)
        return String(localized: "Keeping the Mac awake until \(day) at \(clock)")
    }
}
