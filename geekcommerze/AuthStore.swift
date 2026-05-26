import Foundation
import Observation
import Supabase

@Observable
@MainActor
final class AuthStore {

    var session: Session?        = nil
    var isLoading: Bool          = true
    var authError: String?       = nil

    // True when Supabase keys aren't set — app works fully offline
    var isOfflineMode: Bool { !SupabaseService.isConfigured }

    // Auth gate: require login only when Supabase is configured and no session
    var needsAuth: Bool { SupabaseService.isConfigured && session == nil }

    // MARK: - Bootstrap

    func initialize() async {
        guard let client = SupabaseService.client else {
            isLoading = false
            return
        }
        // authStateChanges emits .initialSession first, so we let it drive state
        for await (event, newSession) in client.auth.authStateChanges {
            switch event {
            case .initialSession, .signedIn, .tokenRefreshed, .userUpdated:
                session = newSession
            case .signedOut, .passwordRecovery:
                session = nil
            default:
                break
            }
            if isLoading { isLoading = false }
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async {
        guard let client = SupabaseService.client else { return }
        authError = nil
        do {
            // signIn returns Session directly in supabase-swift v2
            session = try await client.auth.signIn(email: email, password: password)
        } catch {
            authError = error.localizedDescription
        }
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String, name: String) async {
        guard let client = SupabaseService.client else { return }
        authError = nil
        do {
            let response = try await client.auth.signUp(email: email, password: password)
            session = response.session
            // Create profile row — fire and forget, non-critical
            if let uid = response.session?.user.id {
                try? await client
                    .from("profiles")
                    .insert(["id": uid.uuidString, "name": name, "email": email])
                    .execute()
            }
        } catch {
            authError = error.localizedDescription
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        guard let client = SupabaseService.client else { return }
        do {
            try await client.auth.signOut()
            session = nil
        } catch {
            authError = error.localizedDescription
        }
    }
}
