import Foundation
import SwiftData
import Observation

// MARK: - CartStore

/// Mutations-only cart store injected via `.environment()`.
/// Cart state (item count, contents) is queried reactively from SwiftData
/// via `@Query` in each view — no cached copy here, eliminating the dual
/// source-of-truth that previously caused badge desync.
@Observable
class CartStore {

    // MARK: - Shipping

    /// Minimum subtotal for free shipping.
    static let freeShippingThreshold: Double = AppConstants.Shipping.freeThreshold

    /// Flat shipping fee when below the free-shipping threshold.
    static let shippingCost: Double = AppConstants.Shipping.standardCost

    /// Returns the applicable shipping cost for the given subtotal.
    static func shipping(for subtotal: Double) -> Double {
        subtotal >= freeShippingThreshold ? 0 : shippingCost
    }

    // MARK: - Mutations

    /// Adds one unit of `product`, incrementing quantity if a line already exists.
    func addProduct(_ product: Product, context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<CartItem>())) ?? []
        if let match = existing.first(where: { $0.productId == product.id.uuidString }) {
            match.quantity += 1
        } else {
            context.insert(CartItem(product: product))
        }
    }

    /// Deletes the given cart line from SwiftData.
    func removeItem(_ item: CartItem, context: ModelContext) {
        context.delete(item)
    }

    /// Updates quantity of `item`, deleting the line when quantity reaches zero.
    func updateQuantity(_ item: CartItem, quantity: Int, context: ModelContext) {
        if quantity <= 0 {
            context.delete(item)
        } else {
            item.quantity = quantity
        }
    }

    /// Deletes every cart line — called after a successful order placement.
    func clearCart(context: ModelContext) {
        let items = (try? context.fetch(FetchDescriptor<CartItem>())) ?? []
        items.forEach { context.delete($0) }
    }

    /// Deletes all cart and order data — called on sign-out to remove user-specific local data.
    func clearAllUserData(context: ModelContext) {
        try? context.delete(model: CartItem.self)
        try? context.delete(model: Order.self)
        try? context.delete(model: OrderItem.self)
    }
}
