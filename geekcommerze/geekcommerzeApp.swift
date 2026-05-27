import SwiftUI
import SwiftData
import Sentry
import OneSignalFramework

// MARK: - Schema Versioning
//
// Every schema change needs a new VersionedSchema enum and a MigrationStage entry.
// Adding optional properties → .lightweight migration (no data transform needed).
// Renaming / changing types  → .custom migration stage with explicit data transform.

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] = [
        CartItem.self,
        Order.self,
        OrderItem.self,
    ]
}

enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [SchemaV1.self]
    // Add .lightweight or .custom stages here when a new SchemaV2 is introduced.
    static var stages: [MigrationStage] = []
}

@main
struct geekcommerzeApp: App {
    @AppStorage(AppConstants.StorageKeys.hasSeenOnboarding) private var hasSeenOnboarding = false
    @AppStorage(AppConstants.StorageKeys.darkModeEnabled) private var darkModeEnabled = false
    @State private var authStore = AuthStore()

    init() {
        AppConfig.validate()
        Self.configureSentry()
        Self.configureOneSignal()
    }

    private static func configureSentry() {
        let dsn = AppConfig.Monitoring.sentryDSN
        guard !dsn.hasPrefix("YOUR_") else { return }
        SentrySDK.start { options in
            options.dsn = dsn
            options.tracesSampleRate = 0.2
        }
    }

    private static func configureOneSignal() {
        let appID = AppConfig.Push.oneSignalAppID
        guard !appID.hasPrefix("YOUR_") else { return }
        OneSignal.initialize(appID, withLaunchOptions: nil)
        OneSignal.Notifications.requestPermission({ _ in }, fallbackToSettings: true)
    }

    var sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainer(
                for: CartItem.self, Order.self, OrderItem.self,
                migrationPlan: AppMigrationPlan.self
            )
        } catch {
            // Migration failed — wipe the local store so the user is never permanently
            // locked out of the app. Local cart/order history is lost, but that is
            // preferable to an unrecoverable crash on every launch.
            let fm = FileManager.default
            if let supportDir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                for name in ["default.store", "default.store-shm", "default.store-wal"] {
                    try? fm.removeItem(at: supportDir.appending(path: name))
                }
            }
            // After wiping, a fresh empty container must succeed.
            return try! ModelContainer(
                for: CartItem.self, Order.self, OrderItem.self,
                migrationPlan: AppMigrationPlan.self
            )
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if !hasSeenOnboarding {
                    // First launch: go straight to onboarding, no splash
                    OnboardingView()
                } else if authStore.isLoading {
                    // Returning user: branded splash while session restores
                    SplashView()
                } else if authStore.needsAuth {
                    AuthView()
                        .environment(authStore)
                } else {
                    ContentView()
                        .environment(authStore)
                }
            }
            .preferredColorScheme(darkModeEnabled ? .dark : .light)
            .tint(AppTheme.Colors.primary)
            .task {
                await authStore.initialize()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
