import AppKit
import Darwin

/// Running apps for the While screen, plus a name or pid search across every process.
@MainActor
enum CaffeineProcessList {
    static func isAlive(_ pid: Int32) -> Bool {
        guard pid > 0 else { return false }
        if kill(pid, 0) == 0 { return true }
        return errno == EPERM
    }

    static func runningApps() -> [CaffeineProcess] {
        let own = Bundle.main.bundleIdentifier
        return NSWorkspace.shared.runningApplications.compactMap { app in
            guard app.activationPolicy == .regular || app.activationPolicy == .accessory,
                app.bundleIdentifier != own, app.processIdentifier > 0,
                let name = app.localizedName, !name.isEmpty
            else { return nil }
            return CaffeineProcess(
                pid: app.processIdentifier, name: name, iconPath: app.bundleURL?.path)
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    static func matching(_ raw: String, excluding: Set<Int32>) -> [CaffeineProcess] {
        let query = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        let needle = query.lowercased()
        let wanted = Int32(query)
        var matches: [CaffeineProcess] = []
        for pid in allPIDs() where pid != getpid() && !excluding.contains(pid) {
            let name = processName(pid)
            guard !name.isEmpty else { continue }
            guard pid == wanted || name.lowercased().contains(needle) else { continue }
            matches.append(CaffeineProcess(pid: pid, name: name, iconPath: nil))
        }
        matches.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        if matches.count > matchLimit { matches = Array(matches.prefix(matchLimit)) }
        if let wanted, isAlive(wanted), !excluding.contains(wanted),
            !matches.contains(where: { $0.pid == wanted })
        {
            let name = processName(wanted)
            if !name.isEmpty {
                matches.insert(CaffeineProcess(pid: wanted, name: name, iconPath: nil), at: 0)
            }
        }
        return matches
    }

    private static let matchLimit = 20

    /// The call reports bytes. A full buffer was truncated, so the next pass asks for more.
    private static func allPIDs() -> [pid_t] {
        var capacity = max(Int(proc_listallpids(nil, 0)) / MemoryLayout<pid_t>.size, 1)
        for _ in 0..<3 {
            var pids = [pid_t](repeating: 0, count: capacity)
            let written = pids.withUnsafeMutableBufferPointer { buffer in
                proc_listallpids(
                    buffer.baseAddress, Int32(buffer.count * MemoryLayout<pid_t>.size))
            }
            guard written > 0 else { return [] }
            let used = Int(written) / MemoryLayout<pid_t>.size
            if used < capacity { return Array(pids.prefix(used)).filter { $0 > 0 } }
            capacity = max(used, capacity) * 2
        }
        return []
    }

    private static func processName(_ pid: pid_t) -> String {
        var buffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        guard proc_name(pid, &buffer, UInt32(buffer.count)) > 0 else { return "" }
        let end = buffer.firstIndex(of: 0) ?? buffer.count
        let bytes = buffer[..<end].map { UInt8(bitPattern: $0) }
        return String(bytes: bytes, encoding: .utf8) ?? ""
    }
}
