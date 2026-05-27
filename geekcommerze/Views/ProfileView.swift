import SwiftUI
import SwiftData

/// Codable address model stored in AppStorage as JSON. Used by ProfileView and AddAddressSheet.
struct SavedAddress: Codable, Identifiable {
    var id: UUID = UUID()
    var label: String
    var name: String
    var street: String
    var city: String
    var phone: String
}

// MARK: - ProfileView

struct ProfileView: View {
    @Query private var orders: [Order]
    @Environment(\.modelContext) private var modelContext
    @Environment(CartStore.self) private var cartStore
    @Environment(AuthStore.self) private var authStore
    @AppStorage(AppConstants.StorageKeys.profileName) private var profileName = ""
    @AppStorage(AppConstants.StorageKeys.profileEmail) private var profileEmail = ""
    @AppStorage(AppConstants.StorageKeys.notificationsEnabled) private var notificationsEnabled = true
    @AppStorage(AppConstants.StorageKeys.darkModeEnabled) private var darkModeEnabled = false
    @AppStorage(AppConstants.StorageKeys.loyaltyPoints) private var loyaltyPoints: Int = 0
    @AppStorage(AppConstants.StorageKeys.savedAddresses) private var savedAddressesData: String = ""
    @State private var showEditProfile = false
    @State private var showAddAddress = false
    @State private var showAuthSheet = false

    // MARK: - Computed Properties

    /// Decodes the JSON-encoded address list from AppStorage into typed SavedAddress values.
    var savedAddresses: [SavedAddress] {
        guard let data = savedAddressesData.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([SavedAddress].self, from: data)
        else { return [] }
        return decoded
    }

    /// Encodes an updated address array and writes it back to AppStorage as JSON.
    func persistAddresses(_ addresses: [SavedAddress]) {
        if let data = try? JSONEncoder().encode(addresses),
           let str = String(data: data, encoding: .utf8) {
            savedAddressesData = str
        }
    }

    /// Sums the total value of all SwiftData orders for display in the stats section.
    var totalSpent: Double { orders.reduce(0) { $0 + $1.total } }

    /// Derives one- or two-letter initials from the user's profile name for the avatar circle.
    var avatarInitials: String {
        let parts = profileName.split(separator: " ").filter { !$0.isEmpty }
        guard !parts.isEmpty else { return "G" }
        let first = String(parts[0].prefix(1)).uppercased()
        let last = parts.count > 1 ? String(parts[parts.count - 1].prefix(1)).uppercased() : ""
        return first + last
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                profileHeader
                statsSection
                loyaltySection
                addressesSection
                settingsSection
                aboutSection
                authSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(name: $profileName, email: $profileEmail)
            }
            .sheet(isPresented: $showAddAddress) {
                AddAddressSheet { newAddress in
                    var current = savedAddresses
                    current.append(newAddress)
                    persistAddresses(current)
                }
            }
            .sheet(isPresented: $showAuthSheet) {
                AuthView()
            }
            .onChange(of: authStore.needsAuth) { _, needsAuth in
                if !needsAuth { showAuthSheet = false }
            }
        }
    }

    // MARK: - Profile Header

    /// Avatar circle with initials, display name, email, and an edit-profile button.
    private var profileHeader: some View {
        Section {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Brand.gradient)
                        .frame(width: 70, height: 70)
                    Text(avatarInitials)
                        .font(.title).bold()
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(profileName.isEmpty ? "Guest User" : profileName)
                        .font(.title3).bold()
                    Text(profileEmail.isEmpty ? "Add your email" : profileEmail)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button { showEditProfile = true } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Stats Section

    /// Three-column stat row showing total orders, total amount spent, and delivered order count.
    private var statsSection: some View {
        Section("Shopping Summary") {
            HStack(spacing: 0) {
                StatBox(icon: "shippingbox.fill", value: "\(orders.count)", label: "Orders", color: AppTheme.Colors.primary)
                Divider()
                StatBox(icon: "creditcard.fill", value: String(format: "$%.0f", totalSpent), label: "Spent", color: AppTheme.Colors.accent)
                Divider()
                StatBox(icon: "checkmark.circle.fill",
                        value: "\(orders.filter { $0.status == .delivered }.count)",
                        label: "Delivered", color: AppTheme.Colors.success)
            }
            .frame(height: 80)
        }
    }

    // MARK: - Loyalty Section

    /// Loyalty tier card showing current points, Gold/Silver badge, and a progress bar toward the next Gold threshold.
    private var loyaltySection: some View {
        Section("Loyalty Rewards") {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(loyaltyPoints >= AppConstants.Loyalty.goldThreshold
                              ? LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                              : LinearGradient(colors: [.gray.opacity(0.6), .gray.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 50, height: 50)
                    Image(systemName: loyaltyPoints >= AppConstants.Loyalty.goldThreshold ? "star.fill" : "star.leadinghalf.filled")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(loyaltyPoints >= AppConstants.Loyalty.goldThreshold ? "Gold Member" : "Silver Member")
                        .font(.headline)
                    Text("\(loyaltyPoints) points")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    ProgressView(value: Double(loyaltyPoints % AppConstants.Loyalty.goldThreshold),
                                 total: Double(AppConstants.Loyalty.goldThreshold))
                        .tint(loyaltyPoints >= AppConstants.Loyalty.goldThreshold ? .yellow : AppTheme.Colors.primary)
                    Text(loyaltyPoints >= AppConstants.Loyalty.goldThreshold
                         ? "You're a Gold Member!"
                         : "\(AppConstants.Loyalty.goldThreshold - (loyaltyPoints % AppConstants.Loyalty.goldThreshold)) pts to Gold")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 6)
        }
    }

    // MARK: - Addresses Section

    /// List of saved shipping addresses with swipe-to-delete and an Add Address button that presents AddAddressSheet.
    private var addressesSection: some View {
        Section("Saved Addresses") {
            if savedAddresses.isEmpty {
                Text("No saved addresses yet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(savedAddresses) { address in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Label(address.label, systemImage: "mappin.circle.fill")
                                .font(.subheadline).bold()
                            Spacer()
                        }
                        Text(address.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(address.street), \(address.city)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }
                .onDelete { indexSet in
                    var current = savedAddresses
                    current.remove(atOffsets: indexSet)
                    persistAddresses(current)
                }
            }
            Button {
                showAddAddress = true
            } label: {
                Label("Add Address", systemImage: "plus.circle")
                    .foregroundColor(AppTheme.Colors.primary)
            }
        }
    }

    // MARK: - Settings Section

    /// Preferences section with notification and dark-mode toggles, plus navigation links to Orders and Wishlist.
    private var settingsSection: some View {
        Section("Preferences") {
            Toggle(isOn: $notificationsEnabled) {
                Label("Push Notifications", systemImage: "bell")
            }
            Toggle(isOn: $darkModeEnabled) {
                Label("Dark Mode", systemImage: "moon")
            }
            NavigationLink(destination: OrdersView()) {
                Label("My Orders", systemImage: "shippingbox")
            }
            NavigationLink(destination: WishlistView()) {
                Label("Wishlist", systemImage: "heart")
            }
        }
    }

    // MARK: - About Section

    /// App-info section with a Help & Support link, version number, and legal links.
    private var aboutSection: some View {
        Section("About") {
            NavigationLink(destination: SupportView()) {
                Label("Help & Support", systemImage: "questionmark.circle.fill")
            }
            LabeledContent("App Version", value: AppConstants.App.version)
            Link(destination: URL(string: AppConstants.App.privacyURL)!) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
            Link(destination: URL(string: AppConstants.App.termsURL)!) {
                Label("Terms of Service", systemImage: "doc.text")
            }
        }
    }

    // MARK: - Auth Section

    /// Renders the appropriate auth row: offline notice, sign-in button, or sign-out button.
    @ViewBuilder
    private var authSection: some View {
        if authStore.isOfflineMode {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "wifi.slash")
                        .foregroundStyle(.secondary)
                    Text("Offline mode — add Supabase keys to AppConfig to enable accounts")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        } else if authStore.session == nil {
            Section {
                Button {
                    showAuthSheet = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Sign In / Create Account", systemImage: "person.crop.circle.badge.plus")
                            .font(.headline)
                        Spacer()
                    }
                }
                .foregroundStyle(AppTheme.Colors.primary)
            }
        } else {
            Section {
                Button(role: .destructive) {
                    Task {
                        cartStore.clearAllUserData(context: modelContext)
                        await authStore.signOut()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        Spacer()
                    }
                }
            }
        }
    }
}

// MARK: - StatBox

/// Single stat cell used in the ProfileView shopping-summary row. Displays an icon, a numeric value, and a label.
struct StatBox: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    // MARK: - Body

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.headline).bold()
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - EditProfileView

/// Modal sheet for editing the user's display name and email. Writes back to ProfileView bindings on Save.
struct EditProfileView: View {
    @Binding var name: String
    @Binding var email: String
    @Environment(\.dismiss) private var dismiss
    @State private var tempName = ""
    @State private var tempEmail = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    HStack {
                        Image(systemName: "person").foregroundColor(.secondary)
                        TextField("Full Name", text: $tempName)
                    }
                    HStack {
                        Image(systemName: "envelope").foregroundColor(.secondary)
                        TextField("Email Address", text: $tempEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        name = tempName
                        email = tempEmail
                        dismiss()
                    }
                    .bold()
                }
            }
            .onAppear {
                tempName = name
                tempEmail = email
            }
        }
    }
}

// MARK: - AddAddressSheet

/// Half-height bottom sheet for creating a new SavedAddress. Calls onSave with the completed address and dismisses.
struct AddAddressSheet: View {
    let onSave: (SavedAddress) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var label = "Home"
    @State private var name = ""
    @State private var street = ""
    @State private var city = ""
    @State private var phone = ""

    let labelOptions = ["Home", "Work", "Other"]

    /// Returns true when the required name, street, and city fields are non-empty.
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !street.trimmingCharacters(in: .whitespaces).isEmpty &&
        !city.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Label") {
                    Picker("Label", selection: $label) {
                        ForEach(labelOptions, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Details") {
                    HStack {
                        Image(systemName: "person").foregroundColor(.secondary)
                        TextField("Full Name", text: $name)
                    }
                    HStack {
                        Image(systemName: "mappin").foregroundColor(.secondary)
                        TextField("Street Address", text: $street)
                    }
                    HStack {
                        Image(systemName: "building.2").foregroundColor(.secondary)
                        TextField("City", text: $city)
                    }
                    HStack {
                        Image(systemName: "phone").foregroundColor(.secondary)
                        TextField("Phone (optional)", text: $phone)
                            .keyboardType(.phonePad)
                    }
                }
            }
            .navigationTitle("New Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(SavedAddress(label: label, name: name, street: street, city: city, phone: phone))
                        dismiss()
                    }
                    .bold()
                    .disabled(!isValid)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    ProfileView()
        .environment(CartStore())
        .environment(AuthStore())
        .modelContainer(for: [CartItem.self, Order.self, OrderItem.self], inMemory: true)
}
