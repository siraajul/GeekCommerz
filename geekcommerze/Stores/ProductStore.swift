import Foundation
import Observation
import Supabase

@Observable
class ProductStore {
    var products: [Product] = []
    var isLoading = false
    var loadError: String? = nil

    // MARK: - Load

    func loadProducts() async {
        guard let client = SupabaseService.client else {
            // Offline mode — use bundled mock data
            products = ProductStore.mockProducts
            return
        }
        isLoading = true
        loadError = nil
        do {
            let fetched: [Product] = try await client
                .from("products")
                .select()
                .order("name")
                .execute()
                .value
            products = fetched.isEmpty ? ProductStore.mockProducts : fetched
        } catch {
            loadError = error.localizedDescription
            products = ProductStore.mockProducts   // fallback so UI is never empty
        }
        isLoading = false
    }

    // Search and category are UI state — kept local to ShopView, not here
    func filtered(search: String, category: ProductCategory?) -> [Product] {
        products.filter { product in
            let matchesCategory = category == nil || product.category == category
            let matchesSearch = search.isEmpty || product.name.lowercased().contains(search.lowercased())
            return matchesCategory && matchesSearch
        }
    }

    var featuredProducts: [Product] {
        products.filter { $0.isFeatured }
    }

    func products(for category: ProductCategory) -> [Product] {
        products.filter { $0.category == category }
    }

    func product(id: String) -> Product? {
        products.first { $0.id.uuidString == id }
    }

    static let mockProducts: [Product] = [
        // Electronics
        Product(id: UUID(), name: "Wireless Headphones Pro", description: "Premium noise-cancelling wireless headphones with 30-hour battery life. Experience studio-quality sound wherever you go with active noise cancellation and foldable design.", price: 149.99, originalPrice: 199.99, category: .electronics, imageName: "headphones", rating: 4.7, reviewCount: 312, isFeatured: true, stock: 25, tags: ["audio", "wireless", "noise-cancelling"]),
        Product(id: UUID(), name: "Smart Watch Series X", description: "Advanced fitness tracking smartwatch with ECG, blood oxygen monitoring, and 7-day battery. Stay connected and healthy with 50+ workout modes.", price: 299.99, originalPrice: 349.99, category: .electronics, imageName: "applewatch", rating: 4.8, reviewCount: 540, isFeatured: true, stock: 15, tags: ["wearable", "fitness", "smart"]),
        Product(id: UUID(), name: "Portable Bluetooth Speaker", description: "360-degree surround sound with waterproof IPX7 rating. Perfect for outdoor adventures with 20-hour playtime.", price: 79.99, originalPrice: nil, category: .electronics, imageName: "hifispeaker.fill", rating: 4.5, reviewCount: 198, isFeatured: false, stock: 40, tags: ["audio", "portable", "waterproof"]),
        Product(id: UUID(), name: "Mechanical Keyboard", description: "Tactile mechanical switches with RGB backlight. Designed for productivity and gaming with anti-ghosting technology.", price: 119.99, originalPrice: 139.99, category: .electronics, imageName: "keyboard", rating: 4.6, reviewCount: 275, isFeatured: false, stock: 30, tags: ["keyboard", "gaming", "rgb"]),
        Product(id: UUID(), name: "4K Webcam", description: "Crystal-clear 4K video with built-in ring light and noise-cancelling mic. Perfect for video calls and streaming.", price: 89.99, originalPrice: nil, category: .electronics, imageName: "camera", rating: 4.4, reviewCount: 145, isFeatured: false, stock: 20, tags: ["camera", "streaming", "video"]),

        // Clothing
        Product(id: UUID(), name: "Classic Cotton T-Shirt", description: "100% organic cotton, ultra-soft everyday tee. Pre-shrunk and available in a wide range of colors. Sustainably made.", price: 24.99, originalPrice: nil, category: .clothing, imageName: "tshirt", rating: 4.5, reviewCount: 890, isFeatured: true, stock: 100, tags: ["cotton", "casual", "organic"]),
        Product(id: UUID(), name: "Slim Fit Denim Jeans", description: "Premium stretch denim with modern slim fit. Comfortable for all-day wear with reinforced stitching at stress points.", price: 59.99, originalPrice: 74.99, category: .clothing, imageName: "rectangle.portrait", rating: 4.3, reviewCount: 420, isFeatured: false, stock: 60, tags: ["denim", "slim", "premium"]),
        Product(id: UUID(), name: "Running Jacket", description: "Lightweight windproof running jacket with reflective strips for night safety. Packable into its own pocket.", price: 89.99, originalPrice: nil, category: .clothing, imageName: "figure.run", rating: 4.6, reviewCount: 210, isFeatured: false, stock: 35, tags: ["running", "windproof", "reflective"]),
        Product(id: UUID(), name: "Casual Hoodie", description: "Cozy fleece-lined hoodie with kangaroo pocket and adjustable drawstring. Perfect for layering in any season.", price: 49.99, originalPrice: 64.99, category: .clothing, imageName: "person.fill", rating: 4.7, reviewCount: 650, isFeatured: true, stock: 80, tags: ["hoodie", "fleece", "casual"]),

        // Home & Garden
        Product(id: UUID(), name: "Bamboo Cutting Board Set", description: "Set of 3 eco-friendly bamboo cutting boards in different sizes. Naturally antimicrobial and gentle on knife blades.", price: 39.99, originalPrice: nil, category: .homeGarden, imageName: "rectangle.3.group", rating: 4.6, reviewCount: 320, isFeatured: false, stock: 50, tags: ["kitchen", "bamboo", "eco"]),
        Product(id: UUID(), name: "Scented Soy Candle Set", description: "Handcrafted set of 4 soy wax candles with calming lavender, vanilla, eucalyptus, and citrus scents. 45-hour burn time each.", price: 34.99, originalPrice: 44.99, category: .homeGarden, imageName: "flame", rating: 4.8, reviewCount: 415, isFeatured: true, stock: 45, tags: ["candle", "soy", "scented"]),
        Product(id: UUID(), name: "Indoor Planter Set", description: "Modern ceramic planter pots in geometric designs. Set of 3 with drainage holes and bamboo trays.", price: 44.99, originalPrice: nil, category: .homeGarden, imageName: "leaf", rating: 4.5, reviewCount: 180, isFeatured: false, stock: 30, tags: ["planter", "ceramic", "indoor"]),
        Product(id: UUID(), name: "Smart LED Desk Lamp", description: "Touch-controlled desk lamp with 5 color temperatures and 10 brightness levels. USB-C charging port included.", price: 54.99, originalPrice: 69.99, category: .homeGarden, imageName: "lamp.desk", rating: 4.7, reviewCount: 290, isFeatured: false, stock: 40, tags: ["lamp", "led", "smart"]),

        // Sports
        Product(id: UUID(), name: "Yoga Mat Premium", description: "Eco-friendly non-slip yoga mat with alignment lines. 6mm thick for extra cushioning on hard floors.", price: 49.99, originalPrice: nil, category: .sports, imageName: "figure.yoga", rating: 4.7, reviewCount: 560, isFeatured: false, stock: 70, tags: ["yoga", "eco", "non-slip"]),
        Product(id: UUID(), name: "Adjustable Dumbbell Set", description: "Space-saving adjustable dumbbells from 5-52.5 lbs. Quick-adjust dial system replaces 15 sets of weights.", price: 299.99, originalPrice: 349.99, category: .sports, imageName: "dumbbell", rating: 4.9, reviewCount: 840, isFeatured: true, stock: 10, tags: ["weights", "adjustable", "home-gym"]),
        Product(id: UUID(), name: "Resistance Bands Set", description: "Set of 5 resistance bands with handles, door anchor, and ankle straps. Ideal for full-body workouts at home.", price: 29.99, originalPrice: nil, category: .sports, imageName: "figure.strengthtraining.traditional", rating: 4.5, reviewCount: 380, isFeatured: false, stock: 90, tags: ["resistance", "bands", "workout"]),

        // Books
        Product(id: UUID(), name: "The Art of Minimalism", description: "A transformative guide to decluttering your space and mind. Practical exercises and real-life examples for modern living.", price: 18.99, originalPrice: nil, category: .books, imageName: "book", rating: 4.6, reviewCount: 720, isFeatured: false, stock: 200, tags: ["minimalism", "lifestyle", "self-help"]),
        Product(id: UUID(), name: "Swift Programming Mastery", description: "Comprehensive guide to building iOS apps with SwiftUI and Swift. Covers from basics to advanced async/await patterns.", price: 34.99, originalPrice: 44.99, category: .books, imageName: "swift", rating: 4.8, reviewCount: 310, isFeatured: true, stock: 150, tags: ["swift", "ios", "programming"]),
        Product(id: UUID(), name: "Mindful Cooking", description: "150 wholesome recipes with mindful eating techniques. Full-color photography and seasonal ingredient guides.", price: 27.99, originalPrice: nil, category: .books, imageName: "fork.knife", rating: 4.5, reviewCount: 480, isFeatured: false, stock: 120, tags: ["cooking", "mindful", "recipes"]),
    ]
}
