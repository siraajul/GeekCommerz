import SwiftUI

// MARK: - ToastManager

/// App-wide `@Observable` toast presenter injected via `.environment()`.
/// Manages a single visible `ToastItem` at a time and auto-dismisses it after 2.2 seconds.
@Observable
class ToastManager {

    // MARK: - Properties

    /// The toast currently visible on screen, or `nil` when no toast is showing.
    var currentToast: ToastItem? = nil

    private var dismissTask: Task<Void, Never>? = nil

    // MARK: - Actions

    /// Presents a toast with the given message, SF Symbol icon, and accent color.
    /// Cancels any pending dismissal before showing the new toast.
    func show(_ message: String, icon: String = "checkmark.circle.fill", color: Color = .green) {
        dismissTask?.cancel()
        withAnimation(.spring(duration: 0.35)) {
            currentToast = ToastItem(message: message, icon: icon, color: color)
        }
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(2.2))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.25)) {
                    self.currentToast = nil
                }
            }
        }
    }
}

// MARK: - ToastItem

/// Value type representing a single transient toast notification.
struct ToastItem: Identifiable {
    let id = UUID()
    let message: String
    let icon: String
    let color: Color
}

// MARK: - ToastOverlay

/// Floating capsule pill rendered by the root overlay in `ContentView`.
struct ToastOverlay: View {
    let toast: ToastItem

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: toast.icon)
                .foregroundStyle(toast.color)
                .font(.system(size: 15, weight: .semibold))
            Text(toast.message)
                .font(.subheadline).bold()
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 13)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.12), radius: 14, y: 4)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
