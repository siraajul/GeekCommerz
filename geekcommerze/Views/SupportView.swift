import SwiftUI

/// Help, FAQ, and contact screen. Navigated to from ProfileView's About section.
/// Covers shipping, returns, payments, loyalty, promo codes, and account questions.
struct SupportView: View {

    /// Currently expanded FAQ question ID; nil when all are collapsed.
    @State private var expandedFAQ: UUID? = nil

    // MARK: - Data

    private struct FAQItem: Identifiable {
        let id = UUID()
        let question: String
        let answer: String
    }

    private let faqs: [FAQItem] = [
        FAQItem(question: "How do I track my order?",
                answer: "Go to the Orders tab and tap your order. The status timeline shows real-time progress from processing through to delivery."),
        FAQItem(question: "Can I cancel or change my order?",
                answer: "Orders can be cancelled within 1 hour of placement by contacting support. After that window, you can request a return once the item is delivered."),
        FAQItem(question: "What is your return policy?",
                answer: "Returns are accepted within 30 days of delivery, free of charge. Go to Orders → Order Detail → Request Return to start the process."),
        FAQItem(question: "How long does shipping take?",
                answer: "Standard shipping is 3–5 business days. Express delivery (1–2 days) is available at checkout for $9.99. Orders over $50 ship free."),
        FAQItem(question: "What payment methods do you accept?",
                answer: "We accept credit/debit cards, Apple Pay, and PayPal. All transactions are secured with industry-standard TLS encryption."),
        FAQItem(question: "How does the loyalty program work?",
                answer: "You earn 10 points for every $1 spent. Reach 1,000 points to become a Gold member and unlock exclusive discounts and early access to sales."),
        FAQItem(question: "How do I use a promo code?",
                answer: "Enter your code in the Promo Code field on the Checkout screen before placing your order. Active codes: SAVE10, SAVE20, WELCOME5, FREESHIP."),
        FAQItem(question: "My item arrived damaged — what do I do?",
                answer: "Please email support@geekcommerz.com with your order number and a photo of the damage within 48 hours. We'll arrange a free replacement or refund immediately."),
        FAQItem(question: "Can I change my delivery address?",
                answer: "You can update or add addresses in Profile → Saved Addresses before checkout. Address changes on placed orders require contacting support."),
        FAQItem(question: "How do I delete my account?",
                answer: "Email support@geekcommerz.com from your registered address with the subject 'Delete Account'. We'll process the request within 7 business days."),
    ]

    // MARK: - Body

    var body: some View {
        List {
            faqSection
            contactSection
            aboutSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - FAQ Section

    /// Collapsible accordion of common customer questions.
    private var faqSection: some View {
        Section("Frequently Asked Questions") {
            ForEach(faqs) { item in
                faqRow(item)
            }
        }
    }

    /// Single expandable FAQ row. Tapping toggles the answer with an ease animation.
    @ViewBuilder
    private func faqRow(_ item: FAQItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedFAQ = expandedFAQ == item.id ? nil : item.id
                }
                HapticFeedback.selection()
            } label: {
                HStack {
                    Text(item.question)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: expandedFAQ == item.id ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expandedFAQ == item.id {
                Text(item.answer)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineSpacing(3)
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Contact Section

    /// Direct contact links for email and phone support with operating hours.
    private var contactSection: some View {
        Section("Contact Us") {
            Link(destination: URL(string: "mailto:support@geekcommerz.com")!) {
                Label("support@geekcommerz.com", systemImage: "envelope.fill")
                    .foregroundColor(AppTheme.Colors.primary)
            }
            Link(destination: URL(string: "tel:+18005551234")!) {
                Label("+1 (800) 555-1234", systemImage: "phone.fill")
                    .foregroundColor(AppTheme.Colors.primary)
            }
            Label("Mon–Fri, 9 AM – 6 PM EST", systemImage: "clock")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - About Section

    /// App version, privacy policy, and terms of service links.
    private var aboutSection: some View {
        Section("About GeekCommerz") {
            LabeledContent("Version", value: AppConstants.App.version)
            Link(destination: URL(string: AppConstants.App.privacyURL)!) {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
            }
            Link(destination: URL(string: AppConstants.App.termsURL)!) {
                Label("Terms of Service", systemImage: "doc.text.fill")
            }
        }
    }
}

#Preview {
    NavigationStack {
        SupportView()
    }
}
