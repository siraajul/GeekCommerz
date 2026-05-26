import SwiftUI

struct SplashView: View {
    @State private var scale: CGFloat = 0.72
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            AppTheme.Brand.gradient
                .ignoresSafeArea()

            VStack(spacing: 24) {
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
