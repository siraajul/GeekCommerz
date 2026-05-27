import CryptoKit
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
// Codes are never stored as plaintext — validation compares SHA-256 hashes only.
// Views call PromoService.apply(...) and bind the result to their state.

enum PromoService {

    // SHA-256 hashes of the valid codes (codes never appear as plaintext in the binary)
    private static let h10   = "6f862afc1e2aa88c5bfc0e772b58a38840e49f081a7a7b26dab3b6efbcc72de7"
    private static let h20   = "4373f458281cefac011a8d440a83c3ddf02288b2c466205c2731bb452f9c4fcb"
    private static let hW5   = "2e8d6035d09c520891c8b018695a31f8ec903d0a972a823a57050f2a05d5b7e7"
    private static let hFree = "11d86782ada021038079e7beb627a16842256f0865c3dfd5d7096c05b12ff2b1"

    static func apply(code: String, cartTotal: Double, shipping: Double) -> PromoResult {
        let normalised = code.trimmingCharacters(in: .whitespaces).uppercased()
        let hashed = sha256(normalised)

        switch hashed {

        case h10:
            let discount = cartTotal * 0.10
            return .init(
                discount:    discount,
                message:     "10% off applied! You save \(format(discount))",
                isValid:     true,
                appliedCode: normalised
            )

        case h20:
            let discount = cartTotal * 0.20
            return .init(
                discount:    discount,
                message:     "20% off applied! You save \(format(discount))",
                isValid:     true,
                appliedCode: normalised
            )

        case hW5:
            let discount = min(5.0, cartTotal)
            return .init(
                discount:    discount,
                message:     "$5 off applied!",
                isValid:     true,
                appliedCode: normalised
            )

        case hFree:
            return .init(
                discount:    shipping,
                message:     shipping > 0 ? "Free shipping applied!" : "Shipping is already free.",
                isValid:     true,
                appliedCode: normalised
            )

        default:
            return .init(
                discount:    0,
                message:     "Invalid promo code.",
                isValid:     false,
                appliedCode: nil
            )
        }
    }

    // MARK: Private helpers

    private static func sha256(_ string: String) -> String {
        SHA256.hash(data: Data(string.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private static func format(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}
