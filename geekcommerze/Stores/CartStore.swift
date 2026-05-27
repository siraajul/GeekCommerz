import Foundation
import SwiftData
import Observation

/// App-wide `@Observable` cart store injected via `.environment()`. Manages the in-memory item count
/// synced with SwiftData `CartItem` records. Observed by CartView, ProductDetailView, CheckoutView,
/// ShopView (long-press add), HomeView, and CartBadgeIcon.
@Observable
class CartStore {

    // MARK: - Properties

    /// Running total of individual units across all cart lines. Drives the badge count in CartBadgeIcon and TabBar.
    var itemCount: Int = 0

    // MARK: - Computed

    /// Minimum subtotal required for free shipping. Sourced from `AppConstants.Shipping` and used by CartView and CheckoutView.
    static let freeShippingThreshold: Double = AppConstants.Shipping.freeThreshold

    /// Flat shipping fee applied when the subtotal is below `freeShippingThreshold`. Displayed in CartView and CheckoutView order summary.
    static let shippingCost: Double          = AppConstants.Shipping.standardCost

    // MARK: - Actions

    /// Returns the applicable shipping cost for the given subtotal — zero when free-shipping threshold is met, otherwise `shippingCost`. Called by CartView and CheckoutView to build the order total.
    static func shipping(for subtotal: Double) -> Double {
        subtotal >= freeShippingThreshold ? 0 : shippingCost
    }

    /// Recalculates `itemCount` from the provided array of `CartItem` records. Called after every SwiftData mutation to keep the badge in sync.
    func refresh(with items: [CartItem]) {
        itemCount = items.reduce(0) { $0 + $1.quantity }
    }

    /// Adds one unit of `product` to the SwiftData store, incrementing quantity if a matching `CartItem` already exists. Called from ProductDetailView and ShopView long-press. Refreshes `itemCount` when done.
    func addProduct(_ product: Product, context: ModelContext) {
        let descriptor = FetchDescriptor<CartItem>()
        let existing = (try? context.fetch(descriptor)) ?? []
        if let match = existing.first(where: { $0.productId == product.id.uuidString }) {
            match.quantity += 1
        } else {
            context.insert(CartItem(product: product))
        }
        refreshFromContext(context)
    }

    /// Deletes the given `CartItem` from SwiftData and refreshes `itemCount`. Called from CartView swipe-to-delete and the remove button in the cart row.
    func removeItem(_ item: CartItem, context: ModelContext) {
        context.delete(item)
        refreshFromContext(context)
    }

    /// Sets the quantity of `item` to `quantity`, or deletes it when `quantity` drops to zero or below. Called from CartView stepper controls. Refreshes `itemCount` when done.
    func updateQuantity(_ item: CartItem, quantity: Int, context: ModelContext) {
        if quantity <= 0 {
            context.delete(item)
        } else {
            item.quantity = quantity
        }
        refreshFromContext(context)
    }

    /// Deletes every `CartItem` from SwiftData and resets `itemCount` to zero. Called from CheckoutView after a successful order placement.
    func clearCart(context: ModelContext) {
        let descriptor = FetchDescriptor<CartItem>()
        let items = (try? context.fetch(descriptor)) ?? []
        items.forEach { context.delete($0) }
        refreshFromContext(context)
    }

    /// Fetches all current `CartItem` records from the given context and delegates to `refresh(with:)`. Private helper used internally after every mutation.
    private func refreshFromContext(_ context: ModelContext) {
        let descriptor = FetchDescriptor<CartItem>()
        let items = (try? context.fetch(descriptor)) ?? []
        refresh(with: items)
    }
}
