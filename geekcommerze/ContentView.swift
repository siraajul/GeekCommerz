import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var productStore = ProductStore()
    @State private var cartStore = CartStore()
    @State private var toastManager = ToastManager()
    @State private var notificationStore = NotificationStore()
    @State private var selectedTab = 0
    @State private var showPromoPopup = false
    @State private var promoShownThisLaunch = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem { Label("Home", systemImage: "house") }
                    .tag(0)

                SearchView()
                    .tabItem { Label("Search", systemImage: "magnifyingglass") }
                    .tag(1)

                ShopView()
                    .tabItem { Label("Shop", systemImage: "square.grid.2x2") }
                    .tag(2)

                CartView()
                    .tabItem {
                        ZStack {
                            Label("Cart", systemImage: "cart")
                        }
                    }
                    .tag(3)
                    .badge(cartStore.itemCount > 0 ? cartStore.itemCount : 0)

                ProfileView()
                    .tabItem { Label("Profile", systemImage: "person.circle") }
                    .tag(4)
            }
            .environment(productStore)
            .environment(cartStore)
            .environment(toastManager)
            .environment(notificationStore)
            .sheet(isPresented: $showPromoPopup) {
                PromoPopupView()
                    .presentationDragIndicator(.hidden)
                    .presentationCornerRadius(28)
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active && !promoShownThisLaunch {
                    promoShownThisLaunch = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        showPromoPopup = true
                    }
                }
            }

            if let toast = toastManager.currentToast {
                ToastOverlay(toast: toast)
                    .padding(.bottom, 90)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(999)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [CartItem.self, Order.self, OrderItem.self], inMemory: true)
}
