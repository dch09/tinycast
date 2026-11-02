import Foundation

/// The one live hold. Targets are the ones acquired, so a later settings edit can reacquire them.
struct CaffeineHold: Equatable, Sendable {
    var targets: CaffeineTargets
    var limit: CaffeineLimit
}
