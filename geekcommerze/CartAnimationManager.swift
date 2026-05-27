import SwiftUI

// MARK: - CartAnimationManager

/// App-wide `@Observable` manager for the cart-fly particle animation injected via `.environment()`.
/// Tracks in-flight particles and the cart tab's on-screen position so `FlyingCartParticle`
/// can arc icons from their origin (e.g. a product card) to the cart tab icon.
@Observable
class CartAnimationManager {

    // MARK: - Particle

    /// Value type describing a single in-flight cart-fly particle.
    struct Particle: Identifiable {
        let id = UUID()
        /// Screen-coordinate origin of the particle.
        let start: CGPoint
        /// SF Symbol name rendered inside the animated circle.
        let imageName: String
    }

    // MARK: - Properties

    /// Live array of in-flight particles observed by the root overlay.
    var particles: [Particle] = []

    /// Screen-space center of the cart tab bar icon — the animation endpoint.
    var cartTabCenter: CGPoint = .zero

    // MARK: - Actions

    /// Appends a new particle originating at `point`, initiating a cart-fly animation.
    func trigger(from point: CGPoint, imageName: String = "cart.fill") {
        particles.append(Particle(start: point, imageName: imageName))
    }

    /// Removes the particle with the matching `id` after its animation has finished.
    func remove(id: UUID) {
        particles.removeAll { $0.id == id }
    }
}

// MARK: - FlyingCartParticle

/// Animates a single cart icon particle from `start` to `end` along a parabolic arc,
/// then calls `onFinished` when the animation completes.
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
