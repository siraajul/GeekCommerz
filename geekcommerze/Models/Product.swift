import Foundation

enum ProductCategory: String, CaseIterable, Codable {
    case electronics = "Electronics"
    case clothing = "Clothing"
    case homeGarden = "Home & Garden"
    case sports = "Sports"
    case books = "Books"

    var icon: String {
        switch self {
        case .electronics: return "laptopcomputer"
        case .clothing: return "tshirt"
        case .homeGarden: return "house"
        case .sports: return "sportscourt"
        case .books: return "book"
        }
    }
}

struct Product: Identifiable {
    let id: UUID
    let name: String
    let description: String
    let price: Double
    let originalPrice: Double?
    let category: ProductCategory
    let imageName: String
    let rating: Double
    let reviewCount: Int
    let isFeatured: Bool
    let stock: Int
    let tags: [String]

    var discount: Int? {
        guard let original = originalPrice, original > price else { return nil }
        return Int(((original - price) / original) * 100)
    }

    var isInStock: Bool { stock > 0 }
}
