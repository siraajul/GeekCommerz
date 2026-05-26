import SwiftUI

struct OnboardingView: View {
    @AppStorage(AppConstants.StorageKeys.hasSeenOnboarding) private var hasSeenOnboarding = false
    @State private var currentPage = 0

    private let pages: [(icon: String, color: Color, title: String, subtitle: String)] = [
        ("bag.fill", .blue,
         "Welcome to GeekCommerze",
         "Your one-stop shop for premium tech products, gadgets, and accessories."),
        ("magnifyingglass.circle.fill", .purple,
         "Find Anything Instantly",
         "Browse hundreds of products by category, filter by price, or search for exactly what you need."),
        ("star.fill", .orange,
         "Earn Rewards Every Order",
         "Collect loyalty points on every purchase. Redeem them for exclusive discounts and perks."),
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
                                .background(pages[currentPage].color)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
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
                                .background(pages[currentPage].color)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
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

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 160, height: 160)
                Circle()
                    .fill(color.opacity(0.07))
                    .frame(width: 210, height: 210)
                Image(systemName: icon)
                    .font(.system(size: 70))
                    .foregroundColor(color)
            }

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
