import SwiftUI

@Observable
class ToastManager {
    var currentToast: ToastItem? = nil
    private var dismissTask: Task<Void, Never>? = nil

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

struct ToastItem: Identifiable {
    let id = UUID()
    let message: String
    let icon: String
    let color: Color
}

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

enum HapticFeedback {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
