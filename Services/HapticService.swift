import UIKit

// MARK: - HapticFeedback
// Wraps UIKit haptic generators with a clean, call-site-friendly API.
// Usage: HapticFeedback.notification(.success)

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
