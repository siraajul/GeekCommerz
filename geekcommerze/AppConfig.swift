import Foundation

// ─────────────────────────────────────────────────────────────────────────────
// AppConfig.swift — Environment / Service Keys
//
// HOW TO SET UP:
//   1. Open this file
//   2. Replace every "YOUR_..." placeholder with your real values
//   3. Build & run — AppConfig.validate() will crash loudly if you missed any
//
// ⚠️  NEVER commit real keys. Add this file to .git/info/exclude or run:
//       git update-index --assume-unchanged geekcommerze/geekcommerze/AppConfig.swift
// ─────────────────────────────────────────────────────────────────────────────

enum AppConfig {

    // MARK: - Supabase
    // Get these from: Supabase Dashboard → Project Settings → API
    enum Supabase {
        static let url      = "YOUR_SUPABASE_PROJECT_URL"   // e.g. https://xyzabc.supabase.co
        static let anonKey  = "YOUR_SUPABASE_ANON_KEY"      // starts with eyJ...
    }

    // MARK: - Stripe  (add when integrating payments)
    // Get from: Stripe Dashboard → Developers → API Keys
    enum Stripe {
        static let publishableKey = "YOUR_STRIPE_PUBLISHABLE_KEY"   // starts with pk_live_ or pk_test_
    }

    // MARK: - Push Notifications  (add when integrating OneSignal / APNs)
    enum Push {
        static let oneSignalAppID = "YOUR_ONESIGNAL_APP_ID"
    }

    // MARK: - Crash Reporting  (add when integrating Sentry or Firebase)
    enum Monitoring {
        static let sentryDSN = "YOUR_SENTRY_DSN"   // e.g. https://xxxx@oXXXX.ingest.sentry.io/XXXX
    }

    // MARK: - App URLs  (update before App Store submission)
    enum URLs {
        static let privacy = "https://example.com/privacy"
        static let terms   = "https://example.com/terms"
        static let support = "https://example.com/support"
    }

    // MARK: - Validator
    // Called at app launch in DEBUG builds — crashes immediately if any
    // required key still holds a placeholder value, so you can't miss it.
    // Skipped in Xcode Previews so previews work without real keys.
    static func validate() {
        #if DEBUG
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
        let required: [(String, String)] = [
            ("Supabase URL",      Supabase.url),
            ("Supabase Anon Key", Supabase.anonKey),
        ]
        for (name, value) in required {
            precondition(
                !value.hasPrefix("YOUR_"),
                "\n\n⛔️  AppConfig: \(name) is still a placeholder.\n   Open AppConfig.swift and replace it with your real value.\n"
            )
        }
        #endif
    }
}
