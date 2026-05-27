import SwiftUI

/// App-wide `@Observable` toast presenter injected via `.environment()`. Manages a single visible
/// `ToastItem` at a time and auto-dismisses it after 2.2 seconds. Used from any screen that needs
/// transient feedback (add-to-cart, wishlist toggle, checkout success, etc.).
@Observable
class ToastManager {

    // MARK: - Properties

    /// The toast currently visible on screen, or `nil` when no toast is showing. Observed by the root overlay in `ContentView`.
    var currentToast: ToastItem? = nil

    /// Handle to the active auto-dismiss `Task`, retained so a new `show` call can cancel an in-flight dismissal.
    private var dismissTask: Task<Void, Never>? = nil

    // MARK: - Actions

    /// Presents a toast with the given message, SF Symbol icon, and accent color. Cancels any pending dismissal before showing the new toast, then schedules auto-dismissal after 2.2 seconds. Safe to call from any context.
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

/// Value type representing a single transient toast notification. Conforms to `Identifiable` so SwiftUI can track it in overlays.
struct ToastItem: Identifiable {
    /// Stable unique identifier used by SwiftUI to diff toast transitions in the root overlay.
    let id = UUID()
    /// Human-readable feedback string displayed in the toast pill. Sourced from the call-site (e.g. "Added to cart").
    let message: String
    /// SF Symbol name rendered as the leading icon inside `ToastOverlay`. Defaults to `"checkmark.circle.fill"`.
    let icon: String
    /// Accent color applied to the icon. Communicates success (green), warning (orange), or error (red) at a glance.
    let color: Color
}

/// SwiftUI view that renders a single `ToastItem` as a floating capsule pill at the bottom of the screen. Composed inside the root overlay managed by `ToastManager`.
struct ToastOverlay: View {
    /// The toast data to display. Provided by `ToastManager.currentToast` in the root overlay.
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

/// Namespace enum providing static helpers that wrap UIKit haptic generators. Centralises haptic calls so
/// every screen (ProductDetailView, CartView, WishlistView, etc.) uses a consistent, one-line API.
enum HapticFeedback {
    /// Fires a UIKit impact haptic with the given style (default `.medium`). Used for confirmatory taps such as add-to-cart and wishlist toggle.
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    /// Fires a UIKit notification haptic for the given feedback type (success / warning / error). Used after async operations such as checkout completion or network errors.
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    /// Fires a UIKit selection-changed haptic. Used on discrete UI controls such as category pickers and segmented selectors.
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

// MARK: - Tab Router

/// App-wide `@Observable` tab router injected via `.environment()`. Allows any screen to switch the root `TabView` programmatically without a direct reference to the tab bar.
@Observable
class TabRouter {
    /// Index of the currently selected tab (0 = Home, 1 = Shop, 2 = Cart, 3 = Orders, 4 = Profile). Written by deep-link handlers and post-checkout flows.
    var selectedTab = 0
}

// MARK: - Cart Fly Animation

/// App-wide `@Observable` manager for the cart-fly particle animation injected via `.environment()`.
/// Tracks in-flight particles and the cart tab's on-screen position so `FlyingCartParticle` can arc
/// icons from their origin (e.g. a product card) to the cart tab icon.
@Observable
class CartAnimationManager {
    /// Value type describing a single in-flight cart-fly particle, identified so SwiftUI can manage its lifetime in a `ForEach`.
    struct Particle: Identifiable {
        /// Stable UUID used to match particles when removing them after their animation completes.
        let id = UUID()
        /// Screen-coordinate origin of the particle, typically the center of the tapped product image or add-to-cart button.
        let start: CGPoint
        /// SF Symbol name rendered inside the animated circle (defaults to `"cart.fill"`).
        let imageName: String
    }

    // MARK: - Properties

    /// Live array of in-flight particles. Observed by the root overlay to render `FlyingCartParticle` views.
    var particles: [Particle] = []

    /// Screen-space center of the cart tab bar icon. Written by the tab bar view and read by `FlyingCartParticle` as the animation endpoint.
    var cartTabCenter: CGPoint = .zero

    // MARK: - Actions

    /// Appends a new `Particle` originating at `point`, initiating a cart-fly animation for the given icon. Called from ProductDetailView and ShopView when the user adds an item.
    func trigger(from point: CGPoint, imageName: String = "cart.fill") {
        particles.append(Particle(start: point, imageName: imageName))
    }

    /// Removes the particle with the matching `id` from the live array after its animation has finished. Called by `FlyingCartParticle.onFinished`.
    func remove(id: UUID) {
        particles.removeAll { $0.id == id }
    }
}

/// SwiftUI view that animates a single cart icon particle from `start` to `end` along a parabolic arc, then calls `onFinished` when the animation completes. Rendered by the root overlay managed by `CartAnimationManager`.
struct FlyingCartParticle: View {
    /// Screen-space origin of the particle, captured at the moment the add-to-cart action fires.
    let start: CGPoint
    /// Screen-space destination — the cart tab icon center as reported by `CartAnimationManager.cartTabCenter`.
    let end: CGPoint
    /// SF Symbol name rendered inside the animated circle (typically `"cart.fill"`).
    let imageName: String
    /// Closure called on the main actor once the full animation sequence (0.65 s) completes. Used to remove the particle from `CartAnimationManager.particles`.
    let onFinished: () -> Void

    @State private var offsetX: CGFloat = 0
    @State private var offsetY: CGFloat = 0
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    private var dx: CGFloat { end.x - start.x }
    private var dy: CGFloat { end.y - start.y }
    private var arcLift: CGFloat { -min(abs(dy) * 0.48, 100) }

    var body: some View {
        Image(systemName: imageName)
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 30, height: 30)
            .background(Color.blue)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1.5))
            .shadow(color: .blue.opacity(0.45), radius: 8)
            .scaleEffect(scale)
            .opacity(opacity)
            .position(start)
            .offset(x: offsetX, y: offsetY)
            .onAppear {
                withAnimation(.spring(response: 0.18, dampingFraction: 0.6)) {
                    scale = 1.2; opacity = 1
                }
                withAnimation(.easeOut(duration: 0.25).delay(0.12)) {
                    offsetX = dx * 0.38; offsetY = arcLift; scale = 1.0
                }
                withAnimation(.easeIn(duration: 0.28).delay(0.34)) {
                    offsetX = dx; offsetY = dy; scale = 0.25; opacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { onFinished() }
            }
    }
}
