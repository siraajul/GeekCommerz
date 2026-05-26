import SwiftUI
import SwiftData

@main
struct geekcommerzeApp: App {
    @AppStorage(AppConstants.StorageKeys.hasSeenOnboarding) private var hasSeenOnboarding = false
    @AppStorage(AppConstants.StorageKeys.darkModeEnabled) private var darkModeEnabled = false

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
            ContentView()
                .preferredColorScheme(darkModeEnabled ? .dark : .light)
                .fullScreenCover(isPresented: .constant(!hasSeenOnboarding)) {
                    OnboardingView()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
