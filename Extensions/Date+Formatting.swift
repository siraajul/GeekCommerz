import Foundation

// MARK: - Date formatting helpers

extension Date {

    /// Human-readable relative label for notification timestamps.
    var relativeLabel: String {
        let interval = Date().timeIntervalSince(self)
        if interval < 60      { return "Just now" }
        if interval < 3_600   { return "\(Int(interval / 60))m ago" }
        if interval < 86_400  { return "\(Int(interval / 3_600))h ago" }
        if interval < 172_800 { return "Yesterday" }
        return self.formatted(date: .abbreviated, time: .omitted)
    }
}
