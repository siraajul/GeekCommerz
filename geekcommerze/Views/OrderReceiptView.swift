import SwiftUI

/// Detailed order receipt/invoice view accessible from OrderDetailView.
/// Shows a branded header, itemised list, pricing breakdown, delivery address, and a share button.
struct OrderReceiptView: View {
    let order: Order

    /// Short 8-char uppercase order ID used for display.
    private var orderId: String { String(order.id.uuidString.prefix(8)).uppercased() }

    // MARK: - Derived Pricing

    /// Sum of all item subtotals before shipping and discounts.
    private var subtotal: Double { order.items.reduce(0) { $0 + $1.subtotal } }

    /// Shipping cost: free on orders ≥ $50, otherwise $4.99.
    private var shipping: Double { subtotal >= 50 ? 0 : 4.99 }

    /// Discount amount derived from the difference between subtotal+shipping and the recorded order total.
    private var discount: Double { max(0, subtotal + shipping - order.total) }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                receiptHeader
                itemsCard
                pricingCard
                shippingCard
                footerView
            }
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Receipt")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }

    // MARK: - Header

    /// Branded gradient header with order ID, date, and status badge.
    private var receiptHeader: some View {
        VStack(spacing: 0) {
            ZStack {
                AppTheme.Brand.gradientH
                VStack(spacing: 6) {
                    Image(systemName: "bag.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                    Text("GeekCommerz")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("Order Confirmed")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.vertical, 28)
            }

            VStack(spacing: 10) {
                HStack {
                    Text("Order #\(orderId)")
                        .font(.headline)
                    Spacer()
                    StatusBadge(status: order.status)
                }
                HStack {
                    Text(order.date.formatted(date: .long, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Items

    /// Itemised list of ordered products with thumbnail, quantity, unit price, and subtotal.
    private var itemsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Items Ordered")
                .font(.headline)

            ForEach(Array(order.items.enumerated()), id: \.offset) { index, item in
                HStack(spacing: 12) {
                    Image(systemName: item.imageName)
                        .font(.title3)
                        .foregroundColor(AppTheme.Colors.primary.opacity(0.75))
                        .frame(width: 44, height: 44)
                        .background(AppTheme.Colors.imageSurface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.sm))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.productName)
                            .font(.subheadline)
                            .lineLimit(2)
                        Text("Qty: \(item.quantity) × $\(item.price, specifier: "%.2f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("$\(item.subtotal, specifier: "%.2f")")
                        .font(.subheadline.bold())
                }

                if index < order.items.count - 1 {
                    Divider().padding(.leading, 56)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        .padding(.horizontal, 16)
    }

    // MARK: - Pricing

    /// Pricing breakdown: subtotal, shipping, optional discount, and grand total.
    private var pricingCard: some View {
        VStack(spacing: 0) {
            pricingRow("Subtotal", value: String(format: "$%.2f", subtotal))
            Divider().padding(.leading, 16)
            pricingRow("Shipping", value: shipping == 0 ? "Free" : String(format: "$%.2f", shipping))
            if discount > 0 {
                Divider().padding(.leading, 16)
                pricingRow("Discount", value: String(format: "-$%.2f", discount), valueColor: AppTheme.Colors.success)
            }
            Divider()
            HStack {
                Text("Total Paid")
                    .font(.headline)
                Spacer()
                Text("$\(order.total, specifier: "%.2f")")
                    .font(.title3.bold())
                    .foregroundColor(AppTheme.Colors.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        .padding(.horizontal, 16)
    }

    /// Single labelled price row used inside pricingCard.
    private func pricingRow(_ label: String, value: String, valueColor: Color = .primary) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.subheadline).foregroundColor(valueColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Shipping

    /// Delivery address card showing the recipient name, address lines, and phone.
    private var shippingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Delivery Address", systemImage: "mappin.circle.fill")
                .font(.headline)
                .foregroundColor(AppTheme.Colors.primary)
            Text(order.shippingName).font(.subheadline).bold()
            Text(order.shippingAddress).font(.subheadline).foregroundColor(.secondary)
            Text(order.shippingCity).font(.subheadline).foregroundColor(.secondary)
            Label(order.shippingPhone, systemImage: "phone")
                .font(.subheadline).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        .padding(.horizontal, 16)
    }

    // MARK: - Footer

    /// Branded thank-you footer with support email and app version.
    private var footerView: some View {
        VStack(spacing: 6) {
            Text("Thank you for shopping with GeekCommerz!")
                .font(.subheadline.bold())
            Text("Questions? support@geekcommerz.com")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("GeekCommerz · v\(AppConstants.App.version)")
                .font(.caption2)
                .foregroundColor(Color(.tertiaryLabel))
        }
        .multilineTextAlignment(.center)
        .padding(.vertical, 24)
    }

    // MARK: - Share Text

    /// Plain-text receipt string shared via the system share sheet.
    private var shareText: String {
        var lines = ["GeekCommerz Receipt", "Order #\(orderId)",
                     order.date.formatted(date: .long, time: .shortened), ""]
        for item in order.items {
            lines.append("\(item.productName) ×\(item.quantity) — $\(String(format: "%.2f", item.subtotal))")
        }
        lines += ["", "Total: $\(String(format: "%.2f", order.total))",
                  "Delivered to: \(order.shippingName), \(order.shippingCity)"]
        return lines.joined(separator: "\n")
    }
}
