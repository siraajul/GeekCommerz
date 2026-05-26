import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var productStore = ProductStore()
    @State private var cartStore = CartStore()
    @State private var toastManager = ToastManager()
    @State private var notificationStore = NotificationStore()
    @State private var tabRouter = TabRouter()
    @State private var showPromoPopup = false
    @State private var promoShownThisLaunch = false
    @State private var cartAnimationManager = CartAnimationManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        GeometryReader { geo in
          contentStack(screenSize: geo.size)
        }
        .ignoresSafeArea()
    }

    private func contentStack(screenSize: CGSize) -> some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $tabRouter.selectedTab) {
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
            .environment(cartAnimationManager)
            .environment(tabRouter)
            .onAppear {
                // Cart is the 4th tab (index 3) of 5 — center at 70% of width
                cartAnimationManager.cartTabCenter = CGPoint(
                    x: screenSize.width * 0.7,
                    y: screenSize.height - 44
                )
            }
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

            // Flying cart particles — rendered above everything, non-interactive
            ForEach(cartAnimationManager.particles) { particle in
                FlyingCartParticle(
                    start: particle.start,
                    end: cartAnimationManager.cartTabCenter,
                    imageName: particle.imageName,
                    onFinished: { cartAnimationManager.remove(id: particle.id) }
                )
            }
            .allowsHitTesting(false)
            .zIndex(1000)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [CartItem.self, Order.self, OrderItem.self], inMemory: true)
}
