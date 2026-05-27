import SwiftUI

/// Return tracking screen shown from OrderDetailView when a return has been requested.
/// Simulates status progress based on days elapsed since the order date.
struct ReturnStatusView: View {
    let order: Order

    /// Short 8-char order ID for display.
    private var orderId: String { String(order.id.uuidString.prefix(8)).uppercased() }

    /// Days elapsed since the order date, used to simulate return pipeline progress.
    private var daysSinceOrder: Int {
        max(0, Int(Date().timeIntervalSince(order.date) / 86400))
    }

    private struct ReturnStep {
        let title: String
        let subtitle: String
        let icon: String
    }

    private let steps: [ReturnStep] = [
        ReturnStep(title: "Return Requested",  subtitle: "Your request has been received.",         icon: "arrow.uturn.left.circle.fill"),
        ReturnStep(title: "Under Review",       subtitle: "Our team is reviewing your request.",      icon: "magnifyingglass.circle.fill"),
        ReturnStep(title: "Approved",           subtitle: "Return approved — pickup scheduled.",      icon: "checkmark.circle.fill"),
        ReturnStep(title: "Item Picked Up",     subtitle: "Item collected by our courier.",           icon: "shippingbox.fill"),
        ReturnStep(title: "Refund Issued",      subtitle: "Refund processed in 5–7 business days.",  icon: "creditcard.fill"),
    ]

    /// Active step index derived from days elapsed (0 → just requested, 4 → refund issued).
    private var currentStep: Int {
        switch daysSinceOrder {
        case 0:      return 0
        case 1:      return 1
        case 2...3:  return 2
        case 4...6:  return 3
        default:     return 4
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                headerCard
                timelineCard
                estimateCard
                contactCard
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Return Status")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    /// Summary card showing the return order ID and request date.
    private var headerCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: "arrow.uturn.left.circle.fill")
                    .font(.title)
                    .foregroundColor(.orange)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Return #\(orderId)")
                    .font(.headline)
                Text("Requested \(order.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }

    // MARK: - Timeline

    /// Step-by-step return pipeline timeline, styled to match the order tracking timeline in OrderDetailView.
    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Return Progress")
                .font(.headline)

            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(index <= currentStep ? Color.orange : Color(.systemGray5))
                                .frame(width: 28, height: 28)
                            Image(systemName: index < currentStep ? "checkmark" : step.icon)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(index <= currentStep ? .white : Color(.systemGray3))
                        }
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(index < currentStep ? Color.orange : Color(.systemGray4))
                                .frame(width: 2, height: 36)
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.title)
                            .font(.subheadline)
                            .fontWeight(index <= currentStep ? .semibold : .regular)
                            .foregroundColor(index <= currentStep ? .primary : .secondary)
                        Text(step.subtitle)
                            .font(.caption)
                            .foregroundColor(index == currentStep ? .orange : .secondary)
                    }
                    .padding(.top, 4)
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }

    // MARK: - Estimate

    /// Refund timeline estimate card shown below the tracking steps.
    private var estimateCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.title2)
                .foregroundColor(AppTheme.Colors.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Estimated Refund")
                    .font(.subheadline.bold())
                Text("5–7 business days after item pickup")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }

    // MARK: - Contact

    /// Support contact card with email link pre-filled with the return reference number.
    private var contactCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Need Help?", systemImage: "questionmark.circle.fill")
                .font(.headline)
                .foregroundColor(AppTheme.Colors.primary)
            Link(destination: URL(string: "mailto:support@geekcommerz.com?subject=Return%20%23\(orderId)")!) {
                Label("Email our support team", systemImage: "envelope.fill")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.primary)
            }
            Text("Include return #\(orderId) in your message.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }
}
