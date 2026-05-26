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

// MARK: - Tab Router

@Observable
class TabRouter {
    var selectedTab = 0
}

// MARK: - Cart Fly Animation

@Observable
class CartAnimationManager {
    struct Particle: Identifiable {
        let id = UUID()
        let start: CGPoint
        let imageName: String
    }
    var particles: [Particle] = []
    var cartTabCenter: CGPoint = .zero

    func trigger(from point: CGPoint, imageName: String = "cart.fill") {
        particles.append(Particle(start: point, imageName: imageName))
    }

    func remove(id: UUID) {
        particles.removeAll { $0.id == id }
    }
}

struct FlyingCartParticle: View {
    let start: CGPoint
    let end: CGPoint
    let imageName: String
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
