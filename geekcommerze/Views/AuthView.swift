import SwiftUI

/// Login and sign-up screen presented when no authenticated session exists. Delegates all auth operations to AuthStore.
struct AuthView: View {
    @Environment(AuthStore.self) private var authStore
    @State private var isSignUp    = false
    @State private var name        = ""
    @State private var email       = ""
    @State private var password    = ""
    @State private var showPassword = false
    @State private var isLoading   = false
    @State private var emailSent   = false

    // MARK: - Validation

    /// Returns true when all visible fields satisfy minimum requirements for the current mode (sign-in or sign-up).
    var isFormValid: Bool {
        let trimEmail    = email.trimmingCharacters(in: .whitespaces)
        let trimPassword = password.trimmingCharacters(in: .whitespaces)
        let trimName     = name.trimmingCharacters(in: .whitespaces)
        let emailOK      = trimEmail.contains("@") && trimEmail.contains(".")
        let passwordOK   = trimPassword.count >= 6
        return isSignUp ? (emailOK && passwordOK && !trimName.isEmpty) : (emailOK && passwordOK)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                header
                if emailSent {
                    emailSentView
                } else {
                    formSection
                    actionButton
                    toggleMode
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 60)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .animation(.easeInOut(duration: 0.25), value: isSignUp)
        .animation(.easeInOut(duration: 0.25), value: emailSent)
    }

    // MARK: - Header

    /// Brand logo circle and contextual greeting title that updates when the user switches between sign-in and sign-up.
    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.Brand.gradient)
                    .frame(width: 80, height: 80)
                Image(systemName: "bag.fill")
                    .font(.system(size: 34))
                    .foregroundColor(.white)
            }
            Text("GeekCommerz")
                .font(.title).bold()
            Text(isSignUp ? "Create your account" : "Welcome back")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Form

    /// Card containing the inline error banner, optional name field (sign-up only), email field, and password field with show/hide toggle.
    private var formSection: some View {
        VStack(spacing: 12) {
            if let error = authStore.authError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(error)
                        .font(.caption)
                }
                .foregroundColor(.red)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if isSignUp {
                AuthField(icon: "person", placeholder: "Full Name", text: $name)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            AuthField(icon: "envelope", placeholder: "Email Address", text: $email,
                      keyboardType: .emailAddress, capitalization: .never)
            AuthField(icon: "lock", placeholder: "Password (min 6 chars)", text: $password,
                      isSecure: !showPassword)
                .overlay(alignment: .trailing) {
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                            .padding(.trailing, 14)
                    }
                }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Action Button

    /// Primary CTA button that invokes `submit()`. Renders a gradient fill when the form is valid, grey when disabled.
    private var actionButton: some View {
        Button {
            Task { await submit() }
        } label: {
            HStack {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(isSignUp ? "Create Account" : "Sign In")
                        .font(AppTheme.Typography.button)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundColor(.white)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(isFormValid ? AnyShapeStyle(AppTheme.Brand.gradientH) : AnyShapeStyle(Color.gray.opacity(0.5)))
            }
        }
        .disabled(!isFormValid || isLoading)
    }

    // MARK: - Toggle

    /// Inline text button that flips `isSignUp` and clears any lingering `authStore.authError`.
    private var toggleMode: some View {
        Button {
            isSignUp.toggle()
            authStore.authError = nil
        } label: {
            Group {
                if isSignUp {
                    Text("Already have an account? ") + Text("Sign In").bold().foregroundColor(AppTheme.Colors.primary)
                } else {
                    Text("Don't have an account? ") + Text("Sign Up").bold().foregroundColor(AppTheme.Colors.primary)
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
    }

    // MARK: - Email Sent Confirmation

    /// Success state shown after sign-up when Supabase returns no session, prompting the user to confirm their email.
    private var emailSentView: some View {
        VStack(spacing: 20) {
            Image(systemName: "envelope.badge.checkmark.fill")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.primary)
            Text("Check your inbox")
                .font(.title2).bold()
            Text("We sent a confirmation link to **\(email)**. Click it to activate your account, then sign in.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Back to Sign In") {
                emailSent = false
                isSignUp  = false
                password  = ""
            }
            .font(.subheadline.bold())
            .foregroundColor(AppTheme.Colors.primary)
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Submit

    /// Calls `authStore.signIn` or `authStore.signUp` based on `isSignUp`, sets `emailSent` when Supabase requires email confirmation.
    private func submit() async {
        isLoading = true
        defer { isLoading = false }
        if isSignUp {
            await authStore.signUp(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password,
                name: name.trimmingCharacters(in: .whitespaces)
            )
            // No session returned → Supabase requires email confirmation
            if authStore.authError == nil && authStore.session == nil {
                emailSent = true
            }
        } else {
            await authStore.signIn(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password
            )
        }
    }
}

// MARK: - AuthField

/// Reusable styled text-field row with a leading SF Symbol icon, supporting both plain and secure entry modes.
private struct AuthField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var capitalization: TextInputAutocapitalization = .sentences
    var isSecure: Bool = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(capitalization)
                    .autocorrectionDisabled()
            }
        }
        .padding(14)
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    AuthView()
        .environment(AuthStore())
}
