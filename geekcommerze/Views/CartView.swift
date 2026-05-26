import SwiftUI
import SwiftData

struct CartView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(CartStore.self) private var cartStore
    @Environment(ToastManager.self) private var toastManager
    @Query private var cartItems: [CartItem]
    @State private var showCheckout = false
    @AppStorage(AppConstants.StorageKeys.wishlist) private var wishlistData: String = ""

    var total: Double { cartItems.reduce(0) { $0 + $1.subtotal } }
    var shipping: Double { CartStore.shipping(for: total) }
    var grandTotal: Double { total + shipping }

    var body: some View {
        NavigationStack {
            Group {
                if cartItems.isEmpty {
                    emptyCart
                } else {
                    cartContent
                }
            }
            .navigationTitle("My Cart")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCheckout) {
                CheckoutView()
            }
            .onAppear {
                cartStore.refresh(with: cartItems)
            }
        }
    }

    private var emptyCart: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart")
                .font(.system(size: 72))
                .foregroundColor(.secondary.opacity(0.5))
            Text("Your cart is empty")
                .font(.title3).bold()
            Text("Browse our products and add items to your cart.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            NavigationLink(destination: ShopView()) {
                Text("Start Shopping")
                    .font(AppTheme.Typography.button)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.Brand.gradientH)
                    }
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private var cartContent: some View {
        VStack(spacing: 0) {
            List {
                ForEach(cartItems) { item in
                    CartItemRow(item: item)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color(.systemBackground))
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                saveToWishlist(item)
                            } label: {
                                Label("Wishlist", systemImage: "heart")
                            }
                            .tint(.pink)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                cartStore.removeItem(item, context: modelContext)
                                HapticFeedback.impact(.medium)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                }
            }
            .listStyle(.plain)
            .background(Color(.systemGroupedBackground))

            orderSummary
        }
        .safeAreaInset(edge: .bottom) {
            checkoutButton
        }
    }

    private var orderSummary: some View {
        VStack(spacing: 10) {
            Divider()
            VStack(spacing: 8) {
                SummaryRow(label: "Subtotal", value: String(format: "$%.2f", total))
                SummaryRow(label: "Shipping", value: shipping == 0 ? "FREE" : String(format: "$%.2f", shipping))
                if shipping == 0 {
                    Text("Free shipping on orders over $50!")
                        .font(.caption)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                Divider()
                HStack {
                    Text("Total")
                        .font(AppTheme.Typography.sectionHeader)
                    Spacer()
                    Text("$\(grandTotal, specifier: "%.2f")")
                        .font(AppTheme.Typography.sectionHeader)
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
    }

    private func saveToWishlist(_ item: CartItem) {
        var ids = wishlistData.components(separatedBy: ",").filter { !$0.isEmpty }
        if !ids.contains(item.productId) {
            ids.append(item.productId)
            wishlistData = ids.joined(separator: ",")
            HapticFeedback.impact(.medium)
            toastManager.show("\(item.productName) saved to wishlist", icon: "heart.fill", color: .pink)
        } else {
            toastManager.show("Already in wishlist", icon: "heart.fill", color: .pink)
        }
    }

    private var checkoutButton: some View {
        Button { showCheckout = true } label: {
            HStack {
                Text("Proceed to Checkout")
                    .font(AppTheme.Typography.button)
                Spacer()
                Text("$\(grandTotal, specifier: "%.2f")")
                    .font(AppTheme.Typography.button)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppTheme.Brand.gradientH)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(.regularMaterial)
    }
}

struct CartItemRow: View {
    let item: CartItem
    @Environment(\.modelContext) private var modelContext
    @Environment(CartStore.self) private var cartStore
    @State private var incBounce = false
    @State private var decBounce = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.imageName)
                .font(.title)
                .foregroundColor(AppTheme.Brand.primary.opacity(0.75))
                .frame(width: 60, height: 60)
                .background(AppTheme.Colors.imageSurface)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.productName)
                    .font(.subheadline).bold()
                    .lineLimit(2)
                Text("$\(item.price, specifier: "%.2f") each")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("$\(item.subtotal, specifier: "%.2f")")
                    .font(.subheadline).bold()
                    .foregroundColor(AppTheme.Colors.primary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: item.quantity)
            }

            Spacer()

            // Stepper pill — fixed size so nothing clips the quantity number
            HStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.12)) { decBounce = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                        withAnimation { decBounce = false }
                    }
                    cartStore.updateQuantity(item, quantity: item.quantity - 1, context: modelContext)
                    HapticFeedback.selection()
                } label: {
                    Image(systemName: item.quantity > 1 ? "minus" : "trash")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(decBounce ? .white : (item.quantity > 1 ? AppTheme.Colors.primary : AppTheme.Colors.danger))
                        .frame(width: 30, height: 30)
                        .background(decBounce ? (item.quantity > 1 ? AppTheme.Colors.primary : AppTheme.Colors.danger) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .accessibilityLabel(item.quantity > 1 ? "Decrease quantity" : "Remove item")

                Text("\(item.quantity)")
                    .font(.subheadline).bold()
                    .frame(width: 32)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: item.quantity)

                Button {
                    withAnimation(.easeInOut(duration: 0.12)) { incBounce = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                        withAnimation { incBounce = false }
                    }
                    cartStore.updateQuantity(item, quantity: item.quantity + 1, context: modelContext)
                    HapticFeedback.selection()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(incBounce ? .white : AppTheme.Colors.primary)
                        .frame(width: 30, height: 30)
                        .background(incBounce ? AppTheme.Colors.primary : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .accessibilityLabel("Increase quantity")
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.vertical, 4)
    }
}

struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .bold()
        }
    }
}

#Preview {
    CartView()
        .environment(CartStore())
        .environment(ProductStore())
        .modelContainer(for: [CartItem.self, Order.self, OrderItem.self], inMemory: true)
}
