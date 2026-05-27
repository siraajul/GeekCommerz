import UIKit

// MARK: - HapticFeedback

/// Namespace enum providing static helpers that wrap UIKit haptic generators.
/// Centralises haptic calls so every screen uses a consistent, one-line API.
enum HapticFeedback {
    /// Fires a UIKit impact haptic with the given style (default `.medium`).
    /// Used for confirmatory taps such as add-to-cart and wishlist toggle.
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    /// Fires a UIKit notification haptic (success / warning / error).
    /// Used after async operations such as checkout completion or network errors.
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    /// Fires a UIKit selection-changed haptic.
    /// Used on discrete UI controls such as category pickers and segmented selectors.
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
