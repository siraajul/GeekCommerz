import SwiftUI

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -0.5

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: max(0, phase - 0.25)),
                        .init(color: .white.opacity(0.5), location: phase),
                        .init(color: .clear, location: min(1, phase + 0.25)),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .blendMode(.screen)
                .clipped()
            )
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Cards

struct SkeletonProductCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(height: 110)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 12)
                    .padding(.top, 10)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6))
                    .frame(width: 80, height: 10)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 14)
                Spacer()
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(height: 30)
                    .padding(.bottom, 10)
            }
            .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 265)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        .shimmer()
    }
}

struct SkeletonBannerCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemGray5))
            .frame(height: 200)
            .padding(.horizontal, 16)
            .shimmer()
    }
}

struct SkeletonCategoryChip: View {
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray5))
                .frame(width: 52, height: 52)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray6))
                .frame(width: 50, height: 10)
        }
        .frame(width: 70)
        .shimmer()
    }
}
