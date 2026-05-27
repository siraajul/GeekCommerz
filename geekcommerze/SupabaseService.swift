import Foundation
import Supabase

// ─────────────────────────────────────────────────────────────────────────────
// SupabaseService.swift
//
// ⚠️  BEFORE THIS FILE COMPILES:
//   Xcode → File → Add Package Dependencies
//   URL: https://github.com/supabase/supabase-swift
//   Version: Up to Next Major from 2.0.0
//   Add to target: geekcommerze
// ─────────────────────────────────────────────────────────────────────────────

/// Nil-safe Supabase client singleton. Returns `nil` instead of crashing when keys are missing so the app operates in offline mode. Used by `AuthStore` and `ProductStore`.
enum SupabaseService {

    // MARK: - Properties

    /// Lazily initialized `SupabaseClient` built from `AppConfig.Supabase` keys; nil when keys are still placeholder values, enabling offline mode.
    static let client: SupabaseClient? = {
        guard
            !AppConfig.Supabase.url.hasPrefix("YOUR_"),
            !AppConfig.Supabase.anonKey.hasPrefix("YOUR_"),
            let url = URL(string: AppConfig.Supabase.url)
        else { return nil }
        return SupabaseClient(supabaseURL: url, supabaseKey: AppConfig.Supabase.anonKey)
    }()

    /// True when `client` is non-nil, meaning valid Supabase keys are present and auth/data features are available.
    static var isConfigured: Bool { client != nil }
}
