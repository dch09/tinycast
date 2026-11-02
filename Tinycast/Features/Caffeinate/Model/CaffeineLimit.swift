import Foundation

/// How a hold ends. A new case needs a watcher, and a screen only if it asks for input.
enum CaffeineLimit: Equatable, Sendable {
    case indefinite
    case until(Date)
    /// The pid that was running at the start. A relaunch of the same name is a different hold.
    case whileRunning(pid: Int32, name: String)
}
