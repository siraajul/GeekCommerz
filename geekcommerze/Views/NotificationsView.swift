import SwiftUI

extension Date {
    var relativeLabel: String {
        let interval = Date().timeIntervalSince(self)
        if interval < 60    { return "Just now" }
        if interval < 3600  { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        if interval < 172800 { return "Yesterday" }
        return self.formatted(date: .abbreviated, time: .omitted)
    }
}

struct NotificationsView: View {
    @Environment(NotificationStore.self) private var notifStore

    var todayItems: [AppNotification] {
        notifStore.notifications.filter { Calendar.current.isDateInToday($0.date) }
    }

    var earlierItems: [AppNotification] {
        notifStore.notifications.filter { !Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        Group {
            if notifStore.notifications.isEmpty {
                emptyState
            } else {
                notificationList
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if notifStore.unreadCount > 0 {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Mark All Read") {
                        withAnimation { notifStore.markAllRead() }
                        HapticFeedback.impact(.light)
                    }
                    .font(.subheadline)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.4))
            Text("No Notifications")
                .font(.title3).bold()
            Text("You're all caught up! Check back later for updates.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private var notificationList: some View {
        List {
            if !todayItems.isEmpty {
                Section("Today") {
                    ForEach(todayItems) { notif in
                        notificationRow(notif)
                    }
                }
            }

            if !earlierItems.isEmpty {
                Section("Earlier") {
                    ForEach(earlierItems) { notif in
                        notificationRow(notif)
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    withAnimation { notifStore.clearAll() }
                    HapticFeedback.impact(.medium)
                } label: {
                    Text("Clear All Notifications")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .font(.subheadline)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private func notificationRow(_ notif: AppNotification) -> some View {
        NotificationRow(notification: notif)
            .listRowBackground(notif.isRead ? Color(.systemBackground) : Color.blue.opacity(0.05))
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation { notifStore.markRead(notif.id) }
            }
            .swipeActions(edge: .leading) {
                if !notif.isRead {
                    Button {
                        withAnimation { notifStore.markRead(notif.id) }
                    } label: {
                        Label("Read", systemImage: "checkmark.circle")
                    }
                    .tint(.blue)
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    withAnimation { notifStore.delete(notif.id) }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
    }
}

struct NotificationRow: View {
    let notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(notification.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: notification.icon)
                    .font(.title3)
                    .foregroundColor(notification.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.subheadline)
                    .fontWeight(notification.isRead ? .regular : .bold)
                    .foregroundColor(.primary)
                Text(notification.body)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                Text(notification.date.relativeLabel)
                    .font(.caption2)
                    .foregroundColor(Color(.tertiaryLabel))
            }

            Spacer(minLength: 0)

            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
            }
        }
        .padding(.vertical, 4)
    }
}

struct BellBadgeIcon: View {
    let count: Int

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "bell")
                .font(.title3)
                .padding(.top, 7)
                .padding(.trailing, 7)
            if count > 0 {
                Text(count > 9 ? "9+" : "\(count)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .frame(minWidth: 16, minHeight: 16)
                    .background(Color.red)
                    .clipShape(Circle())
            }
        }
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
            .environment({
                let store = NotificationStore()
                store.add(title: "Order Confirmed!", body: "Your order has been placed.", icon: "checkmark.circle.fill", colorName: "green", typeName: "order")
                store.add(title: "Flash Sale!", body: "Up to 40% off Electronics today.", icon: "bolt.fill", colorName: "orange", typeName: "promo")
                return store
            }())
    }
}
