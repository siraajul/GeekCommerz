import SwiftUI

struct AppNotification: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var body: String
    var icon: String
    var colorName: String
    var date: Date = Date()
    var isRead: Bool = false
    var typeName: String

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

@Observable
class NotificationStore {
    private(set) var notifications: [AppNotification] = []

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    init() { load() }

    func add(title: String, body: String, icon: String, colorName: String = "blue", typeName: String = "system") {
        let notif = AppNotification(title: title, body: body, icon: icon, colorName: colorName, typeName: typeName)
        notifications.insert(notif, at: 0)
        save()
    }

    func markRead(_ id: UUID) {
        guard let idx = notifications.firstIndex(where: { $0.id == id }) else { return }
        notifications[idx].isRead = true
        save()
    }

    func markAllRead() {
        for i in notifications.indices { notifications[i].isRead = true }
        save()
    }

    func delete(_ id: UUID) {
        notifications.removeAll { $0.id == id }
        save()
    }

    func clearAll() {
        notifications.removeAll()
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.StorageKeys.inAppNotifications),
              let decoded = try? JSONDecoder().decode([AppNotification].self, from: data)
        else { return }
        notifications = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(data, forKey: AppConstants.StorageKeys.inAppNotifications)
        }
    }
}
