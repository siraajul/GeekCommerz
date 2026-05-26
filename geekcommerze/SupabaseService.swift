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

enum SupabaseService {

    // Nil when AppConfig keys are still placeholders — app runs in offline mode
    static let client: SupabaseClient? = {
        guard
            !AppConfig.Supabase.url.hasPrefix("YOUR_"),
            !AppConfig.Supabase.anonKey.hasPrefix("YOUR_"),
            let url = URL(string: AppConfig.Supabase.url)
        else { return nil }
        return SupabaseClient(supabaseURL: url, supabaseKey: AppConfig.Supabase.anonKey)
    }()

    static var isConfigured: Bool { client != nil }
}
