import Foundation

/// A running app or a raw process the While screen can hold for.
struct CaffeineProcess: Equatable, Sendable, Identifiable {
    var pid: Int32
    var name: String
    /// Set for an application, so the row can draw its icon. Nil for a raw process.
    var iconPath: String?

    var id: Int32 { pid }
}
