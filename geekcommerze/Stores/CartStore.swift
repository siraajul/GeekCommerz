import Foundation
import SwiftData
import Observation

@Observable
class CartStore {
    var itemCount: Int = 0

    // Single source of truth for shipping thresholds used by CartView and CheckoutView
    static let freeShippingThreshold: Double = AppConstants.Shipping.freeThreshold
    static let shippingCost: Double          = AppConstants.Shipping.standardCost

    static func shipping(for subtotal: Double) -> Double {
        subtotal >= freeShippingThreshold ? 0 : shippingCost
    }

    func refresh(with items: [CartItem]) {
        itemCount = items.reduce(0) { $0 + $1.quantity }
    }

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

    func removeItem(_ item: CartItem, context: ModelContext) {
        context.delete(item)
        refreshFromContext(context)
    }

    func updateQuantity(_ item: CartItem, quantity: Int, context: ModelContext) {
        if quantity <= 0 {
            context.delete(item)
        } else {
            item.quantity = quantity
        }
        refreshFromContext(context)
    }

    func clearCart(context: ModelContext) {
        let descriptor = FetchDescriptor<CartItem>()
        let items = (try? context.fetch(descriptor)) ?? []
        items.forEach { context.delete($0) }
        refreshFromContext(context)
    }

    private func refreshFromContext(_ context: ModelContext) {
        let descriptor = FetchDescriptor<CartItem>()
        let items = (try? context.fetch(descriptor)) ?? []
        refresh(with: items)
    }
}
