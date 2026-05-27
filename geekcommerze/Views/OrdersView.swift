import SwiftUI
import SwiftData

// MARK: - OrdersView

struct OrdersView: View {
    @Query(sort: \Order.date, order: .reverse) private var orders: [Order]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if orders.isEmpty {
                    emptyOrders
                } else {
                    orderList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("My Orders")
        }
    }

    // MARK: - Empty State

    /// Full-screen empty-state illustration shown when the SwiftData orders query returns no results.
    private var emptyOrders: some View {
        VStack(spacing: 20) {
            Image(systemName: "shippingbox")
                .font(.system(size: 72))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No orders yet")
                .font(.title3).bold()
            Text("Your orders will appear here once you've made a purchase.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            NavigationLink(destination: ShopView()) {
                Text("Start Shopping")
                    .font(AppTheme.Typography.button)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .foregroundColor(.white)
                    .background {
                        RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                            .fill(AppTheme.Brand.gradientH)
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Order List

    /// Scrollable list of past orders; each row is an OrderRow that navigates to OrderDetailView.
    private var orderList: some View {
        List {
            ForEach(orders) { order in
                NavigationLink(destination: OrderDetailView(order: order)) {
                    OrderRow(order: order)
                }
                .listRowBackground(Color(.systemBackground))
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - OrderRow

/// Summary row displayed in the OrdersView list. Shows order ID, date, item count, total, and a StatusBadge.
struct OrderRow: View {
    let order: Order

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Order #\(String(order.id.uuidString.prefix(8)).uppercased())")
                    .font(.subheadline).bold()
                Spacer()
                StatusBadge(status: order.status)
            }

            Text(order.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Text("\(order.items.count) item\(order.items.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("$\(order.total, specifier: "%.2f")")
                    .font(.subheadline).bold()
                    .foregroundColor(AppTheme.Colors.primary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - OrderDetailView

struct OrderDetailView: View {
    let order: Order
    @Environment(\.modelContext) private var modelContext
    @Environment(CartStore.self) private var cartStore
    @Environment(ProductStore.self) private var productStore
    @Environment(ToastManager.self) private var toastManager
    @State private var showReturns = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                trackingTimeline
                itemsCard
                shippingCard
                totalCard
                receiptCard
                reorderCard
                if order.status == .delivered {
                    if order.returnRequested == true {
                        returnRequestedBadge
                    } else {
                        returnRequestButton
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Order Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showReturns) {
            ReturnsSheet(
                orderId: String(order.id.uuidString.prefix(8)).uppercased(),
                toastManager: toastManager
            ) {
                order.returnRequested = true
            }
        }
    }

    // MARK: - Return Controls

    /// NavigationLink badge shown when a return is requested. Tapping opens ReturnStatusView to track the return pipeline.
    private var returnRequestedBadge: some View {
        NavigationLink(destination: ReturnStatusView(order: order)) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Return Requested")
                        .font(.headline)
                    Text("Tap to track your return")
                        .font(.caption)
                        .opacity(0.75)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .opacity(0.6)
            }
            .padding(16)
            .background(Color.green.opacity(0.1))
            .foregroundColor(.green)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.card).stroke(Color.green.opacity(0.3), lineWidth: 1))
        }
    }

    /// NavigationLink card that opens the full order receipt/invoice in OrderReceiptView.
    private var receiptCard: some View {
        NavigationLink(destination: OrderReceiptView(order: order)) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.title3)
                    .foregroundColor(AppTheme.Colors.primary)
                Text("View Receipt")
                    .font(AppTheme.Typography.button)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        }
    }

    /// Tappable button that sets showReturns to true, presenting ReturnsSheet. Visible only for delivered, non-returned orders.
    private var returnRequestButton: some View {
        Button { showReturns = true } label: {
            HStack {
                Image(systemName: "arrow.uturn.left.circle.fill")
                    .font(.title3)
                Text("Request Return")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.orange.opacity(0.7))
            }
            .padding(16)
            .background(Color.orange.opacity(0.1))
            .foregroundColor(.orange)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.orange.opacity(0.3), lineWidth: 1))
        }
    }

    // MARK: - Reorder Card

    /// Gradient action card that triggers reorder() to re-add all available order items to the cart.
    private var reorderCard: some View {
        Button {
            reorder()
        } label: {
            HStack {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.title3)
                Text("Order Again")
                    .font(AppTheme.Typography.button)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(16)
            .foregroundColor(.white)
            .background {
                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    .fill(AppTheme.Brand.gradientH)
            }
        }
    }

    // MARK: - Actions

    /// Adds each in-stock item from the order back to CartStore and fires a toast. Called by the reorderCard button.
    private func reorder() {
        var addedCount = 0
        for item in order.items {
            if let product = productStore.products.first(where: { $0.id.uuidString == item.productId }),
               product.isInStock {
                for _ in 0..<item.quantity {
                    cartStore.addProduct(product, context: modelContext)
                }
                addedCount += 1
            }
        }
        HapticFeedback.notification(.success)
        if addedCount > 0 {
            toastManager.show("\(addedCount) item\(addedCount > 1 ? "s" : "") added to cart", icon: "cart.badge.plus", color: AppTheme.Colors.primary)
        } else {
            toastManager.show("Items unavailable", icon: "exclamationmark.circle", color: .orange)
        }
    }

    // MARK: - Order Cards

    /// Step-by-step tracking timeline card showing order progress from Pending through Delivered, or a cancelled state.
    private var trackingTimeline: some View {
        let steps: [(status: OrderStatus, subtitle: String)] = [
            (.pending,    "Order received"),
            (.processing, "Being prepared"),
            (.shipped,    "Out for delivery"),
            (.delivered,  "Delivered to you")
        ]
        let currentIdx = steps.firstIndex(where: { $0.status == order.status }) ?? 0

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Order Status")
                    .font(.headline)
                Spacer()
                StatusBadge(status: order.status)
            }

            if order.status == .cancelled {
                HStack(spacing: 12) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Order Cancelled")
                            .font(.subheadline).bold()
                        Text("This order has been cancelled.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 14) {
                        VStack(spacing: 0) {
                            ZStack {
                                Circle()
                                    .fill(index <= currentIdx ? AppTheme.Colors.primary : Color(.systemGray5))
                                    .frame(width: 28, height: 28)
                                Image(systemName: index < currentIdx ? "checkmark" : step.status.icon)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(index <= currentIdx ? .white : Color(.systemGray3))
                            }
                            if index < steps.count - 1 {
                                Rectangle()
                                    .fill(index < currentIdx ? AppTheme.Colors.primary : Color(.systemGray4))
                                    .frame(width: 2, height: 36)
                            }
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.status.rawValue)
                                .font(.subheadline)
                                .fontWeight(index <= currentIdx ? .semibold : .regular)
                                .foregroundColor(index <= currentIdx ? .primary : .secondary)
                            Text(step.subtitle)
                                .font(.caption)
                                .foregroundColor(index == currentIdx ? AppTheme.Colors.primary : .secondary)
                        }
                        .padding(.top, 4)
                        Spacer()
                    }
                }
            }

            Text("Placed \(order.date.formatted(date: .long, time: .shortened))")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }

    /// Card listing each ordered item with its image icon, name, quantity, unit price, and line subtotal.
    private var itemsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Items Ordered")
                .font(.headline)
            ForEach(order.items) { item in
                HStack {
                    Image(systemName: item.imageName)
                        .foregroundColor(AppTheme.Colors.primary.opacity(0.75))
                        .frame(width: 40, height: 40)
                        .background(AppTheme.Colors.imageSurface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.sm))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.productName)
                            .font(.subheadline)
                        Text("Qty: \(item.quantity) × $\(item.price, specifier: "%.2f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("$\(item.subtotal, specifier: "%.2f")")
                        .font(.subheadline).bold()
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }

    /// Card displaying the shipping name, street address, city, and contact phone number for the order.
    private var shippingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Shipping Address", systemImage: "mappin.circle")
                .font(.headline)
            Text(order.shippingName)
                .font(.subheadline).bold()
            Text(order.shippingAddress)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(order.shippingCity)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Label(order.shippingPhone, systemImage: "phone")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }

    /// Single-row card showing the order grand total in the brand primary color.
    private var totalCard: some View {
        HStack {
            Text("Total Paid")
                .font(.headline)
            Spacer()
            Text("$\(order.total, specifier: "%.2f")")
                .font(.title3).bold()
                .foregroundColor(AppTheme.Colors.primary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }
}

// MARK: - ReturnsSheet

/// Bottom sheet form for submitting a return request. Sets order.returnRequested via onSubmit and fires a toast through ToastManager.
struct ReturnsSheet: View {
    let orderId: String
    let toastManager: ToastManager
    let onSubmit: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason = 0
    @State private var description = ""
    @State private var submitted = false

    let reasons = [
        "Defective / Damaged",
        "Wrong item received",
        "Changed my mind",
        "Item not as described",
        "Missing parts / accessories",
        "Other"
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            if submitted {
                VStack(spacing: 24) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.green)
                        .symbolEffect(.bounce)
                    Text("Return Requested")
                        .font(.title2).bold()
                    Text("We've received your return request for order #\(orderId). You'll hear from us within 24 hours.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button { dismiss() } label: {
                        Text("Done")
                            .font(AppTheme.Typography.button)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundColor(.white)
                            .background {
                                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                                    .fill(AppTheme.Brand.gradientH)
                            }
                    }
                    .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("Return Submitted")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                Form {
                    Section("Order #\(orderId)") {
                        Text("Select the reason for your return request.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Section("Return Reason") {
                        ForEach(reasons.indices, id: \.self) { i in
                            HStack {
                                Text(reasons[i])
                                    .font(.subheadline)
                                Spacer()
                                if selectedReason == i {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppTheme.Colors.primary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { selectedReason = i }
                        }
                    }

                    Section("Additional Details (Optional)") {
                        TextField("Describe the issue…", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                    }

                    Section {
                        Text("Returns are free within 30 days of delivery. Refunds are processed in 5–7 business days.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .navigationTitle("Request Return")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Submit") {
                            HapticFeedback.notification(.success)
                            toastManager.show("Return request submitted", icon: "arrow.uturn.left.circle", color: .orange)
                            onSubmit()
                            submitted = true
                        }
                        .bold()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - StatusBadge

/// Colored capsule badge used across OrderRow and OrderDetailView to indicate the current OrderStatus.
struct StatusBadge: View {
    let status: OrderStatus

    /// Maps each OrderStatus to its corresponding display color.
    var color: Color {
        switch status {
        case .pending:    return .orange
        case .processing: return AppTheme.Colors.primary
        case .shipped:    return AppTheme.Colors.accent
        case .delivered:  return AppTheme.Colors.success
        case .cancelled:  return AppTheme.Colors.danger
        }
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption2)
            Text(status.rawValue)
                .font(.caption).bold()
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(color.opacity(0.12))
        .foregroundColor(color)
        .clipShape(Capsule())
    }
}
