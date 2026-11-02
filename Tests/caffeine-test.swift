import Foundation

@main
@MainActor
struct CaffeineTests {
    static var failures = 0
    static var passes = 0

    static func expect<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
        if actual == expected {
            passes += 1
        } else {
            failures += 1
            print("FAIL: \(message)\n  got  \(actual)\n  want \(expected)")
        }
    }

    static func main() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(
            year: 2026, month: 11, day: 2, hour: 13, minute: 32))!

        func expectTime(_ raw: String, day: Int, _ hour: Int, _ minute: Int, _ message: String) {
            guard let date = CaffeineDeadline.parse(raw, now: now, calendar: calendar) else {
                failures += 1
                print("FAIL: \(message)\n  got  nil")
                return
            }
            let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            expect(parts.year, 2026, message)
            expect(parts.month, 11, message)
            expect(parts.day, day, message)
            expect(parts.hour, hour, message)
            expect(parts.minute, minute, message)
        }

        expectTime("5pm", day: 2, 17, 0, "5pm is later today")
        expectTime("1pm", day: 3, 13, 0, "1pm has passed, so it is tomorrow")
        expectTime("17:30", day: 2, 17, 30, "17:30 is later today")
        expectTime("5:30 pm", day: 2, 17, 30, "5:30 pm is later today")
        expectTime("tomorrow 9am", day: 3, 9, 0, "tomorrow 9am is the next morning")
        expectTime("9", day: 3, 9, 0, "9 has passed, so it is tomorrow morning")
        expectTime("tomorrow 5pm", day: 3, 17, 0, "tomorrow 5pm is one day ahead, not two")
        expectTime("Tomorrow 9AM", day: 3, 9, 0, "the tomorrow prefix is case-insensitive")
        expectTime("noon", day: 3, 12, 0, "noon has passed")
        expectTime("midnight", day: 3, 0, 0, "midnight has passed")
        expectTime("12pm", day: 3, 12, 0, "12pm is noon")
        expectTime("12am", day: 3, 0, 0, "12am is midnight")
        expectTime("0:15", day: 3, 0, 15, "0:15 has passed")
        expect(CaffeineDeadline.parse("24:00", now: now, calendar: calendar), nil, "24:00 is not a time")
        expect(CaffeineDeadline.parse("13pm", now: now, calendar: calendar), nil, "13pm is not a clock")
        expect(CaffeineDeadline.parse("tomorrow", now: now, calendar: calendar), nil, "tomorrow needs a time")
        expect(
            CaffeineDeadline.parse("5pm tomorrow", now: now, calendar: calendar), nil,
            "tomorrow only leads")

        let morning = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now)!
        let ahead = CaffeineDeadline.parse("tomorrow 5pm", now: morning, calendar: calendar)
        let aheadParts = ahead.map {
            calendar.dateComponents([.day, .hour], from: $0)
        }
        expect(aheadParts?.day, 3, "tomorrow adds a day even when the time is still ahead")
        expect(aheadParts?.hour, 17, "tomorrow 5pm keeps the hour")
        let laterToday = CaffeineDeadline.parse("5pm", now: morning, calendar: calendar)
        expect(
            laterToday.map { calendar.component(.day, from: $0) }, 2,
            "5pm in the morning is still today")

        expect(CaffeineDuration.parse(""), nil, "an empty duration is not one")
        expect(CaffeineDuration.parse("   "), nil, "whitespace is not a duration")
        expect(CaffeineDuration.parse("30"), 1800, "a bare number is minutes")
        expect(CaffeineDuration.parse("1.5"), 90, "a bare fraction is minutes")
        expect(CaffeineDuration.parse("1h"), 3600, "h is hours")
        expect(CaffeineDuration.parse("1h30m"), 5400, "units can be written together")
        expect(CaffeineDuration.parse("1 hour 30 minutes"), 5400, "units can be words")
        expect(CaffeineDuration.parse("90m"), 5400, "m is minutes")
        expect(CaffeineDuration.parse("1.5h"), 5400, "a fraction can take a unit")
        expect(CaffeineDuration.parse("45s"), 45, "s is seconds")
        expect(CaffeineDuration.parse("1s"), 1, "one second is the shortest hold")
        expect(CaffeineDuration.parse("0"), nil, "zero is not a hold")
        expect(CaffeineDuration.parse("0s"), nil, "zero seconds is not a hold")
        expect(CaffeineDuration.parse("25h"), nil, "longer than a day is not a hold")
        expect(CaffeineDuration.parse("1h 30"), nil, "a number still needs its unit")
        expect(CaffeineDuration.parse("abc"), nil, "words are not a duration")
        expect(CaffeineDuration.parse("1,5h"), nil, "the decimal mark is a point")
        expect(CaffeineDuration.parse("24h"), 86_400, "a day is the longest hold")
        expect(CaffeineDuration.parse("1440 minutes"), 86_400, "a day in minutes")
        expect(CaffeineDuration.parse("86400s"), 86_400, "a day in seconds")
        expect(CaffeineDuration.parse("1441 minutes"), nil, "a minute past a day is not a hold")

        let presets = CaffeineChoice.durations(matching: "")
        expect(presets.count, 6, "an empty duration query lists the presets")
        expect(CaffeineChoice.durations(matching: "90").count, 1, "a typed duration is one row")
        if case .duration(let interval) = CaffeineChoice.durations(matching: "90").first?.action {
            expect(interval, 5400, "90 is ninety minutes")
        } else {
            expect(false, true, "90 is a duration row")
        }
        expect(CaffeineChoice.durations(matching: "nope").isEmpty, true, "an unknown duration is no row")

        let xcode = CaffeineProcess(pid: 11, name: "Xcode", iconPath: "/Xcode.app")
        let slack = CaffeineProcess(pid: 22, name: "Slack", iconPath: "/Slack.app")
        let other = CaffeineProcess(pid: 33, name: "WindowServer", iconPath: nil)
        let apps = [xcode, slack]
        expect(
            CaffeineChoice.processes(matching: "", apps: apps, others: [other]).map(\.title),
            ["Xcode", "Slack"], "an empty process query keeps the apps, in order")
        expect(
            CaffeineChoice.processes(matching: "sl", apps: apps, others: [other]).map(\.title),
            ["Slack"], "a name matches within the apps")
        expect(
            CaffeineChoice.processes(matching: "11", apps: apps, others: [other]).map(\.title),
            ["Xcode"], "a pid matches even when the name does not contain it")

        expect(
            CaffeineStatus.summary(.indefinite, now: now, calendar: calendar),
            "Keeping the Mac awake", "an open-ended hold says so")
        expect(
            CaffeineStatus.summary(.whileRunning(pid: 1, name: "Slack"), now: now, calendar: calendar)
                .contains("Slack"),
            true, "a process hold names the process")
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        expect(
            CaffeineStatus.summary(.until(tomorrow), now: now, calendar: calendar).contains("tomorrow"),
            true, "tomorrow is named")
        let today = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: now)!
        expect(
            CaffeineStatus.summary(.until(today), now: now, calendar: calendar).contains("tomorrow"),
            false, "later today is not called tomorrow")
        let after = calendar.date(byAdding: .day, value: 2, to: now)!
        expect(
            CaffeineStatus.summary(.until(after), now: now, calendar: calendar).contains("tomorrow"),
            false, "a later day is not called tomorrow")
        expect(CaffeineStatus.menuTitle(.indefinite, now: now), "", "an open-ended hold has no time")
        expect(
            CaffeineStatus.menuTitle(.whileRunning(pid: 1, name: "Slack"), now: now), "Slack",
            "the menu bar names the process")
        expect(
            CaffeineStatus.menuTitle(.until(today), now: now).isEmpty, false,
            "a deadline leaves a remaining time")

        print("\(passes) passed, \(failures) failed")
        if failures > 0 { exit(1) }
    }
}
