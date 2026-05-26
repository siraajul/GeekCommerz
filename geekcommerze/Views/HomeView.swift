import SwiftUI
import SwiftData
import Combine

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ProductStore.self) private var productStore
    @Environment(CartStore.self) private var cartStore
    @Environment(NotificationStore.self) private var notifStore
    @Environment(TabRouter.self) private var tabRouter
    @State private var selectedProduct: Product? = nil
    @AppStorage(AppConstants.StorageKeys.recentlyViewed) private var recentlyViewedData: String = ""
    @State private var currentBannerIndex: Int = 0
    @State private var showNotifications = false
    @State private var navigateToShop = false
    @State private var shopDestinationCategory: ProductCategory? = nil
    @State private var flashSaleEnd = Date().addingTimeInterval(6 * 3600)
    @State private var flashSaleCountdown = ""
    @State private var isInitialLoading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                if isInitialLoading {
                    skeletonContent
                } else {
                    VStack(alignment: .leading, spacing: 24) {
                        bannerSection
                        categorySection
                        flashSaleBanner
                            .onTapGesture {
                                shopDestinationCategory = .electronics
                                navigateToShop = true
                            }
                        recentlyViewedSection
                        featuredSection
                        freeShippingBanner
                            .onTapGesture {
                                shopDestinationCategory = nil
                                navigateToShop = true
                            }
                        newArrivalsSection
                    }
                    .padding(.bottom, 20)
                    .transition(.opacity)
                }
            }
            .refreshable {
                try? await Task.sleep(for: .milliseconds(700))
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("GeekCommerz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showNotifications = true } label: {
                        BellBadgeIcon(count: notifStore.unreadCount)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { tabRouter.selectedTab = 3 } label: {
                        CartBadgeIcon(count: cartStore.itemCount)
                    }
                }
            }
            .navigationDestination(isPresented: $showNotifications) {
                NotificationsView()
            }
            .navigationDestination(isPresented: $navigateToShop) {
                ShopView(initialCategory: shopDestinationCategory)
            }
            .sheet(item: $selectedProduct) { product in
                ProductDetailView(product: product)
            }
            .onAppear {
                updateFlashSaleCountdown()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeOut(duration: 0.35)) {
                        isInitialLoading = false
                    }
                }
                if notifStore.notifications.isEmpty {
                    notifStore.add(
                        title: "Welcome to GeekCommerze!",
                        body: "Discover amazing products. Use code SAVE20 for 20% off your first order.",
                        icon: "gift.fill",
                        colorName: "purple",
                        typeName: "promo"
                    )
                    notifStore.add(
                        title: "⚡ Flash Sale — Today Only!",
                        body: "Up to 40% off Electronics. Limited stock — grab yours before it's gone!",
                        icon: "bolt.fill",
                        colorName: "orange",
                        typeName: "promo"
                    )
                    notifStore.add(
                        title: "Free Shipping Available",
                        body: "Get free shipping on all orders over $50. Use code FREESHIP at checkout.",
                        icon: "shippingbox.fill",
                        colorName: "green",
                        typeName: "promo"
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var skeletonContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            SkeletonBannerCard()
                .padding(.top, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { _ in SkeletonCategoryChip() }
                }
                .padding(.horizontal, 16)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in SkeletonProductCard() }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 20)
    }

    // MARK: - Inline Promo Banners

    private var flashSaleBanner: some View {
        PromoBannerCard(
            title: "⚡ Flash Sale — Today Only!",
            subtitle: flashSaleCountdown.isEmpty
                ? "Up to 40% off Electronics. Limited stock!"
                : "Ends in \(flashSaleCountdown) · Up to 40% off Electronics!",
            ctaText: "Shop Now",
            gradient: [Color(red: 1, green: 0.4, blue: 0.1), Color(red: 0.85, green: 0.1, blue: 0.2)],
            icon: "bolt.fill"
        )
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            updateFlashSaleCountdown()
        }
    }

    private func updateFlashSaleCountdown() {
        let remaining = flashSaleEnd.timeIntervalSinceNow
        guard remaining > 0 else { flashSaleCountdown = "Ended"; return }
        let h = Int(remaining) / 3600
        let m = (Int(remaining) % 3600) / 60
        let s = Int(remaining) % 60
        flashSaleCountdown = String(format: "%02d:%02d:%02d", h, m, s)
    }

    private var freeShippingBanner: some View {
        PromoBannerCard(
            title: "🚚 Free Shipping",
            subtitle: "On all orders over $50. Use code FREESHIP at checkout.",
            ctaText: "Learn More",
            gradient: [Color(red: 0.1, green: 0.7, blue: 0.5), Color(red: 0.05, green: 0.5, blue: 0.65)],
            icon: "shippingbox.fill"
        )
    }

    // MARK: - Sections

    private func recentlyViewedProducts() -> [Product] {
        let ids = recentlyViewedData.components(separatedBy: ",").filter { !$0.isEmpty }.reversed()
        return ids.compactMap { idStr in
            guard let uuid = UUID(uuidString: idStr) else { return nil }
            return productStore.products.first { $0.id == uuid }
        }
    }

    @ViewBuilder
    private var recentlyViewedSection: some View {
        let products = recentlyViewedProducts()
        if !products.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Recently Viewed", destination: ShopView())
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(products) { product in
                            ProductCard(product: product)
                                .frame(width: 165)
                                .onTapGesture { selectedProduct = product }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    private var bannerSection: some View {
        let featured = Array(productStore.featuredProducts.prefix(4))
        return TabView(selection: $currentBannerIndex) {
            ForEach(Array(featured.enumerated()), id: \.offset) { index, product in
                BannerCard(product: product)
                    .onTapGesture { selectedProduct = product }
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: 200)
        .padding(.top, 8)
        .onReceive(Timer.publish(every: 3.5, on: .main, in: .common).autoconnect()) { _ in
            guard !featured.isEmpty else { return }
            withAnimation {
                currentBannerIndex = (currentBannerIndex + 1) % featured.count
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Categories", destination: ShopView())
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ProductCategory.allCases, id: \.self) { category in
                        CategoryChip(category: category)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Featured", destination: ShopView())
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(productStore.featuredProducts) { product in
                        ProductCard(product: product)
                            .frame(width: 165)
                            .onTapGesture { selectedProduct = product }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var newArrivalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "New Arrivals", destination: ShopView())
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(productStore.products.suffix(6)) { product in
                    ProductCard(product: product)
                        .onTapGesture { selectedProduct = product }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Inline Promo Banner Card

struct PromoBannerCard: View {
    let title: String
    let subtitle: String
    let ctaText: String
    let gradient: [Color]
    let icon: String

    var body: some View {
        ZStack(alignment: .leading) {
            LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(title)
                        .font(.subheadline).bold()
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(2)
                    Text(ctaText)
                        .font(.caption2).bold()
                        .padding(.horizontal, 12).padding(.vertical, 5)
                        .background(.white.opacity(0.22))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .padding(.leading, 20)

                Spacer()

                Image(systemName: icon)
                    .font(.system(size: 52))
                    .foregroundColor(.white.opacity(0.22))
                    .padding(.trailing, 20)
            }
        }
        .frame(height: 110)
        .padding(.horizontal, 16)
    }
}

// MARK: - Promotional Popup

struct PromoPopupView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.3, blue: 0.9), Color(red: 0.5, green: 0.1, blue: 0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                VStack(spacing: 28) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.12))
                            .frame(width: 130, height: 130)
                        Circle()
                            .fill(.white.opacity(0.08))
                            .frame(width: 100, height: 100)
                        Image(systemName: "gift.fill")
                            .font(.system(size: 52))
                            .foregroundColor(.white)
                    }

                    VStack(spacing: 10) {
                        Text("Special Welcome Offer!")
                            .font(.title2).bold()
                            .foregroundColor(.white)
                        Text("Enjoy an exclusive discount on\nyour very first order with us.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.82))
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 8) {
                        Text("USE CODE")
                            .font(.caption).bold()
                            .foregroundColor(.white.opacity(0.65))
                            .tracking(3)

                        Text("SAVE20")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.95))
                            .padding(.horizontal, 32).padding(.vertical, 14)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

                        Text("for 20% off your order")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.75))
                    }

                    VStack(spacing: 14) {
                        Button { dismiss() } label: {
                            Text("Shop Now")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(.white)
                                .foregroundColor(Color(red: 0.1, green: 0.3, blue: 0.9))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Button { dismiss() } label: {
                            Text("Maybe Later")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 32)
                }

                Spacer()
            }
        }
    }
}

// MARK: - Supporting Views

struct BannerCard: View {
    let product: Product

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AppTheme.Brand.gradient
                .clipShape(RoundedRectangle(cornerRadius: 16))

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    if let discount = product.discount {
                        Text("\(discount)% OFF")
                            .font(.caption).bold()
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    Text(product.name)
                        .font(.title3).bold()
                        .foregroundColor(.white)
                        .lineLimit(2)
                    Text("$\(product.price, specifier: "%.2f")")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                }
                Spacer()
                Image(systemName: product.imageName)
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(20)
        }
        .padding(.horizontal, 16)
    }
}

struct CategoryChip: View {
    let category: ProductCategory
    @Environment(ProductStore.self) private var productStore

    var body: some View {
        NavigationLink(destination: ShopView(initialCategory: category)) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(width: 52, height: 52)
                    .background(AppTheme.Brand.tint)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                Text(category.rawValue)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 70, height: 32, alignment: .top)
            }
            .frame(width: 70)
        }
    }
}

struct SectionHeader<D: View>: View {
    let title: String
    let destination: D

    init(title: String, destination: D) {
        self.title = title
        self.destination = destination
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.title3).bold()
            Spacer()
            NavigationLink(destination: destination) {
                Text("See All")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.primary)
            }
        }
        .padding(.horizontal, 16)
    }
}

struct CartBadgeIcon: View {
    let count: Int
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "cart")
                .font(.title3)
            if count > 0 {
                Text("\(count)")
                    .font(.caption2).bold()
                    .foregroundColor(.white)
                    .frame(minWidth: 16, minHeight: 16)
                    .background(Color.red)
                    .clipShape(Circle())
                    .offset(x: 8, y: -8)
            }
        }
        .scaleEffect(scale)
        .onChange(of: count) { _, newCount in
            guard newCount > 0 else { return }
            withAnimation(.spring(duration: 0.18, bounce: 0.7)) { scale = 1.45 }
            withAnimation(.spring(duration: 0.2).delay(0.16)) { scale = 1.0 }
        }
    }
}

#Preview {
    HomeView()
        .environment(ProductStore())
        .environment(CartStore())
        .modelContainer(for: [CartItem.self, Order.self, OrderItem.self], inMemory: true)
}
