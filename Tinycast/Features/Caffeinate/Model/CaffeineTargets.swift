import Foundation

/// Which sleep paths a hold blocks. Disk stays off: keeping it spun up costs battery.
struct CaffeineTargets: OptionSet, Sendable {
    let rawValue: Int

    static let display = CaffeineTargets(rawValue: 1 << 0)
    static let system = CaffeineTargets(rawValue: 1 << 1)
    static let disk = CaffeineTargets(rawValue: 1 << 2)
}
