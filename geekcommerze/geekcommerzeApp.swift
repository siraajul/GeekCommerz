import SwiftUI
import SwiftData
import Sentry
import OneSignalFramework

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
        let schema = Schema([
            CartItem.self,
            Order.self,
            OrderItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if authStore.isLoading {
                    // Splash while session is being restored
                    ZStack {
                        Color(.systemBackground).ignoresSafeArea()
                        VStack(spacing: 16) {
                            Image(systemName: "bag.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.blue)
                            ProgressView()
                        }
                    }
                } else if authStore.needsAuth {
                    AuthView()
                        .environment(authStore)
                } else {
                    ContentView()
                        .environment(authStore)
                }
            }
            .preferredColorScheme(darkModeEnabled ? .dark : .light)
            .fullScreenCover(isPresented: .constant(!hasSeenOnboarding)) {
                OnboardingView()
            }
            .task {
                await authStore.initialize()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
