import SwiftData
import Foundation

@Model
class CartItem {
    var productId: String
    var productName: String
    var price: Double
    var quantity: Int
    var imageName: String
    var category: String

    init(product: Product, quantity: Int = 1) {
        self.productId = product.id.uuidString
        self.productName = product.name
        self.price = product.price
        self.quantity = quantity
        self.imageName = product.imageName
        self.category = product.category.rawValue
    }

    var subtotal: Double { price * Double(quantity) }
}
