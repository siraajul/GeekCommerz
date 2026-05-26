import SwiftUI
import SwiftData

struct OrdersView: View {
    @Query(sort: \Order.date, order: .reverse) private var orders: [Order]

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
                    .font(.headline)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

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

struct OrderRow: View {
    let order: Order

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
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

struct OrderDetailView: View {
    let order: Order
    @Environment(\.modelContext) private var modelContext
    @Environment(CartStore.self) private var cartStore
    @Environment(ProductStore.self) private var productStore
    @Environment(ToastManager.self) private var toastManager
    @State private var showReturns = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                trackingTimeline
                itemsCard
                shippingCard
                totalCard
                reorderCard
                if order.status == .delivered {
                    if order.returnRequested {
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

    private var returnRequestedBadge: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text("Return Requested")
                    .font(.headline)
                Text("We'll contact you within 24 hours.")
                    .font(.caption)
                    .opacity(0.75)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.green.opacity(0.1))
        .foregroundColor(.green)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(0.3), lineWidth: 1))
    }

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
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.orange.opacity(0.3), lineWidth: 1))
        }
    }

    private var reorderCard: some View {
        Button {
            reorder()
        } label: {
            HStack {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.title3)
                Text("Order Again")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(16)
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

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
            toastManager.show("\(addedCount) item\(addedCount > 1 ? "s" : "") added to cart", icon: "cart.badge.plus", color: .blue)
        } else {
            toastManager.show("Items unavailable", icon: "exclamationmark.circle", color: .orange)
        }
    }

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
                                    .fill(index <= currentIdx ? Color.blue : Color(.systemGray5))
                                    .frame(width: 28, height: 28)
                                Image(systemName: index < currentIdx ? "checkmark" : step.status.icon)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(index <= currentIdx ? .white : Color(.systemGray3))
                            }
                            if index < steps.count - 1 {
                                Rectangle()
                                    .fill(index < currentIdx ? Color.blue : Color(.systemGray4))
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
                                .foregroundColor(index == currentIdx ? .blue : .secondary)
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
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var itemsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Items Ordered")
                .font(.headline)
            ForEach(order.items) { item in
                HStack {
                    Image(systemName: item.imageName)
                        .foregroundColor(.blue.opacity(0.7))
                        .frame(width: 40, height: 40)
                        .background(Color.blue.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
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
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

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
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var totalCard: some View {
        HStack {
            Text("Total Paid")
                .font(.headline)
            Spacer()
            Text("$\(order.total, specifier: "%.2f")")
                .font(.title3).bold()
                .foregroundColor(.blue)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

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
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
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
                                        .foregroundColor(.blue)
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

struct StatusBadge: View {
    let status: OrderStatus

    var color: Color {
        switch status {
        case .pending: return .orange
        case .processing: return .blue
        case .shipped: return .purple
        case .delivered: return .green
        case .cancelled: return .red
        }
    }

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
