import Foundation

/// Durations a person types into Caffeinate for…. A bare number is minutes.
enum CaffeineDuration {
    /// Longer than a day is a schedule, which a single hold is not.
    static let maximum: TimeInterval = 24 * 60 * 60
    static let presets: [TimeInterval] = [5, 15, 30, 60, 120, 240].map { $0 * 60 }

    static func parse(_ raw: String) -> TimeInterval? {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !text.isEmpty else { return nil }
        if let minutes = Double(text) { return accept(minutes * 60) }
        return accept(scan(text))
    }

    static func phrase(_ interval: TimeInterval) -> String {
        formatted(interval, style: .full, units: [.hour, .minute, .second])
    }

    static func remaining(_ interval: TimeInterval) -> String {
        let units: NSCalendar.Unit = interval >= 60 ? [.hour, .minute] : [.second]
        return formatted(max(interval, 0), style: .abbreviated, units: units)
    }

    private static func formatted(
        _ interval: TimeInterval, style: DateComponentsFormatter.UnitsStyle, units: NSCalendar.Unit
    ) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = units
        formatter.unitsStyle = style
        formatter.maximumUnitCount = 2
        formatter.zeroFormattingBehavior = .dropAll
        let rounded = Int(interval.rounded())
        return formatter.string(from: interval) ?? String(localized: "\(rounded) seconds")
    }

    private static func accept(_ interval: TimeInterval?) -> TimeInterval? {
        guard let interval, interval >= 1, interval <= maximum else { return nil }
        return interval
    }

    /// Units may be written `1h30m` or `1 hour 30 minutes`. A number without a unit fails.
    private static func scan(_ text: String) -> TimeInterval? {
        var index = text.startIndex
        var total: TimeInterval = 0
        var sawUnit = false
        while index < text.endIndex {
            while index < text.endIndex, text[index].isWhitespace { index = text.index(after: index) }
            guard index < text.endIndex else { break }
            let numberStart = index
            while index < text.endIndex, text[index].isNumber || text[index] == "." {
                index = text.index(after: index)
            }
            guard numberStart < index, let value = Double(text[numberStart..<index]), value >= 0
            else { return nil }
            while index < text.endIndex, text[index].isWhitespace { index = text.index(after: index) }
            let unitStart = index
            while index < text.endIndex, text[index].isLetter {
                index = text.index(after: index)
            }
            let seconds: TimeInterval
            switch String(text[unitStart..<index]) {
            case "h", "hr", "hrs", "hour", "hours": seconds = value * 3600
            case "m", "min", "mins", "minute", "minutes": seconds = value * 60
            case "s", "sec", "secs", "second", "seconds": seconds = value
            default: return nil
            }
            sawUnit = true
            total += seconds
        }
        return sawUnit ? total : nil
    }
}
