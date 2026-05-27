import SwiftUI

/// In-app notification model. Codable for UserDefaults persistence. Not related to push notifications.
struct AppNotification: Identifiable, Codable {

    // MARK: - Properties

    /// Stable unique identifier used for list diffing and targeted read/delete operations.
    var id: UUID = UUID()

    /// Short title line shown in the notification row header.
    var title: String

    /// Full descriptive text shown below the title in the notification row.
    var body: String

    /// SF Symbol name used as the notification icon.
    var icon: String

    /// Raw color name string persisted to UserDefaults; resolved to a SwiftUI `Color` via the `color` computed property.
    var colorName: String

    /// Timestamp when the notification was created; defaults to now.
    var date: Date = Date()

    /// False until the user taps the notification or `markAllRead()` is called.
    var isRead: Bool = false

    /// Semantic category string (e.g. "order", "promo", "system") used for grouping or filtering.
    var typeName: String

    /// Resolves `colorName` to a SwiftUI `Color`; falls back to `.blue` for unrecognized values.
    var color: Color {
        switch colorName {
        case "green":  return .green
        case "orange": return .orange
        case "purple": return .purple
        case "red":    return .red
        case "yellow": return .yellow
        default:       return .blue
        }
    }
}

/// Observable store for in-app notifications. Persists to UserDefaults and seeds demo data on first launch. Used by NotificationsView, HomeView (badge), and ContentView.
@Observable
class NotificationStore {

    // MARK: - Properties

    /// Ordered array of notifications, newest first. Read-only externally; mutated via store methods.
    private(set) var notifications: [AppNotification] = []

    /// Count of notifications whose `isRead` is false. Observed by HomeView to display the bell badge.
    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    // MARK: - Init

    /// Initializes the store and loads persisted notifications from UserDefaults.
    init() { load() }

    // MARK: - Actions

    /// Creates a new `AppNotification` with the given parameters, inserts it at the front of the list, and persists to UserDefaults.
    func add(title: String, body: String, icon: String, colorName: String = "blue", typeName: String = "system") {
        let notif = AppNotification(title: title, body: body, icon: icon, colorName: colorName, typeName: typeName)
        notifications.insert(notif, at: 0)
        save()
    }

    /// Marks the notification with the given `id` as read and persists the change; no-ops if `id` is not found.
    func markRead(_ id: UUID) {
        guard let idx = notifications.firstIndex(where: { $0.id == id }) else { return }
        notifications[idx].isRead = true
        save()
    }

    /// Marks every notification as read and persists the change.
    func markAllRead() {
        for i in notifications.indices { notifications[i].isRead = true }
        save()
    }

    /// Removes the notification with the given `id` from the list and persists the change.
    func delete(_ id: UUID) {
        notifications.removeAll { $0.id == id }
        save()
    }

    /// Removes all notifications from the list and persists the empty state.
    func clearAll() {
        notifications.removeAll()
        save()
    }

    // MARK: - Persistence

    /// Loads the notification array from UserDefaults; silently no-ops if no data is stored or decoding fails.
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.StorageKeys.inAppNotifications),
              let decoded = try? JSONDecoder().decode([AppNotification].self, from: data)
        else { return }
        notifications = decoded
    }

    /// Encodes the current notification array and writes it to UserDefaults; silently no-ops if encoding fails.
    private func save() {
        if let data = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(data, forKey: AppConstants.StorageKeys.inAppNotifications)
        }
    }
}
