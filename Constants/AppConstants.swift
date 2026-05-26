import Foundation

// MARK: - AppConstants
// Single source of truth for all app-wide constants.
// Avoids raw string literals scattered across the codebase and prevents typos.

enum AppConstants {

    // MARK: UserDefaults / AppStorage keys
    enum StorageKeys {
        static let wishlist             = "wishlist"
        static let recentlyViewed       = "recentlyViewed"
        static let recentSearches       = "recentSearches"
        static let savedAddresses       = "savedAddresses"
        static let loyaltyPoints        = "loyaltyPoints"
        static let profileName          = "profileName"
        static let profileEmail         = "profileEmail"
        static let notificationsEnabled = "notificationsEnabled"
        static let darkModeEnabled      = "darkModeEnabled"
        static let hasSeenOnboarding    = "hasSeenOnboarding"
        static let inAppNotifications   = "inAppNotifications"
    }

    // MARK: Loyalty program rules
    enum Loyalty {
        static let pointsPerDollar: Double = 10
        static let goldThreshold: Int      = 1_000
    }

    // MARK: Shipping rules
    enum Shipping {
        static let freeThreshold: Double = 50.0
        static let standardCost: Double  = 4.99
    }

    // MARK: Valid promo codes
    enum PromoCodes {
        static let save10   = "SAVE10"
        static let save20   = "SAVE20"
        static let welcome5 = "WELCOME5"
        static let freeShip = "FREESHIP"
    }

    // MARK: App-level metadata & external URLs
    enum App {
        static let name           = "GeekCommerz"
        static let version        = "1.0.0"
        static let privacyURL     = "https://example.com/privacy"
        static let termsURL       = "https://example.com/terms"
    }
}
