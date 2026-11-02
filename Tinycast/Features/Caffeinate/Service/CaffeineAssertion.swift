import Foundation
import IOKit.pwr_mgt

/// The power assertions behind one hold. A failed swap leaves the previous ids in place.
@MainActor
final class CaffeineAssertion {
    private var ids: [IOPMAssertionID] = []

    func swap(targets: CaffeineTargets, reason: String, timeout: TimeInterval?) -> Bool {
        guard !targets.isEmpty, let created = create(targets, reason: reason, timeout: timeout)
        else { return false }
        release()
        ids = created
        return true
    }

    func release() {
        for id in ids { IOPMAssertionRelease(id) }
        ids.removeAll()
    }

    isolated deinit { release() }

    /// The kernel drops a timed hold if this process never reaches its own deadline.
    private func create(
        _ targets: CaffeineTargets, reason: String, timeout: TimeInterval?
    ) -> [IOPMAssertionID]? {
        var created: [IOPMAssertionID] = []
        for type in Self.types(in: targets) {
            var id = IOPMAssertionID(0)
            let result = IOPMAssertionCreateWithProperties(
                properties(type: type, reason: reason, timeout: timeout), &id)
            guard result == kIOReturnSuccess else {
                created.forEach { IOPMAssertionRelease($0) }
                return nil
            }
            created.append(id)
        }
        return created
    }

    private func properties(type: String, reason: String, timeout: TimeInterval?) -> CFDictionary {
        var properties: [String: Any] = [:]
        properties[kIOPMAssertionTypeKey] = type
        properties[kIOPMAssertionNameKey as String] = "Tinycast"
        // A dynamic sentence has no catalog entry, so it cannot be the localizable reason key.
        properties[kIOPMAssertionDetailsKey as String] = reason
        if let timeout {
            let seconds = max(1, Int(timeout.rounded(.up)))
            properties[kIOPMAssertionTimeoutKey as String] = seconds
            properties[kIOPMAssertionTimeoutActionKey as String] = kIOPMAssertionTimeoutActionRelease
        }
        return properties as CFDictionary
    }

    private static func types(in targets: CaffeineTargets) -> [String] {
        var types: [String] = []
        if targets.contains(.display) { types.append(kIOPMAssertPreventUserIdleDisplaySleep) }
        if targets.contains(.system) { types.append(kIOPMAssertPreventUserIdleSystemSleep) }
        if targets.contains(.disk) { types.append(kIOPMAssertPreventDiskIdle) }
        return types
    }
}
