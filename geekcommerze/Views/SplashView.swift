import SwiftUI

/// Branded launch screen shown on every app start after onboarding. Animates in with a spring scale and fades out after a brief delay.
struct SplashView: View {
    /// Starting scale for the spring entrance animation.
    @State private var scale: CGFloat = 0.72
    /// Starting opacity for the spring entrance animation.
    @State private var opacity: Double = 0

    // MARK: - Body

    var body: some View {
        ZStack {
            AppTheme.Brand.gradient
                .ignoresSafeArea()

            VStack(spacing: 24) {

                // MARK: - Logo

                ZStack {
                    Circle()
                        .fill(.white.opacity(0.12))
                        .frame(width: 140, height: 140)
                    Circle()
                        .fill(.white.opacity(0.08))
                        .frame(width: 108, height: 108)
                    Image(systemName: "bag.fill")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundColor(.white)
                }

                // MARK: - Wordmark

                VStack(spacing: 6) {
                    Text("GeekCommerz")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("Shop smarter. Earn rewards.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.72))
                }
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
