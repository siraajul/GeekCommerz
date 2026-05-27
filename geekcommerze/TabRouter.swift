import Observation

// MARK: - TabRouter

/// App-wide `@Observable` tab router injected via `.environment()`.
/// Allows any screen to switch the root `TabView` programmatically
/// without a direct reference to the tab bar.
@Observable
class TabRouter {
    /// Index of the currently selected tab (0 = Home, 1 = Search, 2 = Shop, 3 = Cart, 4 = Profile).
    var selectedTab = 0
}
