import Foundation

// MARK: - PromoResult
struct PromoResult {
    let discount:    Double
    let message:     String
    let isValid:     Bool
    let appliedCode: String?
}

// MARK: - PromoService
// Centralises all promo-code validation logic.
// Views call PromoService.apply(...) and bind the result to their state.

enum PromoService {

    static func apply(code: String, cartTotal: Double, shipping: Double) -> PromoResult {
        let normalised = code.trimmingCharacters(in: .whitespaces).uppercased()

        switch normalised {

        case AppConstants.PromoCodes.save10:
            let discount = cartTotal * 0.10
            return .init(
                discount:    discount,
                message:     "10% off applied! You save \(format(discount))",
                isValid:     true,
                appliedCode: normalised
            )

        case AppConstants.PromoCodes.save20:
            let discount = cartTotal * 0.20
            return .init(
                discount:    discount,
                message:     "20% off applied! You save \(format(discount))",
                isValid:     true,
                appliedCode: normalised
            )

        case AppConstants.PromoCodes.welcome5:
            let discount = min(5.0, cartTotal)
            return .init(
                discount:    discount,
                message:     "$5 off applied!",
                isValid:     true,
                appliedCode: normalised
            )

        case AppConstants.PromoCodes.freeShip:
            return .init(
                discount:    shipping,
                message:     shipping > 0 ? "Free shipping applied!" : "Shipping is already free.",
                isValid:     true,
                appliedCode: normalised
            )

        default:
            return .init(
                discount:    0,
                message:     "Invalid code. Try SAVE10, SAVE20, WELCOME5, or FREESHIP.",
                isValid:     false,
                appliedCode: nil
            )
        }
    }

    // MARK: Private helpers
    private static func format(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}
