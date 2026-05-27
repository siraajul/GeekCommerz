import SwiftUI
import SwiftData
import Charts
import UserNotifications

/// Immutable data model for a single user-submitted product review, used by `mockReviews` and `ReviewCard`.
struct ProductReview: Identifiable {
    /// Unique string identifier combining the product UUID and pool index.
    let id: String
    /// Display name of the reviewer (e.g. "Sarah M.").
    let name: String
    /// Two-letter initials shown in the avatar circle.
    let initials: String
    /// Star rating given by the reviewer, from 1 to 5.
    let rating: Int
    /// Formatted date string when the review was posted (e.g. "May 12, 2026").
    let date: String
    /// Full review text body.
    let comment: String
    /// True when the review is marked as a verified purchase.
    let isVerified: Bool
    /// Number of users who found this review helpful at time of creation.
    let helpfulCount: Int
}

/// Full-screen detail sheet for a single product, featuring image zoom, variant selectors, price sparkline, reviews, and add-to-cart.
struct ProductDetailView: View {
    let product: Product
    @Environment(\.modelContext) private var modelContext
    @Environment(CartStore.self) private var cartStore
    @Query private var cartItems: [CartItem]
    @Environment(ProductStore.self) private var productStore
    @Environment(\.dismiss) private var dismiss
    @Environment(ToastManager.self) private var toastManager
    @AppStorage(AppConstants.StorageKeys.wishlist) private var wishlistData: String = ""
    @AppStorage(AppConstants.StorageKeys.recentlyViewed) private var recentlyViewedData: String = ""
    @State private var quantity: Int = 1
    @State private var addedToCart = false
    @State private var selectedTab = 0
    @State private var selectedRelatedProduct: Product? = nil
    @State private var selectedColorName = ""
    @State private var selectedSize = ""
    @State private var showWriteReview = false
    @State private var notifyMeSet = false
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    @State private var showUpsells = false
    @State private var showImageGallery = false
    @State private var showSizeGuide = false

    /// True when the current product's UUID is stored in the `@AppStorage` wishlist string.
    var isWishlisted: Bool {
        wishlistData.components(separatedBy: ",").contains(product.id.uuidString)
    }

    /// Up to 6 products in the same category, excluding the current product. Used by `peopleAlsoBuySection`.
    var relatedProducts: [Product] {
        productStore.products
            .filter { $0.category == product.category && $0.id != product.id }
            .prefix(6)
            .map { $0 }
    }

    /// Two deterministically selected products (seeded by the product's UUID hash) shown in the bundle upsell row.
    var frequentlyBoughtTogether: [Product] {
        let others = productStore.products.filter { $0.id != product.id }
        guard others.count >= 2 else { return Array(others.prefix(2)) }
        var seed = UInt(bitPattern: product.id.hashValue) &* 2_654_435_761
        seed = seed &* 1_664_525 &+ 1_013_904_223
        let idx1 = Int(seed % UInt(others.count))
        seed = seed &* 1_664_525 &+ 1_013_904_223
        var idx2 = Int(seed % UInt(others.count))
        if idx2 == idx1 { idx2 = (idx1 + 1) % others.count }
        return [others[idx1], others[idx2]]
    }

    /// Deterministic pseudo-random count (3–30) of concurrent viewers, seeded per product UUID.
    var socialProofViewing: Int {
        var seed = UInt(bitPattern: product.id.hashValue) &* 2_246_822_519
        seed = seed &* 1_664_525 &+ 1_013_904_223
        return 3 + Int(seed % 28)
    }

    /// Deterministic pseudo-random count (4–50) of units sold today, seeded per product UUID.
    var socialProofSoldToday: Int {
        var seed = UInt(bitPattern: product.id.hashValue) &* 3_266_489_917
        seed = seed &* 1_664_525 &+ 1_013_904_223
        return 4 + Int(seed % 47)
    }

    /// Category-specific list of color name/`Color` pairs shown as tappable swatches in the info section.
    var colorVariants: [(name: String, color: Color)] {
        switch product.category {
        case .electronics:
            return [("Space Gray", Color(white: 0.45)), ("Silver", Color(white: 0.85)), ("Midnight", Color(red: 0.1, green: 0.1, blue: 0.25)), ("Gold", Color(red: 0.82, green: 0.68, blue: 0.38))]
        case .clothing:
            return [("Black", Color(white: 0.08)), ("White", Color(white: 0.92)), ("Navy", Color(red: 0.05, green: 0.12, blue: 0.45)), ("Olive", Color(red: 0.33, green: 0.37, blue: 0.18))]
        case .homeGarden:
            return [("Natural", Color(red: 0.82, green: 0.72, blue: 0.56)), ("White", Color(white: 0.95)), ("Charcoal", Color(white: 0.25))]
        case .sports:
            return [("Black", Color(white: 0.08)), ("Blue", Color(red: 0.1, green: 0.35, blue: 0.9)), ("Red", Color(red: 0.85, green: 0.12, blue: 0.12))]
        case .books:
            return []
        }
    }

    /// Category-specific size labels (clothing sizes, storage capacities, or sport fit ranges); empty for categories without size variants.
    var sizeVariants: [String] {
        switch product.category {
        case .clothing:
            return ["XS", "S", "M", "L", "XL", "XXL"]
        case .electronics:
            return ["128GB", "256GB", "512GB"]
        case .sports:
            return ["S/M", "M/L", "L/XL"]
        default:
            return []
        }
    }

    /// 30 daily price points with ±10% pseudo-random variation around the product's current price, used by `priceSparkline`.
    var priceHistory: [(day: Int, price: Double)] {
        var seed = UInt(bitPattern: product.id.hashValue) &* 2_891_336_453
        return (0..<30).map { day in
            seed = seed &* 1_664_525 &+ 1_013_904_223
            let pct = Double(Int(seed % 21) - 10) / 100.0
            return (day: day, price: max(0.01, product.price * (1.0 + pct)))
        }
    }

    static let reviewPool: [(name: String, initials: String, comment: String, isVerified: Bool, helpfulCount: Int)] = [
        ("Sarah M.", "SM", "Absolutely love this! Build quality is excellent and it arrived well-packaged. Will definitely buy again.", true, 34),
        ("James R.", "JR", "Great value for money. Works exactly as described. Would definitely recommend to anyone looking for this.", true, 21),
        ("Priya K.", "PK", "Pretty good overall. Delivery was fast. Packaging could be better but the product itself is solid.", false, 8),
        ("Tom B.", "TB", "This is my second purchase. Top quality and ships quickly. My go-to brand now.", true, 15),
        ("Anika S.", "AS", "Looks great and functions well. Setup was straightforward. Very happy with this purchase!", true, 6),
        ("David L.", "DL", "Excellent product. Does everything it says. Already recommended it to three friends.", true, 29),
        ("Emma K.", "EK", "Arrived quickly and in perfect condition. Really impressed with the overall quality.", true, 18),
        ("Marco P.", "MP", "Good quality but slightly smaller than I expected. Otherwise works perfectly and looks premium.", false, 5),
        ("Lena H.", "LH", "Amazing! This has completely changed how I work. 10/10 would recommend to everyone.", true, 42),
        ("Ali R.", "AR", "Solid product, delivered on time. Instructions could be clearer but figured it out fine.", false, 11),
        ("Nour A.", "NA", "Very impressed with the quality. Looks and feels premium. Worth every single penny.", true, 23),
        ("Chris T.", "CT", "Exactly what I needed. Simple, effective, and well-made. No complaints at all.", true, 9),
        ("Yuki S.", "YS", "Super fast delivery and the product is even better in person. Highly recommend!", true, 37),
        ("Fatima Z.", "FZ", "Bought as a gift and the recipient was thrilled. Great quality and very fair price.", true, 14),
        ("Lucas M.", "LM", "Does the job well. Not perfect but for this price point it's hard to beat.", false, 7),
    ]

    /// Five reviews deterministically selected from `reviewPool` using the product UUID as a seed, with dates and ratings derived from the product's rating.
    var mockReviews: [ProductReview] {
        let pool = ProductDetailView.reviewPool
        var indices: [Int] = []
        var current = UInt(bitPattern: product.id.hashValue)
        while indices.count < 5 {
            let idx = Int(current % UInt(pool.count))
            if !indices.contains(idx) { indices.append(idx) }
            current = current &* 1_664_525 &+ 1_013_904_223
        }
        let dates = ["May 12, 2026", "Apr 28, 2026", "Apr 15, 2026", "Mar 30, 2026", "Mar 14, 2026"]
        let rBase = min(5, max(1, Int(product.rating.rounded())))
        let ratings = [min(5, rBase), min(5, rBase), max(3, rBase - 1), min(5, rBase), max(3, rBase - 1)]
        return indices.enumerated().map { i, idx in
            let t = pool[idx]
            return ProductReview(id: "\(product.id.uuidString)-\(idx)",
                                 name: t.name, initials: t.initials, rating: ratings[i],
                                 date: dates[i], comment: t.comment,
                                 isVerified: t.isVerified, helpfulCount: t.helpfulCount)
        }
    }

    /// Star-to-fraction mapping (5 down to 1) derived from the product's overall rating bucket, used to render the histogram bars in `ratingOverview`.
    var ratingBreakdown: [(stars: Int, fraction: Double)] {
        let r = product.rating
        let fractions: [Double]
        switch r {
        case 4.5...: fractions = [0.65, 0.22, 0.07, 0.04, 0.02]
        case 4.0..<4.5: fractions = [0.45, 0.32, 0.13, 0.06, 0.04]
        case 3.5..<4.0: fractions = [0.28, 0.30, 0.22, 0.12, 0.08]
        default: fractions = [0.12, 0.18, 0.30, 0.24, 0.16]
        }
        return zip([5, 4, 3, 2, 1], fractions).map { (stars: $0, fraction: $1) }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    productImageSection
                    productInfoSection
                    tabSection
                    deliveryReturnsSection
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) { showUpsells.toggle() }
                    } label: {
                        HStack {
                            Text(showUpsells ? "Show Less" : "See Bundles & Related")
                                .font(AppTheme.Typography.label)
                                .foregroundColor(AppTheme.Colors.primary)
                            Spacer()
                            Image(systemName: showUpsells ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemBackground))
                    }
                    if showUpsells {
                        frequentlyBoughtSection
                        if !relatedProducts.isEmpty {
                            peopleAlsoBuySection
                        }
                    }
                    Spacer(minLength: 100)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(product.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                    .accessibilityLabel("Close")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        ShareLink(item: "Check out \(product.name) for $\(String(format: "%.2f", product.price)) on GeekCommerze!") {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.primary)
                        }
                        Button { toggleWishlist() } label: {
                            Image(systemName: isWishlisted ? "heart.fill" : "heart")
                                .foregroundColor(isWishlisted ? .red : .primary)
                        }
                        NavigationLink(destination: CartView()) {
                            CartBadgeIcon(count: cartItems.reduce(0) { $0 + $1.quantity })
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                addToCartBar
            }
            .sheet(item: $selectedRelatedProduct) { related in
                ProductDetailView(product: related)
            }
            .sheet(isPresented: $showWriteReview) {
                WriteReviewSheet(productName: product.name, toastManager: toastManager)
            }
            .sheet(isPresented: $showImageGallery) {
                ProductImageGalleryView(product: product)
            }
            .sheet(isPresented: $showSizeGuide) {
                SizeGuideSheet()
            }
            .onAppear {
                trackRecentlyViewed()
                if !colorVariants.isEmpty { selectedColorName = colorVariants[0].name }
                if !sizeVariants.isEmpty { selectedSize = sizeVariants[0] }
            }
        }
    }

    // MARK: - Image Section

    /// Hero image section with pinch-to-zoom gesture, discount badge overlay, and double-tap reset hint.
    private var productImageSection: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: product.imageName)
                .font(.system(size: 100))
                .foregroundColor(AppTheme.Colors.primary.opacity(0.6))
                .frame(maxWidth: .infinity)
                .frame(height: windowScreenHeight() < 700 ? 210 : 260)
                .background(
                    LinearGradient(colors: [AppTheme.Colors.primary.opacity(0.08), AppTheme.Colors.accent.opacity(0.05)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .scaleEffect(zoomScale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            zoomScale = max(1.0, min(3.0, lastZoomScale * value))
                        }
                        .onEnded { _ in
                            lastZoomScale = zoomScale
                            if zoomScale < 1.2 {
                                withAnimation(.spring()) {
                                    zoomScale = 1.0
                                    lastZoomScale = 1.0
                                }
                            }
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation(.spring()) {
                        if zoomScale > 1.0 {
                            zoomScale = 1.0
                            lastZoomScale = 1.0
                        } else {
                            zoomScale = 2.0
                            lastZoomScale = 2.0
                        }
                    }
                }
                .clipped()

            if let discount = product.discount {
                Text("-\(discount)% OFF")
                    .font(.caption).bold()
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .padding(16)
            }

            if zoomScale > 1.0 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("Double-tap to reset")
                            .font(.caption2)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(.black.opacity(0.5))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .padding(12)
                    }
                }
            }

            if zoomScale <= 1.0 {
                VStack {
                    Spacer()
                    HStack {
                        Button { showImageGallery = true } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.caption)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Open full-screen gallery")
                        .padding(12)
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Info Section

    /// Product metadata block: category pill, name, star rating, social proof counts, price with strikethrough, color/size selectors, stock status, quantity stepper, and tag chips.
    private var productInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(product.category.rawValue)
                .font(.caption)
                .foregroundColor(AppTheme.Colors.primary)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(AppTheme.Colors.primary.opacity(0.1))
                .clipShape(Capsule())

            Text(product.name)
                .font(.title2).bold()

            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(0..<5) { i in
                        let threshold = Double(i + 1)
                        Image(systemName: product.rating >= threshold ? "star.fill"
                                        : product.rating >= threshold - 0.5 ? "star.leadinghalf.filled"
                                        : "star")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
                Text("\(product.rating, specifier: "%.1f")")
                    .font(.subheadline).bold()
                Text("(\(product.reviewCount) reviews)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 16) {
                Label("\(socialProofViewing) viewing now", systemImage: "eye.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Label("\(socialProofSoldToday) sold today", systemImage: "flame.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("$\(product.price, specifier: "%.2f")")
                    .font(.title).bold()
                    .foregroundColor(AppTheme.Colors.primary)
                if let original = product.originalPrice {
                    Text("$\(original, specifier: "%.2f")")
                        .font(.headline)
                        .strikethrough()
                        .foregroundColor(.secondary)
                    if let discount = product.discount {
                        Text("Save \(discount)%")
                            .font(.caption).bold()
                            .foregroundColor(.green)
                    }
                }
            }

            // Color variants
            if !colorVariants.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Text("Color:").font(.subheadline).bold()
                        Text(selectedColorName).font(.subheadline).foregroundColor(.secondary)
                    }
                    HStack(spacing: 10) {
                        ForEach(colorVariants, id: \.name) { variant in
                            Circle()
                                .fill(variant.color)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle().stroke(
                                        selectedColorName == variant.name ? AppTheme.Colors.primary : Color(.systemGray4),
                                        lineWidth: selectedColorName == variant.name ? 2.5 : 1
                                    )
                                )
                                .padding(2)
                                .onTapGesture {
                                    selectedColorName = variant.name
                                    HapticFeedback.selection()
                                }
                        }
                    }
                }
            }

            // Size variants
            if !sizeVariants.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Size:").font(.subheadline).bold()
                        if product.category == .clothing {
                            Button("Guide") { showSizeGuide = true }
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(sizeVariants, id: \.self) { size in
                                Text(size)
                                    .font(.caption).bold()
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(selectedSize == size ? AppTheme.Colors.primary : Color(.systemGroupedBackground))
                                    .foregroundColor(selectedSize == size ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xs))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.Radius.xs)
                                            .stroke(selectedSize == size ? AppTheme.Colors.primary : Color(.systemGray4), lineWidth: 1)
                                    )
                                    .onTapGesture {
                                        selectedSize = size
                                        HapticFeedback.selection()
                                    }
                            }
                        }
                    }
                }
            }

            HStack {
                if product.isInStock && product.stock <= 5 {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Only \(product.stock) left in stock!")
                        .font(.subheadline).bold()
                        .foregroundColor(.orange)
                } else {
                    Image(systemName: product.isInStock ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(product.isInStock ? .green : .red)
                    Text(product.isInStock ? "In Stock (\(product.stock) available)" : "Out of Stock")
                        .font(.subheadline)
                        .foregroundColor(product.isInStock ? .green : .red)
                }
            }

            Divider()

            HStack(spacing: 16) {
                Text("Quantity")
                    .font(.subheadline).bold()
                Spacer()
                HStack(spacing: 0) {
                    Button {
                        if quantity > 1 { quantity -= 1 }
                    } label: {
                        Image(systemName: "minus")
                            .frame(width: 36, height: 36)
                            .background(Color(.systemBackground))
                    }
                    .accessibilityLabel("Decrease quantity")
                    Text("\(quantity)")
                        .frame(width: 40)
                        .font(.headline)
                        .accessibilityLabel("Quantity: \(quantity)")
                    Button {
                        if quantity < product.stock { quantity += 1 }
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 36, height: 36)
                            .background(Color(.systemBackground))
                    }
                    .accessibilityLabel("Increase quantity")
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
            }

            if !product.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(product.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color(.systemGroupedBackground))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
    }

    // MARK: - Tab Section

    /// Segmented picker switching between Description, Details (with price sparkline), and Reviews tabs.
    private var tabSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("Description").tag(0)
                Text("Details").tag(1)
                Text("Reviews").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(16)

            Group {
                switch selectedTab {
                case 0:
                    Text(product.description)
                        .font(.body)
                        .lineSpacing(4)
                        .foregroundColor(.secondary)
                        .padding(16)
                case 1:
                    VStack(spacing: 0) {
                        DetailRow(label: "Category", value: product.category.rawValue)
                        DetailRow(label: "Rating", value: String(format: "%.1f / 5.0", product.rating))
                        DetailRow(label: "Reviews", value: "\(product.reviewCount)")
                        DetailRow(label: "Availability", value: product.isInStock ? "In Stock" : "Out of Stock")
                        DetailRow(label: "Stock", value: "\(product.stock) units")
                        DetailRow(label: "SKU", value: String(product.id.uuidString.prefix(8).uppercased()))
                        priceSparkline
                    }
                default:
                    reviewsSection
                }
            }
            .background(Color(.systemBackground))
        }
        .padding(.top, 8)
    }

    // MARK: - Price Sparkline

    /// Swift Charts line-and-area chart showing the 30-day price history with high/low annotations, rendered inside the Details tab.
    @ViewBuilder
    private var priceSparkline: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("30-Day Price History")
                    .font(.subheadline).bold()
                Spacer()
                let minP = priceHistory.min(by: { $0.price < $1.price })?.price ?? product.price
                let maxP = priceHistory.max(by: { $0.price < $1.price })?.price ?? product.price
                VStack(alignment: .trailing, spacing: 2) {
                    Text("High: $\(String(format: "%.2f", maxP))")
                        .font(.caption2).foregroundColor(.secondary)
                    Text("Low: $\(String(format: "%.2f", minP))")
                        .font(.caption2).foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Chart(priceHistory, id: \.day) { point in
                LineMark(
                    x: .value("Day", point.day),
                    y: .value("Price", point.price)
                )
                .foregroundStyle(AppTheme.Colors.primary)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Day", point.day),
                    y: .value("Price", point.price)
                )
                .foregroundStyle(
                    LinearGradient(colors: [AppTheme.Colors.primary.opacity(0.25), .clear],
                                   startPoint: .top, endPoint: .bottom)
                )
                .interpolationMethod(.catmullRom)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let p = value.as(Double.self) {
                            Text("$\(Int(p))").font(.caption2)
                        }
                    }
                }
            }
            .chartXAxis(.hidden)
            .frame(height: 90)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        Divider().padding(.leading, 16)
    }

    // MARK: - Reviews Section

    /// Reviews tab content: write-review CTA button, rating overview histogram, and the list of five `ReviewCard` rows.
    private var reviewsSection: some View {
        let reviews = mockReviews
        return VStack(alignment: .leading, spacing: 16) {
            Button { showWriteReview = true } label: {
                Label("Write a Review", systemImage: "pencil.and.list.clipboard")
                    .font(.subheadline).bold()
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.Colors.primary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.chip))
            }
            .padding(.horizontal, 16)

            ratingOverview
            Divider().padding(.horizontal, 16)
            ForEach(reviews) { review in
                ReviewCard(review: review)
                if review.id != reviews.last?.id {
                    Divider().padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, 16)
    }

    /// Large numeric rating score on the left paired with a 5-row star-fraction histogram on the right.
    private var ratingOverview: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(spacing: 4) {
                Text("\(product.rating, specifier: "%.1f")")
                    .font(.system(size: 48, weight: .bold))
                HStack(spacing: 2) {
                    ForEach(0..<5) { i in
                        Image(systemName: i < Int(product.rating.rounded()) ? "star.fill" : "star")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                }
                Text("\(product.reviewCount) ratings")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 5) {
                ForEach(ratingBreakdown, id: \.stars) { item in
                    HStack(spacing: 8) {
                        Text("\(item.stars)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 10)
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(.systemGroupedBackground))
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.yellow)
                                    .frame(width: geo.size.width * item.fraction, height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Delivery & Returns

    /// Static card listing free delivery, express delivery, 30-day returns, and 2-year warranty policies as `DeliveryRow` entries.
    private var deliveryReturnsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Delivery & Returns")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.top, 16)

            VStack(spacing: 0) {
                DeliveryRow(icon: "shippingbox.fill", color: AppTheme.Colors.primary,
                            title: "Free Delivery",
                            subtitle: "On orders over $50. Estimated 3–5 business days.")
                Divider().padding(.leading, 52)
                DeliveryRow(icon: "bolt.fill", color: .orange,
                            title: "Express Delivery",
                            subtitle: "Get it in 1–2 days for $9.99 extra.")
                Divider().padding(.leading, 52)
                DeliveryRow(icon: "arrow.uturn.left.circle.fill", color: .green,
                            title: "30-Day Returns",
                            subtitle: "Changed your mind? Return within 30 days, no questions asked.")
                Divider().padding(.leading, 52)
                DeliveryRow(icon: "checkmark.shield.fill", color: .purple,
                            title: "2-Year Warranty",
                            subtitle: "Full manufacturer warranty included with every purchase.")
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Frequently Bought Together

    /// Horizontal scroll of the current product plus two companion picks, with a one-tap "Add Bundle" button showing the combined total.
    private var frequentlyBoughtSection: some View {
        let bundle = frequentlyBoughtTogether
        guard !bundle.isEmpty else { return AnyView(EmptyView()) }
        let bundleTotal = product.price + bundle.reduce(0) { $0 + $1.price }
        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                Text("Frequently Bought Together")
                    .font(.headline)
                    .padding(.horizontal, 16)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        miniProductCard(product, isMain: true)
                        ForEach(bundle) { p in
                            Image(systemName: "plus")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            miniProductCard(p, isMain: false)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bundle Total")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("$\(bundleTotal, specifier: "%.2f")")
                            .font(.headline).bold()
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                    Spacer()
                    Button {
                        cartStore.addProduct(product, context: modelContext)
                        bundle.forEach { cartStore.addProduct($0, context: modelContext) }
                        HapticFeedback.notification(.success)
                        toastManager.show("Bundle added to cart!", icon: "cart.badge.plus", color: AppTheme.Colors.primary)
                    } label: {
                        Text("Add Bundle")
                            .font(.subheadline).bold()
                            .padding(.horizontal, 18).padding(.vertical, 10)
                            .foregroundColor(.white)
                            .background {
                                RoundedRectangle(cornerRadius: AppTheme.Radius.chip)
                                    .fill(AppTheme.Brand.gradientH)
                            }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 8)
        )
    }

    /// Compact 72 pt square product thumbnail with name and price, used in the bundle row; the main product receives a highlighted border when `isMain` is true.
    @ViewBuilder
    private func miniProductCard(_ p: Product, isMain: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: p.imageName)
                .font(.title2)
                .foregroundColor(AppTheme.Colors.primary.opacity(0.75))
                .frame(width: 72, height: 72)
                .background(isMain ? AppTheme.Colors.primary.opacity(0.12) : AppTheme.Colors.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
                .overlay(
                    isMain ? RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .stroke(AppTheme.Colors.primary.opacity(0.4), lineWidth: 1.5) : nil
                )
            Text(p.name)
                .font(.caption2)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 72)
            Text("$\(p.price, specifier: "%.2f")")
                .font(.caption2).bold()
                .foregroundColor(AppTheme.Colors.primary)
        }
    }

    // MARK: - You May Also Like

    /// Horizontally scrollable row of up to 6 same-category `ProductCard` views that open a nested `ProductDetailView` on tap.
    private var peopleAlsoBuySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("You May Also Like")
                .font(.headline)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(relatedProducts) { related in
                        ProductCard(product: related)
                            .frame(width: 165)
                            .onTapGesture { selectedRelatedProduct = related }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Add to Cart Bar

    /// Sticky bottom bar containing the wishlist toggle button and either the add-to-cart button (in-stock) or the notify-me button (out-of-stock).
    private var addToCartBar: some View {
        HStack(spacing: 12) {
            Button { toggleWishlist() } label: {
                Image(systemName: isWishlisted ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundColor(isWishlisted ? .red : .secondary)
                    .frame(width: 48, height: 48)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
                    .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
            }
            .accessibilityLabel(isWishlisted ? "Remove from wishlist" : "Add to wishlist")

            if !product.isInStock {
                Button { notifyWhenAvailable() } label: {
                    HStack {
                        Image(systemName: notifyMeSet ? "bell.fill" : "bell.badge")
                        Text(notifyMeSet ? "You'll be notified!" : "Notify Me When Back in Stock")
                            .font(.subheadline).bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(notifyMeSet ? Color.green : Color.orange)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
                }
                .disabled(notifyMeSet)
                .animation(.easeInOut(duration: 0.2), value: notifyMeSet)
            } else {
                Button {
                    for _ in 0..<quantity {
                        cartStore.addProduct(product, context: modelContext)
                    }
                    HapticFeedback.notification(.success)
                    toastManager.show("\(quantity > 1 ? "\(quantity)x " : "")\(product.name) added to cart", icon: "cart.badge.plus", color: AppTheme.Colors.primary)
                    addedToCart = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        addedToCart = false
                    }
                } label: {
                    HStack {
                        Label(addedToCart ? "Added to Cart!" : "Add to Cart", systemImage: addedToCart ? "checkmark" : "cart.badge.plus")
                            .font(.headline)
                        Spacer()
                        Text("$\(product.price * Double(quantity), specifier: "%.2f")")
                            .font(.headline)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .foregroundColor(.white)
                    .background {
                        RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                            .fill(addedToCart ? AnyShapeStyle(Color.green) : AnyShapeStyle(AppTheme.Brand.gradientH))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: addedToCart)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }

    /// Adds or removes the product UUID from the `@AppStorage` wishlist string and fires a haptic and toast confirmation.
    private func toggleWishlist() {
        var ids = wishlistData.components(separatedBy: ",").filter { !$0.isEmpty }
        let uid = product.id.uuidString
        if ids.contains(uid) {
            ids.removeAll { $0 == uid }
            HapticFeedback.impact(.light)
            toastManager.show("Removed from wishlist", icon: "heart.slash", color: .secondary)
        } else {
            ids.append(uid)
            HapticFeedback.impact(.medium)
            toastManager.show("Added to wishlist", icon: "heart.fill", color: .red)
        }
        wishlistData = ids.joined(separator: ",")
    }

    /// Appends the current product UUID to the `@AppStorage` recently-viewed list, capping the list at 10 entries.
    private func trackRecentlyViewed() {
        var ids = recentlyViewedData.components(separatedBy: ",").filter { !$0.isEmpty }
        let idStr = product.id.uuidString
        ids.removeAll { $0 == idStr }
        ids.append(idStr)
        if ids.count > 10 { ids = Array(ids.suffix(10)) }
        recentlyViewedData = ids.joined(separator: ",")
    }

    /// Requests `UNUserNotificationCenter` permission and schedules a 30-second restock notification, then sets `notifyMeSet` to lock the button.
    private func notifyWhenAvailable() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Back in Stock!"
            content.body = "\(product.name) is now available. Grab yours before it sells out!"
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 30, repeats: false)
            let request = UNNotificationRequest(
                identifier: product.id.uuidString + "-restock",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)
        }
        notifyMeSet = true
        HapticFeedback.notification(.success)
        toastManager.show("We'll notify you when it's back!", icon: "bell.fill", color: .orange)
    }
}

// MARK: - Write Review Sheet

/// Modal form sheet for submitting a star rating and free-text review for a named product.
struct WriteReviewSheet: View {
    let productName: String
    let toastManager: ToastManager
    @Environment(\.dismiss) private var dismiss
    @State private var starRating = 0
    @State private var reviewText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Your Rating") {
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= starRating ? "star.fill" : "star")
                                .font(.title)
                                .foregroundColor(star <= starRating ? .yellow : Color(.systemGray4))
                                .onTapGesture {
                                    starRating = star
                                    HapticFeedback.selection()
                                }
                        }
                        Spacer()
                        if starRating > 0 {
                            Text(["", "Poor", "Fair", "Good", "Very Good", "Excellent"][starRating])
                                .font(.caption).bold()
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Your Review") {
                    TextField("Share your thoughts about \(productName)…", text: $reviewText, axis: .vertical)
                        .lineLimit(4...10)
                }

                Section {
                    Text("Reviews are public and help other shoppers make informed decisions.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Write a Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        HapticFeedback.notification(.success)
                        toastManager.show("Thanks for your review!", icon: "star.fill", color: .yellow)
                        dismiss()
                    }
                    .bold()
                    .disabled(starRating == 0 || reviewText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Review Card

/// Single review row showing avatar initials, reviewer name, verified badge, star rating, date, review body, and a helpful-vote toggle button.
struct ReviewCard: View {
    let review: ProductReview
    @State private var hasVotedHelpful = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(review.initials)
                    .font(.subheadline).bold()
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.Colors.primary.opacity(0.7))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(review.name)
                            .font(.subheadline).bold()
                        if review.isVerified {
                            Label("Verified Purchase", systemImage: "checkmark.seal.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                    HStack(spacing: 3) {
                        ForEach(0..<5) { i in
                            Image(systemName: i < review.rating ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                        Text("·")
                            .foregroundColor(.secondary)
                        Text(review.date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }

            Text(review.comment)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(3)

            HStack {
                Text("Helpful?")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Button {
                    hasVotedHelpful.toggle()
                } label: {
                    Label(
                        "\(review.helpfulCount + (hasVotedHelpful ? 1 : 0))",
                        systemImage: hasVotedHelpful ? "hand.thumbsup.fill" : "hand.thumbsup"
                    )
                    .font(.caption)
                    .foregroundColor(hasVotedHelpful ? AppTheme.Colors.primary : .secondary)
                }
                .accessibilityLabel(hasVotedHelpful ? "Marked as helpful" : "Mark as helpful")
                .animation(.easeInOut(duration: 0.15), value: hasVotedHelpful)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Delivery Row

/// Single policy row for the delivery & returns card, displaying a colored SF Symbol icon, a bold title, and a subtitle description.
struct DeliveryRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline).bold()
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Detail Row

/// Two-column label/value row with a bottom divider, used in the Details tab to display structured product metadata.
struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 110, alignment: .leading)
            Text(value)
                .bold()
            Spacer()
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        Divider().padding(.leading, 16)
    }
}

// MARK: - Size Guide Sheet

/// Half-height sheet presenting a clothing measurement table (XS–XXL) with chest, waist, and hips in inches.
/// Shown from ProductDetailView when the user taps "Guide" next to the Size selector on clothing products.
struct SizeGuideSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let sizes = ["XS", "S", "M", "L", "XL", "XXL"]
    private let chest = ["32–34", "34–36", "36–38", "38–40", "40–42", "42–44"]
    private let waist = ["24–26", "26–28", "28–30", "30–32", "32–34", "34–36"]
    private let hips  = ["34–36", "36–38", "38–40", "40–42", "42–44", "44–46"]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    measureRow("Size", chest: "Chest (in)", waist: "Waist (in)", hips: "Hips (in)", isHeader: true)
                    Divider()
                    ForEach(sizes.indices, id: \.self) { i in
                        measureRow(sizes[i], chest: chest[i], waist: waist[i], hips: hips[i], isHeader: false)
                        if i < sizes.count - 1 { Divider().padding(.leading, 16) }
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
                .padding(16)

                Text("Measurements are in inches. Measure yourself and compare to the chart for the best fit.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Size Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.bold()
                }
            }
        }
        .presentationDetents([.medium])
    }

    /// Single row in the size guide table; header row uses caption weight, data rows use subheadline.
    private func measureRow(_ size: String, chest: String, waist: String, hips: String, isHeader: Bool) -> some View {
        HStack {
            Text(size).frame(maxWidth: .infinity)
            Text(chest).frame(maxWidth: .infinity)
            Text(waist).frame(maxWidth: .infinity)
            Text(hips).frame(maxWidth: .infinity)
        }
        .font(isHeader ? .caption.bold() : .subheadline)
        .foregroundColor(isHeader ? .secondary : .primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// Reads screen height via the active UIWindowScene — avoids the deprecated UIScreen.main API.
private func windowScreenHeight() -> CGFloat {
    UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first?.screen.bounds.height ?? 812
}
