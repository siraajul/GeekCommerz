import SwiftUI

struct OnboardingView: View {
    @AppStorage(AppConstants.StorageKeys.hasSeenOnboarding) private var hasSeenOnboarding = false
    @State private var currentPage = 0

    private struct Page {
        let icon: String
        let color: Color
        let title: String
        let subtitle: String
    }

    private let pages: [Page] = [
        Page(icon: "bag.fill",
             color: AppTheme.Colors.primary,
             title: "Welcome to GeekCommerz",
             subtitle: "Your one-stop shop for premium tech products, gadgets, and accessories."),
        Page(icon: "magnifyingglass.circle.fill",
             color: AppTheme.Colors.accent,
             title: "Find Anything Instantly",
             subtitle: "Browse hundreds of products by category, filter by price, or search for exactly what you need."),
        Page(icon: "star.fill",
             color: Color.orange,
             title: "Earn Rewards Every Order",
             subtitle: "Collect loyalty points on every purchase. Redeem them for exclusive discounts and perks."),
    ]

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPage(
                            icon: page.icon,
                            color: page.color,
                            title: page.title,
                            subtitle: page.subtitle
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(.easeInOut, value: currentPage)

                VStack(spacing: 16) {
                    if currentPage < pages.count - 1 {
                        Button {
                            withAnimation { currentPage += 1 }
                        } label: {
                            Text("Next")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .foregroundColor(.white)
                                .background {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(AppTheme.Brand.gradientH)
                                }
                        }

                        Button {
                            hasSeenOnboarding = true
                        } label: {
                            Text("Skip")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Button {
                            hasSeenOnboarding = true
                        } label: {
                            Text("Get Started")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .foregroundColor(.white)
                                .background {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(AppTheme.Brand.gradientH)
                                }
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}

struct OnboardingPage: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(color.opacity(0.10))
                    .frame(width: 210, height: 210)
                Circle()
                    .fill(color.opacity(0.16))
                    .frame(width: 160, height: 160)
                Image(systemName: icon)
                    .font(.system(size: 70))
                    .foregroundColor(color)
            }
            .scaleEffect(appeared ? 1.0 : 0.6)
            .opacity(appeared ? 1.0 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.68)) {
                    appeared = true
                }
            }
            .onDisappear { appeared = false }

            VStack(spacing: 16) {
                Text(title)
                    .font(.title2).bold()
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
