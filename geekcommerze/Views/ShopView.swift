import SwiftUI
import SwiftData

enum SortOption: String, CaseIterable, Identifiable {
    case featured  = "Featured"
    case priceLow  = "Price: Low to High"
    case priceHigh = "Price: High to Low"
    case rating    = "Top Rated"
    case name      = "Name A–Z"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .featured:  return "star"
        case .priceLow:  return "arrow.up"
        case .priceHigh: return "arrow.down"
        case .rating:    return "star.fill"
        case .name:      return "textformat.abc"
        }
    }
}

struct ShopView: View {
    @Environment(ProductStore.self) private var productStore
    @Environment(CartStore.self) private var cartStore
    @State private var selectedProduct: Product? = nil
    @State private var searchText: String = ""
    @State private var selectedCategory: ProductCategory? = nil
    @State private var sortOption: SortOption = .featured
    @State private var showInStockOnly: Bool = false
    @State private var showDiscountOnly: Bool = false
    @State private var showSortFilter: Bool = false
    var initialCategory: ProductCategory? = nil

    var activeFilterCount: Int {
        (showInStockOnly ? 1 : 0) + (showDiscountOnly ? 1 : 0) + (sortOption != .featured ? 1 : 0)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                categoryFilter
                if activeFilterCount > 0 { activeFiltersChips }
                productGrid
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Shop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button { showSortFilter = true } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "slider.horizontal.3")
                                if activeFilterCount > 0 {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 8, y: -8)
                                }
                            }
                        }
                        NavigationLink(destination: CartView()) {
                            CartBadgeIcon(count: cartStore.itemCount)
                        }
                    }
                }
            }
            .sheet(item: $selectedProduct) { product in
                ProductDetailView(product: product)
            }
            .sheet(isPresented: $showSortFilter) {
                SortFilterSheet(
                    sortOption: $sortOption,
                    showInStockOnly: $showInStockOnly,
                    showDiscountOnly: $showDiscountOnly
                )
                .presentationDetents([.medium, .large])
            }
            .onAppear {
                if let cat = initialCategory {
                    selectedCategory = cat
                }
            }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search products...", text: $searchText)
                .autocorrectionDisabled()
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(ProductCategory.allCases, id: \.self) { cat in
                    FilterChip(title: cat.rawValue, isSelected: selectedCategory == cat) {
                        selectedCategory = selectedCategory == cat ? nil : cat
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private var activeFiltersChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if sortOption != .featured {
                    ActiveFilterChip(label: sortOption.rawValue) { sortOption = .featured }
                }
                if showInStockOnly {
                    ActiveFilterChip(label: "In Stock") { showInStockOnly = false }
                }
                if showDiscountOnly {
                    ActiveFilterChip(label: "Has Discount") { showDiscountOnly = false }
                }
                Button {
                    sortOption = .featured
                    showInStockOnly = false
                    showDiscountOnly = false
                } label: {
                    Text("Clear All")
                        .font(.caption).bold()
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }

    private var productGrid: some View {
        let base = productStore.filtered(search: searchText, category: selectedCategory)
        let inStockFiltered = showInStockOnly ? base.filter { $0.isInStock } : base
        let discountFiltered = showDiscountOnly ? inStockFiltered.filter { $0.discount != nil } : inStockFiltered
        let results: [Product]
        switch sortOption {
        case .featured:  results = discountFiltered
        case .priceLow:  results = discountFiltered.sorted { $0.price < $1.price }
        case .priceHigh: results = discountFiltered.sorted { $0.price > $1.price }
        case .rating:    results = discountFiltered.sorted { $0.rating > $1.rating }
        case .name:      results = discountFiltered.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        }
        return ScrollView {
            if results.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No products found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(results) { product in
                        ProductCard(product: product)
                            .onTapGesture { selectedProduct = product }
                    }
                }
                .padding(16)
            }
        }
        .refreshable {
            try? await Task.sleep(for: .milliseconds(600))
        }
    }
}

struct ActiveFilterChip: View {
    let label: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2).bold()
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.12))
        .foregroundColor(.blue)
        .clipShape(Capsule())
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.blue : Color(.systemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
    }
}

struct SortFilterSheet: View {
    @Binding var sortOption: SortOption
    @Binding var showInStockOnly: Bool
    @Binding var showDiscountOnly: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Sort By") {
                    ForEach(SortOption.allCases) { option in
                        HStack {
                            Label(option.rawValue, systemImage: option.icon)
                            Spacer()
                            if sortOption == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { sortOption = option }
                    }
                }
                Section("Filter") {
                    Toggle("In Stock Only", isOn: $showInStockOnly)
                    Toggle("Has Discount", isOn: $showDiscountOnly)
                }
                Section {
                    Button("Reset All", role: .destructive) {
                        sortOption = .featured
                        showInStockOnly = false
                        showDiscountOnly = false
                    }
                }
            }
            .navigationTitle("Sort & Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.bold()
                }
            }
        }
    }
}

struct ProductCard: View {
    let product: Product
    @Environment(ProductStore.self) private var productStore
    @Environment(CartStore.self) private var cartStore
    @Environment(ToastManager.self) private var toastManager
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppConstants.StorageKeys.wishlist) private var wishlistData: String = ""

    var isWishlisted: Bool {
        wishlistData.components(separatedBy: ",").contains(product.id.uuidString)
    }

    func toggleWishlist() {
        var ids = wishlistData.components(separatedBy: ",").filter { !$0.isEmpty }
        let uid = product.id.uuidString
        if ids.contains(uid) {
            ids.removeAll { $0 == uid }
            toastManager.show("Removed from wishlist", icon: "heart.slash", color: .secondary)
        } else {
            ids.append(uid)
            toastManager.show("Added to wishlist", icon: "heart.fill", color: .red)
        }
        wishlistData = ids.joined(separator: ",")
        HapticFeedback.impact(.medium)
    }

    private var productBadge: (label: String, color: Color)? {
        if product.isInStock && product.stock <= 5 {
            return ("LIMITED", .orange)
        } else if let d = product.discount, d >= 30 {
            return ("HOT DEAL", .red)
        } else if product.rating >= 4.6 {
            return ("BESTSELLER", .purple)
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: product.imageName)
                    .font(.system(size: 50))
                    .foregroundColor(.blue.opacity(0.7))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.blue.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if let discount = product.discount {
                    Text("-\(discount)%")
                        .font(.caption2).bold()
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .padding(6)
                }

                if let badge = productBadge {
                    VStack {
                        Spacer()
                        HStack {
                            Text(badge.label)
                                .font(.system(size: 8, weight: .bold))
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(badge.color)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .padding(6)
                            Spacer()
                        }
                    }
                }
            }
            .frame(height: 110)

            VStack(alignment: .leading, spacing: 0) {
                Text(product.name)
                    .font(.subheadline).bold()
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 38, alignment: .top)
                    .foregroundColor(.primary)
                    .padding(.top, 8)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    Text("\(product.rating, specifier: "%.1f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("(\(product.reviewCount))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 18)
                .padding(.top, 4)

                HStack(spacing: 4) {
                    Text("$\(product.price, specifier: "%.2f")")
                        .font(.subheadline).bold()
                        .foregroundColor(.blue)
                    if let original = product.originalPrice {
                        Text("$\(original, specifier: "%.2f")")
                            .font(.caption)
                            .strikethrough()
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 22)
                .padding(.top, 4)

                Spacer()

                Button {
                    cartStore.addProduct(product, context: modelContext)
                    HapticFeedback.notification(.success)
                    toastManager.show("\(product.name) added to cart", icon: "cart.badge.plus", color: .blue)
                } label: {
                    Label("Add to Cart", systemImage: "cart.badge.plus")
                        .font(.caption).bold()
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .background(product.isInStock ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(!product.isInStock)
                .padding(.bottom, 10)
            }
            .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity, idealHeight: 265)
        .frame(height: 265)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.07), radius: 4, y: 2)
        .contextMenu {
            Button {
                cartStore.addProduct(product, context: modelContext)
                HapticFeedback.notification(.success)
                toastManager.show("\(product.name) added to cart", icon: "cart.badge.plus", color: .blue)
            } label: {
                Label("Add to Cart", systemImage: "cart.badge.plus")
            }
            .disabled(!product.isInStock)

            Button {
                toggleWishlist()
            } label: {
                Label(isWishlisted ? "Remove from Wishlist" : "Add to Wishlist",
                      systemImage: isWishlisted ? "heart.slash" : "heart")
            }

            ShareLink(item: "Check out \(product.name) for $\(String(format: "%.2f", product.price)) on GeekCommerze!") {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        } preview: {
            VStack(spacing: 8) {
                Image(systemName: product.imageName)
                    .font(.system(size: 60))
                    .foregroundColor(.blue.opacity(0.7))
                    .frame(width: 160, height: 120)
                    .background(Color.blue.opacity(0.06))
                Text(product.name)
                    .font(.subheadline).bold()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                Text("$\(product.price, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.bottom, 8)
            }
            .frame(width: 200)
        }
    }
}

#Preview {
    ShopView()
        .environment(ProductStore())
        .environment(CartStore())
        .environment(ToastManager())
        .modelContainer(for: [CartItem.self, Order.self, OrderItem.self], inMemory: true)
}
