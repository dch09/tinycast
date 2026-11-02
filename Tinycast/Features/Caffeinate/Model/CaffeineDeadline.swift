import Foundation

/// Clock times a person types into Caffeinate Until. A time already past rolls to the next day.
enum CaffeineDeadline {
    static func parse(_ raw: String, now: Date, calendar: Calendar) -> Date? {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !text.isEmpty else { return nil }
        let (clock, tomorrow) = strippingTomorrow(text)
        guard !clock.isEmpty, let time = time(in: clock, calendar: calendar) else { return nil }
        return date(
            hour: time.hour, minute: time.minute, tomorrow: tomorrow, now: now, calendar: calendar)
    }

    /// English stays accepted beside the translated word, so the placeholder still works.
    private static func strippingTomorrow(_ text: String) -> (String, Bool) {
        let words = Set(["tomorrow", String(localized: "tomorrow").lowercased()])
        for word in words where text == word || text.hasPrefix(word + " ") {
            let rest = text.dropFirst(word.count).trimmingCharacters(in: .whitespaces)
            return (String(rest), true)
        }
        return (text, false)
    }

    private static func time(in text: String, calendar: Calendar) -> (hour: Int, minute: Int)? {
        switch text {
        case "noon": return (12, 0)
        case "midnight": return (0, 0)
        default: break
        }
        guard let match = text.wholeMatch(of: /(\d{1,2})(?::(\d{2}))?\s*([a-z.]+)?/) else {
            return nil
        }
        guard let hour = Int(match.1) else { return nil }
        let minute = match.2.flatMap { Int($0) } ?? 0
        guard (0..<60).contains(minute) else { return nil }
        guard let marker = match.3.map({ String($0) }) else {
            guard (0..<24).contains(hour) else { return nil }
            return (hour, minute)
        }
        guard (1...12).contains(hour) else { return nil }
        if amSymbols(calendar).contains(marker) { return (hour == 12 ? 0 : hour, minute) }
        if pmSymbols(calendar).contains(marker) { return (hour == 12 ? 12 : hour + 12, minute) }
        return nil
    }

    private static func date(
        hour: Int, minute: Int, tomorrow: Bool, now: Date, calendar: Calendar
    ) -> Date? {
        var parts = calendar.dateComponents([.year, .month, .day], from: now)
        parts.hour = hour
        parts.minute = minute
        parts.second = 0
        guard var result = calendar.date(from: parts) else { return nil }
        if tomorrow || result <= now {
            result = calendar.date(byAdding: .day, value: 1, to: result) ?? result
        }
        return result
    }

    private static func amSymbols(_ calendar: Calendar) -> Set<String> {
        var symbols: Set<String> = ["am", "a.m.", "a.m"]
        symbols.insert(meridiem(calendar).am)
        return symbols
    }

    private static func pmSymbols(_ calendar: Calendar) -> Set<String> {
        var symbols: Set<String> = ["pm", "p.m.", "p.m"]
        symbols.insert(meridiem(calendar).pm)
        return symbols
    }

    private static func meridiem(_ calendar: Calendar) -> (am: String, pm: String) {
        let formatter = DateFormatter()
        formatter.locale = calendar.locale ?? .current
        return (formatter.amSymbol.lowercased(), formatter.pmSymbol.lowercased())
    }
}
