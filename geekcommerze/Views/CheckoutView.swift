import SwiftUI
import SwiftData
import LocalAuthentication

struct CheckoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(CartStore.self) private var cartStore
    @Environment(ToastManager.self) private var toastManager
    @Environment(NotificationStore.self) private var notifStore
    @Environment(\.dismiss) private var dismiss
    @Query private var cartItems: [CartItem]

    @State private var name = ""
    @State private var address = ""
    @State private var city = ""
    @State private var phone = ""
    @State private var selectedPayment = 0
    @State private var isPlacingOrder = false
    @State private var orderPlaced = false
    @State private var showConfetti = false
    @AppStorage(AppConstants.StorageKeys.loyaltyPoints) private var loyaltyPoints: Int = 0
    @AppStorage(AppConstants.StorageKeys.savedAddresses) private var savedAddressesData: String = ""
    @State private var showAddressPicker = false
    @State private var promoCode: String = ""
    @State private var appliedPromo: String? = nil
    @State private var promoDiscount: Double = 0
    @State private var promoMessage: String? = nil
    @State private var promoIsError: Bool = false

    var savedAddresses: [SavedAddress] {
        guard let data = savedAddressesData.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([SavedAddress].self, from: data)
        else { return [] }
        return decoded
    }

    let paymentMethods = ["Credit/Debit Card (Demo)", "Cash on Delivery", "Mobile Banking"]
    let paymentIcons = ["creditcard", "banknote", "iphone"]

    var total: Double { cartItems.reduce(0) { $0 + $1.subtotal } }
    var shipping: Double { CartStore.shipping(for: total) }
    var grandTotal: Double { max(0, total + shipping - promoDiscount) }

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !address.trimmingCharacters(in: .whitespaces).isEmpty &&
        !city.trimmingCharacters(in: .whitespaces).isEmpty &&
        !phone.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            if orderPlaced {
                orderSuccessView
            } else {
                checkoutForm
            }
        }
    }

    private var checkoutForm: some View {
        ScrollView {
            VStack(spacing: 16) {
                trustSection
                shippingSection
                promoSection
                paymentSection
                orderSummarySection
            }
            .padding(16)
            .padding(.bottom, 100)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").foregroundColor(.primary)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            placeOrderButton
        }
    }

    private var trustSection: some View {
        HStack(spacing: 0) {
            TrustBadge(icon: "lock.shield.fill", label: "Secure\nCheckout", color: .blue)
            Divider().frame(height: 40)
            TrustBadge(icon: "creditcard.fill", label: "Safe\nPayment", color: .green)
            Divider().frame(height: 40)
            TrustBadge(icon: "arrow.uturn.left.circle.fill", label: "30-Day\nReturn", color: .orange)
            Divider().frame(height: 40)
            TrustBadge(icon: "hand.raised.fill", label: "Buyer\nProtection", color: .purple)
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var shippingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Shipping Information", systemImage: "shippingbox")
                    .font(.headline)
                Spacer()
                if !savedAddresses.isEmpty {
                    Button {
                        showAddressPicker = true
                    } label: {
                        Label("Saved", systemImage: "mappin.and.ellipse")
                            .font(.caption).bold()
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }
                }
            }

            VStack(spacing: 10) {
                CheckoutField(label: "Full Name", placeholder: "John Doe", text: $name, icon: "person")
                CheckoutField(label: "Address", placeholder: "123 Main Street", text: $address, icon: "mappin")
                CheckoutField(label: "City", placeholder: "Dhaka", text: $city, icon: "building.2")
                CheckoutField(label: "Phone", placeholder: "+880 1234567890", text: $phone, icon: "phone", keyboardType: .phonePad)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .sheet(isPresented: $showAddressPicker) {
            SavedAddressPickerSheet(addresses: savedAddresses) { selected in
                name = selected.name
                address = selected.street
                city = selected.city
                phone = selected.phone
            }
        }
    }

    private var promoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Promo Code", systemImage: "tag")
                .font(.headline)

            HStack(spacing: 8) {
                TextField("Enter code (e.g. SAVE10)", text: $promoCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(Color(.systemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Button {
                    applyPromo()
                } label: {
                    Text(appliedPromo != nil ? "Applied ✓" : "Apply")
                        .font(.subheadline).bold()
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(appliedPromo != nil ? Color.green : Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(promoCode.trimmingCharacters(in: .whitespaces).isEmpty || appliedPromo != nil)
            }

            if let message = promoMessage {
                HStack(spacing: 6) {
                    Image(systemName: promoIsError ? "xmark.circle.fill" : "checkmark.circle.fill")
                    Text(message)
                        .font(.caption)
                    if !promoIsError {
                        Spacer()
                        Button("Remove") { removePromo() }
                            .font(.caption).bold()
                            .foregroundColor(.red)
                    }
                }
                .foregroundColor(promoIsError ? .red : .green)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Payment Method", systemImage: "creditcard")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(paymentMethods.indices, id: \.self) { index in
                    HStack {
                        Image(systemName: paymentIcons[index])
                            .foregroundColor(.blue)
                            .frame(width: 28)
                        Text(paymentMethods[index])
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: selectedPayment == index ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedPayment == index ? .blue : .secondary)
                    }
                    .padding(12)
                    .background(selectedPayment == index ? Color.blue.opacity(0.06) : Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(selectedPayment == index ? Color.blue : Color.clear, lineWidth: 1.5)
                    )
                    .onTapGesture { selectedPayment = index }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var orderSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Order Summary", systemImage: "list.bullet.rectangle")
                .font(.headline)

            ForEach(cartItems) { item in
                HStack {
                    Image(systemName: item.imageName)
                        .foregroundColor(.blue.opacity(0.7))
                        .frame(width: 36, height: 36)
                        .background(Color.blue.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.productName)
                            .font(.subheadline)
                            .lineLimit(1)
                        Text("Qty: \(item.quantity)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("$\(item.subtotal, specifier: "%.2f")")
                        .font(.subheadline).bold()
                }
            }

            Divider()

            SummaryRow(label: "Subtotal", value: String(format: "$%.2f", total))
            SummaryRow(label: "Shipping", value: shipping == 0 ? "FREE" : String(format: "$%.2f", shipping))
            if promoDiscount > 0, let code = appliedPromo {
                HStack {
                    Text("Discount (\(code))")
                        .font(.subheadline)
                        .foregroundColor(.green)
                    Spacer()
                    Text("-\(String(format: "$%.2f", promoDiscount))")
                        .font(.subheadline).bold()
                        .foregroundColor(.green)
                }
            }
            Divider()
            HStack {
                Text("Total")
                    .font(.headline).bold()
                Spacer()
                Text("$\(grandTotal, specifier: "%.2f")")
                    .font(.headline).bold()
                    .foregroundColor(.blue)
            }

            HStack(spacing: 6) {
                Image(systemName: "star.circle.fill")
                    .foregroundColor(.yellow)
                Text("You'll earn \(Int(grandTotal * AppConstants.Loyalty.pointsPerDollar)) loyalty points with this order")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var placeOrderButton: some View {
        VStack(spacing: 8) {
            Button {
                toastManager.show("Apple Pay not configured in demo", icon: "apple.logo", color: .primary)
                HapticFeedback.impact(.medium)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "apple.logo")
                        .font(.headline)
                    Text("Pay")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.primary)
                .foregroundColor(Color(uiColor: .systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 16)
            }
            .disabled(!isFormValid || isPlacingOrder)

            Button {
                authenticateAndPlaceOrder()
            } label: {
                HStack {
                    if isPlacingOrder {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "faceid")
                        Text("Place Order • $\(grandTotal, specifier: "%.2f")")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isFormValid ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .disabled(!isFormValid || isPlacingOrder)
        }
        .background(.regularMaterial)
    }

    private var orderSuccessView: some View {
        ZStack {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .symbolEffect(.bounce)

                VStack(spacing: 8) {
                    Text("Order Placed!")
                        .font(.title).bold()
                    Text("Thank you for your order. We'll send you a confirmation shortly.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Button { dismiss() } label: {
                    Text("Continue Shopping")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
            }

            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Order Confirmed")
        .onAppear {
            withAnimation { showConfetti = true }
            HapticFeedback.notification(.success)
        }
    }

    private func applyPromo() {
        let code = promoCode.trimmingCharacters(in: .whitespaces).uppercased()
        let currentShipping = CartStore.shipping(for: total)
        switch code {
        case AppConstants.PromoCodes.save10:
            promoDiscount = total * 0.10
            promoMessage = "10% off applied! You save \(String(format: "$%.2f", promoDiscount))"
            promoIsError = false; appliedPromo = code
        case AppConstants.PromoCodes.save20:
            promoDiscount = total * 0.20
            promoMessage = "20% off applied! You save \(String(format: "$%.2f", promoDiscount))"
            promoIsError = false; appliedPromo = code
        case AppConstants.PromoCodes.welcome5:
            promoDiscount = min(5.0, total)
            promoMessage = "$5 off applied!"
            promoIsError = false; appliedPromo = code
        case AppConstants.PromoCodes.freeShip:
            promoDiscount = currentShipping
            promoMessage = currentShipping > 0 ? "Free shipping applied!" : "Shipping is already free."
            promoIsError = false; appliedPromo = code
        default:
            promoDiscount = 0
            promoMessage = "Invalid code. Try SAVE10, SAVE20, WELCOME5, or FREESHIP."
            promoIsError = true; appliedPromo = nil
        }
    }

    private func removePromo() {
        promoCode = ""
        appliedPromo = nil
        promoDiscount = 0
        promoMessage = nil
        promoIsError = false
    }

    private func authenticateAndPlaceOrder() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Confirm your $\(String(format: "%.2f", grandTotal)) purchase"
            ) { success, _ in
                DispatchQueue.main.async {
                    if success { placeOrder() }
                }
            }
        } else {
            placeOrder()
        }
    }

    private func placeOrder() {
        isPlacingOrder = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            let order = Order(
                cartItems: cartItems,
                total: grandTotal,
                shippingName: name,
                shippingAddress: address,
                shippingCity: city,
                shippingPhone: phone
            )
            modelContext.insert(order)
            loyaltyPoints += Int(grandTotal * AppConstants.Loyalty.pointsPerDollar)
            cartStore.clearCart(context: modelContext)
            notifStore.add(
                title: "Order Confirmed! 🎉",
                body: "Your $\(String(format: "%.2f", grandTotal)) order has been placed. We'll notify you when it ships.",
                icon: "checkmark.circle.fill",
                colorName: "green",
                typeName: "order"
            )
            isPlacingOrder = false
            orderPlaced = true
        }
    }
}

struct TrustBadge: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SavedAddressPickerSheet: View {
    let addresses: [SavedAddress]
    let onSelect: (SavedAddress) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(addresses) { address in
                Button {
                    onSelect(address)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(address.label, systemImage: "mappin.circle.fill")
                            .font(.subheadline).bold()
                            .foregroundColor(.primary)
                        Text(address.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(address.street), \(address.city)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if !address.phone.isEmpty {
                            Text(address.phone)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Choose Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct CheckoutField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
            }
            .padding(12)
            .background(Color(.systemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
