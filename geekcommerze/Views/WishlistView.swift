import SwiftUI
import SwiftData

struct WishlistView: View {
    @AppStorage(AppConstants.StorageKeys.wishlist) private var wishlistData: String = ""
    @Environment(ProductStore.self) private var productStore
    @Environment(CartStore.self) private var cartStore
    @Environment(\.modelContext) private var modelContext
    @State private var selectedProduct: Product? = nil

    // MARK: - Computed Properties

    /// Filters ProductStore to only the products whose UUIDs appear in the @AppStorage wishlist string; drives WishlistView's grid.
    var wishlistedProducts: [Product] {
        let ids = wishlistData.components(separatedBy: ",").filter { !$0.isEmpty }
        return productStore.products.filter { ids.contains($0.id.uuidString) }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if wishlistedProducts.isEmpty {
                emptyWishlist
            } else {
                wishlistGrid
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Wishlist")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedProduct) { product in
            ProductDetailView(product: product)
        }
    }

    // MARK: - Empty State

    /// Placeholder shown in WishlistView when no products are saved; includes a CTA that navigates to ShopView.
    private var emptyWishlist: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))
            Text("Your wishlist is empty")
                .font(.title3).bold()
            Text("Tap the heart icon on any product to save it here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            NavigationLink(destination: ShopView()) {
                Text("Browse Products")
                    .font(.headline)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Wishlist Grid

    /// Two-column lazy grid of ProductCard tiles in WishlistView; each card has an overlaid remove button.
    private var wishlistGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(wishlistedProducts) { product in
                    ZStack(alignment: .topTrailing) {
                        ProductCard(product: product)
                            .onTapGesture { selectedProduct = product }

                        // Remove from wishlist button
                        Button {
                            removeFromWishlist(product)
                        } label: {
                            Image(systemName: "heart.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Remove from wishlist")
                        .padding(6)
                    }
                    .transition(.scale(scale: 0.75).combined(with: .opacity))
                }
            }
            .padding(16)
            .animation(.spring(response: 0.38, dampingFraction: 0.78), value: wishlistedProducts.count)
        }
    }

    // MARK: - Actions

    /// Removes a product's UUID from the @AppStorage wishlist string; triggered by the heart button overlay in WishlistView.
    private func removeFromWishlist(_ product: Product) {
        HapticFeedback.impact(.medium)
        var ids = wishlistData.components(separatedBy: ",").filter { !$0.isEmpty }
        ids.removeAll { $0 == product.id.uuidString }
        wishlistData = ids.joined(separator: ",")
    }
}

#Preview {
    NavigationStack {
        WishlistView()
            .environment(ProductStore())
            .environment(CartStore())
            .environment(ToastManager())
            .environment(TabRouter())
            .environment(CartAnimationManager())
            .environment(NotificationStore())
            .environment(AuthStore())
    }
    .modelContainer(for: [CartItem.self, Order.self, OrderItem.self], inMemory: true)
}
