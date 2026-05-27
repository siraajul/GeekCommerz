import Foundation
import Observation
import Supabase

/// Manages Supabase authentication state. Injected app-wide via `.environment()`. Used by AuthView, ProfileView, and ContentView.
@Observable
@MainActor
final class AuthStore {

    // MARK: - Properties

    /// The active Supabase session. Nil when signed out or when no valid session exists.
    var session: Session?        = nil

    /// True while the initial auth state is being resolved from Supabase on launch.
    var isLoading: Bool          = true

    /// Holds a localized error message from the last failed auth operation. Nil when no error.
    var authError: String?       = nil

    /// True when Supabase keys aren't configured — app runs fully in offline mode without auth.
    var isOfflineMode: Bool { !SupabaseService.isConfigured }

    /// True when Supabase is configured and there is no active session; triggers AuthView presentation.
    var needsAuth: Bool { SupabaseService.isConfigured && session == nil }

    // MARK: - Bootstrap

    /// Subscribes to Supabase auth state changes and populates `session` from the initial or refreshed session; sets `isLoading` to false after the first event.
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

    /// Awaits a Supabase password sign-in and stores the returned session; sets `authError` on failure.
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

    /// Awaits a Supabase sign-up, stores the returned session, and fire-and-forgets a profile row insert; sets `authError` on failure.
    func signUp(email: String, password: String, name: String) async {
        guard let client = SupabaseService.client else { return }
        authError = nil
        do {
            let response = try await client.auth.signUp(email: email, password: password)
            session = response.session
            // Create profile row — fire and forget, non-critical
            if let uid = response.session?.user.id {
                _ = try? await client
                    .from("profiles")
                    .insert(["id": uid.uuidString, "name": name, "email": email])
                    .execute()
            }
        } catch {
            authError = error.localizedDescription
        }
    }

    // MARK: - Sign Out

    /// Awaits a Supabase sign-out and clears the local session; sets `authError` on failure.
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
