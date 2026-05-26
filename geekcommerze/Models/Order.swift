import SwiftData
import Foundation

enum OrderStatus: String, Codable {
    case pending = "Pending"
    case processing = "Processing"
    case shipped = "Shipped"
    case delivered = "Delivered"
    case cancelled = "Cancelled"

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .processing: return "gearshape"
        case .shipped: return "shippingbox"
        case .delivered: return "checkmark.circle"
        case .cancelled: return "xmark.circle"
        }
    }

    var color: String {
        switch self {
        case .pending: return "orange"
        case .processing: return "blue"
        case .shipped: return "purple"
        case .delivered: return "green"
        case .cancelled: return "red"
        }
    }
}

@Model
class OrderItem {
    var productId: String
    var productName: String
    var price: Double
    var quantity: Int
    var imageName: String
    var order: Order?

    init(from cartItem: CartItem) {
        self.productId = cartItem.productId
        self.productName = cartItem.productName
        self.price = cartItem.price
        self.quantity = cartItem.quantity
        self.imageName = cartItem.imageName
    }

    var subtotal: Double { price * Double(quantity) }
}

@Model
class Order {
    var id: UUID
    var date: Date
    var statusRaw: String
    var total: Double
    var shippingName: String
    var shippingAddress: String
    var shippingCity: String
    var shippingPhone: String
    var returnRequested: Bool
    @Relationship(deleteRule: .cascade) var items: [OrderItem]

    var status: OrderStatus {
        get { OrderStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    init(cartItems: [CartItem], total: Double, shippingName: String, shippingAddress: String, shippingCity: String, shippingPhone: String) {
        self.id = UUID()
        self.date = Date()
        self.statusRaw = OrderStatus.processing.rawValue
        self.total = total
        self.shippingName = shippingName
        self.shippingAddress = shippingAddress
        self.shippingCity = shippingCity
        self.shippingPhone = shippingPhone
        self.returnRequested = false
        self.items = cartItems.map { OrderItem(from: $0) }
    }
}
