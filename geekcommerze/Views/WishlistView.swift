import SwiftUI
import SwiftData

struct WishlistView: View {
    @AppStorage(AppConstants.StorageKeys.wishlist) private var wishlistData: String = ""
    @Environment(ProductStore.self) private var productStore
    @Environment(CartStore.self) private var cartStore
    @Environment(\.modelContext) private var modelContext
    @State private var selectedProduct: Product? = nil

    var wishlistedProducts: [Product] {
        let ids = wishlistData.components(separatedBy: ",").filter { !$0.isEmpty }
        return productStore.products.filter { ids.contains($0.id.uuidString) }
    }

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
                        .padding(6)
                    }
                    .transition(.scale(scale: 0.75).combined(with: .opacity))
                }
            }
            .padding(16)
            .animation(.spring(response: 0.38, dampingFraction: 0.78), value: wishlistedProducts.count)
        }
    }

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
    }
    .modelContainer(for: [CartItem.self, Order.self, OrderItem.self], inMemory: true)
}
