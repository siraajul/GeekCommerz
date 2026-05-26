import SwiftUI
import SwiftData

struct SavedAddress: Codable, Identifiable {
    var id: UUID = UUID()
    var label: String
    var name: String
    var street: String
    var city: String
    var phone: String
}

struct ProfileView: View {
    @Query private var orders: [Order]
    @AppStorage(AppConstants.StorageKeys.profileName) private var profileName = ""
    @AppStorage(AppConstants.StorageKeys.profileEmail) private var profileEmail = ""
    @AppStorage(AppConstants.StorageKeys.notificationsEnabled) private var notificationsEnabled = true
    @AppStorage(AppConstants.StorageKeys.darkModeEnabled) private var darkModeEnabled = false
    @AppStorage(AppConstants.StorageKeys.loyaltyPoints) private var loyaltyPoints: Int = 0
    @AppStorage(AppConstants.StorageKeys.savedAddresses) private var savedAddressesData: String = ""
    @State private var showEditProfile = false
    @State private var showAddAddress = false

    var savedAddresses: [SavedAddress] {
        guard let data = savedAddressesData.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([SavedAddress].self, from: data)
        else { return [] }
        return decoded
    }

    func persistAddresses(_ addresses: [SavedAddress]) {
        if let data = try? JSONEncoder().encode(addresses),
           let str = String(data: data, encoding: .utf8) {
            savedAddressesData = str
        }
    }

    var totalSpent: Double { orders.reduce(0) { $0 + $1.total } }

    var avatarInitials: String {
        let parts = profileName.split(separator: " ").filter { !$0.isEmpty }
        guard !parts.isEmpty else { return "G" }
        let first = String(parts[0].prefix(1)).uppercased()
        let last = parts.count > 1 ? String(parts[parts.count - 1].prefix(1)).uppercased() : ""
        return first + last
    }

    var body: some View {
        NavigationStack {
            List {
                profileHeader
                statsSection
                loyaltySection
                addressesSection
                settingsSection
                aboutSection
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
        }
    }

    private var profileHeader: some View {
        Section {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
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
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var statsSection: some View {
        Section("Shopping Summary") {
            HStack(spacing: 0) {
                StatBox(icon: "shippingbox.fill", value: "\(orders.count)", label: "Orders", color: .blue)
                Divider()
                StatBox(icon: "creditcard.fill", value: String(format: "$%.0f", totalSpent), label: "Spent", color: .purple)
                Divider()
                StatBox(icon: "checkmark.circle.fill",
                        value: "\(orders.filter { $0.status == .delivered }.count)",
                        label: "Delivered", color: .green)
            }
            .frame(height: 80)
        }
    }

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
                        .tint(loyaltyPoints >= AppConstants.Loyalty.goldThreshold ? .yellow : .blue)
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
                    .foregroundColor(.blue)
            }
        }
    }

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

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("App Version", value: AppConstants.App.version)
            Link(destination: URL(string: AppConstants.App.privacyURL)!) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
            Link(destination: URL(string: AppConstants.App.termsURL)!) {
                Label("Terms of Service", systemImage: "doc.text")
            }
        }
    }
}

struct StatBox: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

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

struct EditProfileView: View {
    @Binding var name: String
    @Binding var email: String
    @Environment(\.dismiss) private var dismiss
    @State private var tempName = ""
    @State private var tempEmail = ""

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

struct AddAddressSheet: View {
    let onSave: (SavedAddress) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var label = "Home"
    @State private var name = ""
    @State private var street = ""
    @State private var city = ""
    @State private var phone = ""

    let labelOptions = ["Home", "Work", "Other"]

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !street.trimmingCharacters(in: .whitespaces).isEmpty &&
        !city.trimmingCharacters(in: .whitespaces).isEmpty
    }

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
        .modelContainer(for: [CartItem.self, Order.self, OrderItem.self], inMemory: true)
}
