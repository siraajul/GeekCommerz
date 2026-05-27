<div align="center">

# GeekCommerz — Android Native Build Plan

**Complete guide to rebuilding GeekCommerz as a native Android app**
**using Kotlin · Jetpack Compose · Supabase · Room**

[![Kotlin](https://img.shields.io/badge/Kotlin-2.0-7F52FF?style=for-the-badge&logo=kotlin&logoColor=white)](https://kotlinlang.org)
[![Jetpack Compose](https://img.shields.io/badge/Jetpack_Compose-1.7-4285F4?style=for-the-badge&logo=jetpackcompose&logoColor=white)](https://developer.android.com/jetpack/compose)
[![Android](https://img.shields.io/badge/Android-8.0%2B-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com)
[![Supabase](https://img.shields.io/badge/Supabase-ready-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)

*Same backend. Same features. True native Android.*

</div>

---

## iOS → Android Concept Map

| Concept | iOS (current) | Android (target) |
|---|---|---|
| UI framework | SwiftUI | Jetpack Compose |
| Observable state | `@Observable` class | `ViewModel` + `StateFlow` |
| Environment injection | `@Environment(Store.self)` | Hilt dependency injection |
| Local persistence | SwiftData | Room |
| Key-value storage | `@AppStorage` | DataStore Preferences |
| Navigation | `NavigationStack` | Navigation Compose |
| Async networking | Swift `async/await` | Kotlin Coroutines + Flow |
| Backend | Supabase Swift SDK | Supabase Kotlin SDK |
| Auth | Supabase Auth | Supabase Auth (same API) |
| Biometrics | `LocalAuthentication` | `BiometricPrompt` |
| Haptics | `UIImpactFeedbackGenerator` | `VibrationEffect` |
| Push notifications | OneSignal | OneSignal Android SDK |
| Crash reporting | Sentry iOS | Sentry Android |
| Payments | Stripe iOS SDK | Stripe Android SDK |
| Charts | Swift Charts | Vico |
| Architecture | `@Observable` stores | MVVM + Repository pattern |

---

## Architecture

```
┌─────────────────────────────────────────────┐
│               Jetpack Compose UI             │
│  (Screens / Composables / Navigation)        │
└──────────────────┬──────────────────────────┘
                   │ collectAsState()
┌──────────────────▼──────────────────────────┐
│              ViewModels (Hilt)               │
│  StateFlow<UiState>  ·  one per screen       │
└──────────────┬──────────────┬───────────────┘
               │              │
┌──────────────▼──┐   ┌───────▼──────────────┐
│  Repositories   │   │  Shared Managers      │
│  (data layer)   │   │  CartManager          │
│                 │   │  AuthManager          │
│                 │   │  ToastManager         │
└──┬──────────┬───┘   └───────────────────────┘
   │          │
┌──▼──┐  ┌────▼─────────────────────────────┐
│Room │  │  Supabase Kotlin SDK             │
│(DB) │  │  (Auth · PostgREST · Realtime)   │
└─────┘  └──────────────────────────────────┘
```

```
GeekCommerz-Android/
├── app/src/main/
│   ├── java/com/geekcommerz/
│   │   ├── data/
│   │   │   ├── local/          Room database, DAOs, entities
│   │   │   ├── remote/         Supabase service, DTOs
│   │   │   └── repository/     CartRepository, ProductRepository, OrderRepository
│   │   ├── domain/
│   │   │   └── model/          Product, CartItem, Order (pure Kotlin data classes)
│   │   ├── ui/
│   │   │   ├── theme/          AppTheme, Colors, Typography, Shapes
│   │   │   ├── components/     Shared composables (ToastOverlay, SummaryRow, etc.)
│   │   │   └── screens/        One package per screen
│   │   ├── util/
│   │   │   ├── HapticUtil.kt
│   │   │   ├── PromoService.kt
│   │   │   └── AppConstants.kt
│   │   ├── di/                 Hilt modules
│   │   ├── navigation/         NavGraph, Screen sealed class
│   │   └── GeekCommerz.kt      Application class (Hilt entry point)
│   └── res/
│       ├── values/             strings.xml, colors.xml, themes.xml
│       └── drawable/           Vector icons, launcher
└── build.gradle.kts
```

---

## Environment Setup

### 1. Install tools

| Tool | Version | Download |
|---|---|---|
| Android Studio | Meerkat (2024.3+) | developer.android.com/studio |
| JDK | 17 (bundled in AS) | — |
| Kotlin | 2.0+ | bundled in Android Studio |
| Gradle | 8.7+ | managed by Android Studio |

### 2. Create the project

1. Open Android Studio → **New Project**
2. Select **Empty Activity** (Compose enabled by default)
3. Set:
   - **Name:** `GeekCommerz`
   - **Package:** `com.geekcommerz`
   - **Min SDK:** API 26 (Android 8.0 — ~95% device coverage)
   - **Language:** Kotlin
   - **Build config:** Kotlin DSL

### 3. Minimum SDK rationale

API 26 gives access to `BiometricPrompt`, `VibrationEffect`, `ShortcutManager`, and modern cryptography APIs needed for secure token storage.

---

## Full `build.gradle.kts` (app module)

```kotlin
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.hilt.android)
    alias(libs.plugins.ksp)
    kotlin("plugin.serialization") version "2.0.0"
}

android {
    namespace = "com.geekcommerz"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.geekcommerz"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"

        buildConfigField("String", "SUPABASE_URL",     "\"${project.findProperty("SUPABASE_URL") ?: ""}\"")
        buildConfigField("String", "SUPABASE_ANON_KEY","\"${project.findProperty("SUPABASE_ANON_KEY") ?: ""}\"")
        buildConfigField("String", "STRIPE_KEY",       "\"${project.findProperty("STRIPE_KEY") ?: ""}\"")
        buildConfigField("String", "ONESIGNAL_APP_ID", "\"${project.findProperty("ONESIGNAL_APP_ID") ?: ""}\"")
        buildConfigField("String", "SENTRY_DSN",       "\"${project.findProperty("SENTRY_DSN") ?: ""}\"")
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }
}

dependencies {
    // ── Jetpack Compose BOM ──────────────────────────────────────────────
    val composeBom = platform("androidx.compose:compose-bom:2024.09.00")
    implementation(composeBom)
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.activity:activity-compose:1.9.2")
    debugImplementation("androidx.compose.ui:ui-tooling")

    // ── Navigation ───────────────────────────────────────────────────────
    implementation("androidx.navigation:navigation-compose:2.8.2")

    // ── ViewModel + Lifecycle ────────────────────────────────────────────
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.6")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.8.6")

    // ── Hilt (dependency injection) ──────────────────────────────────────
    implementation("com.google.dagger:hilt-android:2.52")
    ksp("com.google.dagger:hilt-compiler:2.52")
    implementation("androidx.hilt:hilt-navigation-compose:1.2.0")

    // ── Room (local database) ────────────────────────────────────────────
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    ksp("androidx.room:room-compiler:2.6.1")

    // ── DataStore (AppStorage equivalent) ───────────────────────────────
    implementation("androidx.datastore:datastore-preferences:1.1.1")

    // ── Supabase Kotlin SDK ──────────────────────────────────────────────
    val supabaseVersion = "3.0.0"
    implementation(platform("io.github.jan-tennert.supabase:bom:$supabaseVersion"))
    implementation("io.github.jan-tennert.supabase:postgrest-kt")
    implementation("io.github.jan-tennert.supabase:auth-kt")
    implementation("io.github.jan-tennert.supabase:realtime-kt")
    implementation("io.ktor:ktor-client-android:2.3.12")

    // ── Kotlin Serialization ─────────────────────────────────────────────
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.1")

    // ── Coroutines ───────────────────────────────────────────────────────
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")

    // ── Image loading ────────────────────────────────────────────────────
    implementation("io.coil-kt.coil3:coil-compose:3.0.0")
    implementation("io.coil-kt.coil3:coil-network-okhttp:3.0.0")

    // ── Charts (Swift Charts equivalent) ────────────────────────────────
    implementation("com.patrykandpatrick.vico:compose-m3:2.0.0-beta.2")

    // ── Biometrics ───────────────────────────────────────────────────────
    implementation("androidx.biometric:biometric:1.2.0-alpha05")

    // ── Payments ─────────────────────────────────────────────────────────
    implementation("com.stripe:stripe-android:20.52.0")

    // ── Push notifications ───────────────────────────────────────────────
    implementation("com.onesignal:OneSignal:5.1.22")

    // ── Crash reporting ──────────────────────────────────────────────────
    implementation("io.sentry:sentry-android:7.14.0")

    // ── Confetti ─────────────────────────────────────────────────────────
    implementation("nl.dionsegijn:konfetti-compose:2.0.4")
}
```

---

## Keys Setup (`local.properties`)

Store all service keys in `local.properties` — this file is gitignored by default.

```properties
# local.properties  (never commit this file)
SUPABASE_URL=https://xyzabc.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...
STRIPE_KEY=pk_test_...
ONESIGNAL_APP_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
SENTRY_DSN=https://xxxx@oXXX.ingest.sentry.io/XXXX
```

Access in code via `BuildConfig.SUPABASE_URL` etc. (generated by `buildConfigField` above).

---

## Supabase Setup

The Supabase project, tables, RLS policies, and `decrement_stock` function are **identical** to the iOS version — no changes needed on the backend.

### Android client singleton

```kotlin
// di/SupabaseModule.kt
@Module
@InstallIn(SingletonComponent::class)
object SupabaseModule {

    @Provides @Singleton
    fun provideSupabaseClient(): SupabaseClient = createSupabaseClient(
        supabaseUrl = BuildConfig.SUPABASE_URL,
        supabaseKey = BuildConfig.SUPABASE_ANON_KEY
    ) {
        install(Auth)
        install(Postgrest)
        install(Realtime)
    }
}
```

---

## Room Database

### Entities (map directly from iOS models)

```kotlin
// data/local/CartItemEntity.kt
@Entity(tableName = "cart_items")
data class CartItemEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val productId: String,
    val productName: String,
    val price: Double,
    val quantity: Int,
    val imageName: String,
    val selectedColor: String? = null,
    val selectedSize: String? = null
)

// data/local/OrderEntity.kt
@Entity(tableName = "orders")
data class OrderEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val total: Double,
    val status: String,   // "pending" | "confirmed" | "shipped" | "delivered" | "cancelled"
    val shippingName: String,
    val shippingAddress: String,
    val shippingCity: String,
    val shippingPhone: String,
    val createdAt: Long = System.currentTimeMillis()
)

@Entity(tableName = "order_items", foreignKeys = [
    ForeignKey(entity = OrderEntity::class, parentColumns = ["id"], childColumns = ["orderId"])
])
data class OrderItemEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val orderId: String,
    val productId: String,
    val productName: String,
    val price: Double,
    val quantity: Int
)
```

### DAOs

```kotlin
@Dao
interface CartDao {
    @Query("SELECT * FROM cart_items")
    fun observeAll(): Flow<List<CartItemEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(item: CartItemEntity)

    @Delete
    suspend fun delete(item: CartItemEntity)

    @Query("UPDATE cart_items SET quantity = :qty WHERE id = :id")
    suspend fun updateQuantity(id: String, qty: Int)

    @Query("DELETE FROM cart_items")
    suspend fun clearAll()
}

@Dao
interface OrderDao {
    @Query("SELECT * FROM orders ORDER BY createdAt DESC")
    fun observeAll(): Flow<List<OrderEntity>>

    @Insert
    suspend fun insert(order: OrderEntity)

    @Insert
    suspend fun insertItems(items: List<OrderItemEntity>)

    @Query("DELETE FROM orders")
    suspend fun clearAll()
}
```

### Database

```kotlin
@Database(
    entities = [CartItemEntity::class, OrderEntity::class, OrderItemEntity::class],
    version = 1
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun cartDao(): CartDao
    abstract fun orderDao(): OrderDao
}
```

---

## DataStore Preferences (AppStorage equivalent)

```kotlin
// data/local/PreferencesManager.kt
class PreferencesManager @Inject constructor(
    @ApplicationContext context: Context
) {
    private val ds = context.createDataStore("prefs")

    companion object Keys {
        val PROFILE_NAME      = stringPreferencesKey("profile_name")
        val PROFILE_EMAIL     = stringPreferencesKey("profile_email")
        val LOYALTY_POINTS    = intPreferencesKey("loyalty_points")
        val DARK_MODE         = booleanPreferencesKey("dark_mode_enabled")
        val NOTIFICATIONS     = booleanPreferencesKey("notifications_enabled")
        val WISHLIST          = stringPreferencesKey("wishlist_ids")
        val SAVED_ADDRESSES   = stringPreferencesKey("saved_addresses_json")
        val HAS_SEEN_ONBOARD  = booleanPreferencesKey("has_seen_onboarding")
        val RECENTLY_VIEWED   = stringPreferencesKey("recently_viewed_ids")
    }

    val preferences: Flow<Preferences> = ds.data

    suspend fun <T> set(key: Preferences.Key<T>, value: T) {
        ds.edit { it[key] = value }
    }
}
```

---

## Navigation

```kotlin
// navigation/Screen.kt
sealed class Screen(val route: String) {
    object Splash       : Screen("splash")
    object Onboarding   : Screen("onboarding")
    object Home         : Screen("home")
    object Search       : Screen("search")
    object Shop         : Screen("shop/{category}") {
        fun go(category: String = "") = "shop/$category"
    }
    object ProductDetail: Screen("product/{id}") {
        fun go(id: String) = "product/$id"
    }
    object Cart         : Screen("cart")
    object Checkout     : Screen("checkout")
    object Orders       : Screen("orders")
    object OrderDetail  : Screen("order/{id}") {
        fun go(id: String) = "order/$id"
    }
    object Profile      : Screen("profile")
    object Wishlist     : Screen("wishlist")
    object Notifications: Screen("notifications")
    object Auth         : Screen("auth")
    object Support      : Screen("support")
}

// navigation/NavGraph.kt
@Composable
fun NavGraph(navController: NavHostController) {
    NavHost(navController, startDestination = Screen.Splash.route) {
        composable(Screen.Splash.route)        { SplashScreen(navController) }
        composable(Screen.Onboarding.route)    { OnboardingScreen(navController) }
        composable(Screen.Home.route)          { HomeScreen(navController) }
        composable(Screen.Search.route)        { SearchScreen(navController) }
        composable(
            Screen.Shop.route,
            arguments = listOf(navArgument("category") { defaultValue = "" })
        ) { entry ->
            ShopScreen(navController, entry.arguments?.getString("category") ?: "")
        }
        composable(
            Screen.ProductDetail.route,
            arguments = listOf(navArgument("id") { type = NavType.StringType })
        ) { entry ->
            ProductDetailScreen(navController, entry.arguments!!.getString("id")!!)
        }
        composable(Screen.Cart.route)          { CartScreen(navController) }
        composable(Screen.Checkout.route)      { CheckoutScreen(navController) }
        composable(Screen.Orders.route)        { OrdersScreen(navController) }
        composable(Screen.Profile.route)       { ProfileScreen(navController) }
        composable(Screen.Wishlist.route)      { WishlistScreen(navController) }
        composable(Screen.Notifications.route) { NotificationsScreen(navController) }
        composable(Screen.Auth.route)          { AuthScreen(navController) }
        composable(Screen.Support.route)       { SupportScreen(navController) }
    }
}
```

### Tab bar (Bottom Navigation)

```kotlin
@Composable
fun MainScaffold() {
    val navController = rememberNavController()
    val tabs = listOf(
        Triple("Home",   Icons.Default.Home,              Screen.Home.route),
        Triple("Search", Icons.Default.Search,            Screen.Search.route),
        Triple("Shop",   Icons.Default.GridView,          Screen.Shop.go()),
        Triple("Cart",   Icons.Default.ShoppingCart,      Screen.Cart.route),
        Triple("Profile",Icons.Default.AccountCircle,     Screen.Profile.route),
    )

    Scaffold(
        bottomBar = {
            NavigationBar {
                val navBackStack by navController.currentBackStackEntryAsState()
                val currentRoute = navBackStack?.destination?.route
                tabs.forEach { (label, icon, route) ->
                    NavigationBarItem(
                        selected = currentRoute == route,
                        onClick  = { navController.navigate(route) { launchSingleTop = true } },
                        icon     = { Icon(icon, label) },
                        label    = { Text(label) }
                    )
                }
            }
        }
    ) { padding ->
        Box(Modifier.padding(padding)) {
            NavGraph(navController)
        }
    }
}
```

---

## Theme (AppTheme equivalent)

```kotlin
// ui/theme/AppTheme.kt
val PrimaryIndigo  = Color(0xFF5856D6)
val AccentViolet   = Color(0xFF9F7AEA)
val DangerRed      = Color(0xFFFF3B30)
val SuccessGreen   = Color(0xFF34C759)
val SurfaceGray    = Color(0xFFF2F2F7)

val GradientBrush = Brush.horizontalGradient(listOf(PrimaryIndigo, AccentViolet))

private val LightColors = lightColorScheme(
    primary         = PrimaryIndigo,
    secondary       = AccentViolet,
    error           = DangerRed,
    surface         = Color.White,
    background      = SurfaceGray,
)

private val DarkColors = darkColorScheme(
    primary         = Color(0xFF7C7AFF),
    secondary       = AccentViolet,
    error           = DangerRed,
    surface         = Color(0xFF1C1C1E),
    background      = Color(0xFF000000),
)

@Composable
fun GeekCommerZTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = if (darkTheme) DarkColors else LightColors,
        typography  = GeekTypography,
        content     = content
    )
}
```

---

## Screen-by-Screen Implementation Plan

### 1. SplashScreen

**iOS equivalent:** `SplashView.swift`

```kotlin
@Composable
fun SplashScreen(navController: NavHostController) {
    val scale = remember { Animatable(0.8f) }

    LaunchedEffect(Unit) {
        scale.animateTo(1f, animationSpec = spring(dampingRatio = Spring.DampingRatioMediumBouncy))
        delay(1200)
        navController.navigate(Screen.Home.route) { popUpTo(Screen.Splash.route) { inclusive = true } }
    }

    Box(Modifier.fillMaxSize().background(brush = GradientBrush), contentAlignment = Alignment.Center) {
        Text("GeekCommerZ", style = MaterialTheme.typography.displayMedium,
             color = Color.White, modifier = Modifier.scale(scale.value))
    }
}
```

---

### 2. OnboardingScreen

**iOS equivalent:** `OnboardingView.swift`

- 3-page `HorizontalPager` (Accompanist or built-in Compose)
- `PagerState` drives dot indicators
- "Get Started" button on last page writes `HAS_SEEN_ONBOARD = true` and navigates to Home
- Guard in `GeekCommerZ.kt` routes to Onboarding if flag is false

```kotlin
@Composable
fun OnboardingScreen(navController: NavHostController, vm: OnboardingViewModel = hiltViewModel()) {
    val pagerState = rememberPagerState(pageCount = { 3 })

    Column(Modifier.fillMaxSize()) {
        HorizontalPager(state = pagerState, Modifier.weight(1f)) { page ->
            OnboardingPage(pages[page])
        }
        Row(horizontalArrangement = Arrangement.Center) {
            repeat(3) { i ->
                Box(
                    Modifier.size(if (pagerState.currentPage == i) 24.dp else 8.dp, 8.dp)
                        .clip(CircleShape)
                        .background(if (pagerState.currentPage == i) MaterialTheme.colorScheme.primary else Color.Gray)
                )
            }
        }
        if (pagerState.currentPage == 2) {
            Button(onClick = { vm.completeOnboarding(); navController.navigate(Screen.Home.route) }) {
                Text("Get Started")
            }
        }
    }
}
```

---

### 3. HomeScreen

**iOS equivalent:** `HomeView.swift`

**Features to implement:**
- Auto-scrolling promo banner (LaunchedEffect + PagerState + LazyRow)
- Flash sale countdown timer (CountDownTimer → StateFlow → UI)
- Skeleton loading placeholders (shimmer effect via animated alpha)
- Category chips → navigate to ShopScreen with category filter
- Recently viewed horizontal scroll
- Promo popup bottom sheet (ModalBottomSheet) on app resume, shown once per launch

```kotlin
@HiltViewModel
class HomeViewModel @Inject constructor(
    private val productRepo: ProductRepository,
    private val prefsManager: PreferencesManager
) : ViewModel() {

    val uiState: StateFlow<HomeUiState> = combine(
        productRepo.products,
        prefsManager.preferences
    ) { products, prefs ->
        HomeUiState(
            featured    = products.filter { it.isFeatured },
            categories  = products.map { it.category }.distinct(),
            recentIds   = prefs[PreferencesManager.Keys.RECENTLY_VIEWED]
                              ?.split(",")?.filter { it.isNotBlank() } ?: emptyList(),
            isLoading   = false
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), HomeUiState(isLoading = true))

    val flashSaleSeconds = MutableStateFlow(3600)

    init {
        viewModelScope.launch {
            while (true) { delay(1000); flashSaleSeconds.update { if (it > 0) it - 1 else 0 } }
        }
    }
}
```

---

### 4. SearchScreen

**iOS equivalent:** `SearchView.swift`

- `TextField` with debounced search using `snapshotFlow` + `debounce(300ms)`
- Trending chips as `LazyRow` of `FilterChip`
- Recent searches stored in DataStore (max 8), persisted across sessions
- Results shown in `LazyColumn`

```kotlin
@HiltViewModel
class SearchViewModel @Inject constructor(
    private val repo: ProductRepository,
    private val prefs: PreferencesManager
) : ViewModel() {

    val query = MutableStateFlow("")
    val results = query
        .debounce(300)
        .flatMapLatest { q -> repo.search(q) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(), emptyList())

    fun submitSearch(q: String) {
        viewModelScope.launch { prefs.addRecentSearch(q) }
    }
}
```

---

### 5. ShopScreen

**iOS equivalent:** `ShopView.swift`

- `LazyVerticalGrid(columns = Fixed(2))` for 2-column product grid
- Sort & Filter as `ModalBottomSheet`
- Pull-to-refresh via `PullToRefreshBox`
- Long-press context menu via `combinedClickable` + `DropdownMenu`
- `AnimatedVisibility` for filter chips

```kotlin
@Composable
fun ProductCard(product: Product, onAddToCart: () -> Unit, onLongPress: () -> Unit) {
    var showMenu by remember { mutableStateOf(false) }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .combinedClickable(
                onClick = { /* navigate */ },
                onLongClick = { showMenu = true; performHaptic() }
            )
    ) {
        // Product image, name, price, Add to Cart button
        DropdownMenu(expanded = showMenu, onDismissRequest = { showMenu = false }) {
            DropdownMenuItem(text = { Text("Add to Cart") }, onClick = { onAddToCart(); showMenu = false })
            DropdownMenuItem(text = { Text("Add to Wishlist") }, onClick = { /* wishlist */ })
            DropdownMenuItem(text = { Text("Share") }, onClick = { /* share */ })
        }
    }
}
```

---

### 6. ProductDetailScreen

**iOS equivalent:** `ProductDetailView.swift`

- Pinch-to-zoom image: `transformable` modifier with `rememberTransformableState`
- 4-image gallery: `HorizontalPager` with dot indicators
- Color/size variant selectors: `LazyRow` of `FilterChip`
- Price history chart: Vico `CartesianChartHost`
- Reviews section: `LazyColumn` embedded in `Column` (non-scrollable inner, outer handles scroll)
- Collapsible "Bundle" and "Related" sections: `AnimatedVisibility`
- Add to Cart bar: `BottomAppBar` with gradient background

```kotlin
@Composable
fun PinchZoomImage(imageRes: String) {
    var scale by remember { mutableFloatStateOf(1f) }
    var offset by remember { mutableStateOf(Offset.Zero) }
    val transformState = rememberTransformableState { zoomChange, panChange, _ ->
        scale = (scale * zoomChange).coerceIn(1f, 5f)
        offset += panChange
    }
    AsyncImage(
        model = imageRes,
        contentDescription = null,
        modifier = Modifier
            .transformable(transformState)
            .graphicsLayer(scaleX = scale, scaleY = scale, translationX = offset.x, translationY = offset.y)
    )
}
```

---

### 7. CartScreen

**iOS equivalent:** `CartView.swift`

- `LazyColumn` of cart items
- Swipe-to-dismiss: `SwipeToDismissBox` (Material3)
  - Leading swipe → add to wishlist
  - Trailing swipe → delete item
- Pill-style quantity stepper: Row with `IconButton` (minus/trash) + `Text` + `IconButton` (plus)
- `AnimatedContent` with `numericText`-style transition on quantity/total
- Order summary pinned at bottom via `Scaffold` `bottomBar`
- Auth gate: if `authState.needsAuth`, navigate to Auth screen; on login success, navigate to Checkout

```kotlin
@Composable
fun CartItemRow(item: CartItem, onIncrement: () -> Unit, onDecrement: () -> Unit) {
    val dismissState = rememberSwipeToDismissBoxState(
        confirmValueChange = { it == SwipeToDismissBoxValue.EndToStart }
    )

    SwipeToDismissBox(
        state = dismissState,
        backgroundContent = {
            Box(Modifier.fillMaxSize().background(Color.Red), contentAlignment = Alignment.CenterEnd) {
                Icon(Icons.Default.Delete, contentDescription = "Delete", tint = Color.White,
                     modifier = Modifier.padding(end = 20.dp))
            }
        }
    ) {
        // Cart item content: image, name, price, stepper
    }
}
```

---

### 8. CheckoutScreen

**iOS equivalent:** `CheckoutView.swift`

- Multi-step form: address → payment → confirmation
- Saved address picker: `ModalBottomSheet` with `LazyColumn` of addresses from DataStore
- Promo code field: same SHA-256 hash validation as iOS (`PromoService.kt`)
- Biometric confirm: `BiometricPrompt` before order placement
- Google Pay button (equivalent to Apple Pay demo): `PayButton` from Google Pay Compose
- Confetti on success: Konfetti library

```kotlin
fun verifyBiometric(context: FragmentActivity, onSuccess: () -> Unit, onFail: () -> Unit) {
    val executor = ContextCompat.getMainExecutor(context)
    val prompt = BiometricPrompt(context, executor, object : BiometricPrompt.AuthenticationCallback() {
        override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) = onSuccess()
        override fun onAuthenticationError(code: Int, msg: CharSequence) = onFail()
        override fun onAuthenticationFailed() = onFail()
    })
    val info = BiometricPrompt.PromptInfo.Builder()
        .setTitle("Confirm Order")
        .setSubtitle("Use biometrics to place your order")
        .setNegativeButtonText("Use passcode")
        .build()
    prompt.authenticate(info)
}
```

---

### 9. OrdersScreen / OrderDetailScreen

**iOS equivalent:** `OrdersView.swift`

- `LazyColumn` of order cards grouped by status
- Status timeline: vertical `Column` with `Canvas`-drawn connecting lines between status dots
- Reorder: re-inserts items into Room cart
- Return request: persisted flag in Room `OrderEntity.hasReturnRequest`

---

### 10. WishlistScreen

**iOS equivalent:** `WishlistView.swift`

- Wishlist IDs stored as comma-separated string in DataStore (same as iOS)
- `LazyVerticalGrid` matching ShopScreen layout
- Spring-exit animation on remove: `AnimatedVisibility` with `scaleOut() + fadeOut()`
- Heart toggle from any screen: managed by `WishlistManager` singleton (Hilt `@Singleton`)

---

### 11. ProfileScreen

**iOS equivalent:** `ProfileView.swift`

- Avatar circle with initials computed from name
- Stats row: orders count, total spent, delivered count (from Room `@Query`)
- Loyalty tier: Gold (≥1000 pts) / Silver, progress bar
- Saved addresses: JSON list in DataStore, swipe-to-delete in `LazyColumn`
- Dark mode toggle: writes `DARK_MODE` to DataStore, read in `GeekCommerZ.kt` to switch theme
- **Auth-aware footer (same 3-state logic as iOS):**
  - Offline (no Supabase keys) → notice row
  - Supabase configured, not signed in → "Sign In / Create Account" button → navigate to AuthScreen
  - Signed in → "Sign Out" button → clears Room + navigates back

---

### 12. NotificationsScreen

**iOS equivalent:** `NotificationsView.swift`

- Notification data stored in Room (`NotificationEntity`)
- Badge count via `Flow<Int>` from Room `@Query("SELECT COUNT(*) WHERE isRead = 0")`
- Swipe actions: mark read (leading), delete (trailing) using `SwipeToDismissBox`
- Seeded with mock notifications on first launch

---

### 13. AuthScreen

**iOS equivalent:** `AuthView.swift`

- Email + password fields with show/hide toggle
- Sign In / Sign Up tabs
- Email confirmation state handling
- Same Supabase Auth API — `supabase.auth.signInWithPassword(email, password)`

```kotlin
@HiltViewModel
class AuthViewModel @Inject constructor(
    private val supabase: SupabaseClient
) : ViewModel() {

    val uiState = MutableStateFlow(AuthUiState())

    fun signIn(email: String, password: String) {
        viewModelScope.launch {
            uiState.update { it.copy(isLoading = true) }
            try {
                supabase.auth.signInWithPassword(email = email, password = password)
                uiState.update { it.copy(isLoading = false, success = true) }
            } catch (e: Exception) {
                uiState.update { it.copy(isLoading = false, error = e.message) }
            }
        }
    }

    fun signUp(email: String, password: String) {
        viewModelScope.launch {
            uiState.update { it.copy(isLoading = true) }
            try {
                supabase.auth.signUpWith(Email) { this.email = email; this.password = password }
                uiState.update { it.copy(isLoading = false, awaitingConfirmation = true) }
            } catch (e: Exception) {
                uiState.update { it.copy(isLoading = false, error = e.message) }
            }
        }
    }
}
```

---

### 14. SupportScreen

**iOS equivalent:** `SupportView.swift`

- FAQ accordion (expandable list items with `AnimatedVisibility`)
- Contact form or deep-link to email intent
- Static content, no ViewModel needed

---

## Shared Components

### ToastOverlay

```kotlin
@Composable
fun ToastOverlay(message: String, icon: ImageVector, color: Color, onDismiss: () -> Unit) {
    LaunchedEffect(message) { delay(3000); onDismiss() }

    Box(
        Modifier.fillMaxSize().padding(bottom = 90.dp),
        contentAlignment = Alignment.BottomCenter
    ) {
        Surface(shape = RoundedCornerShape(14.dp), color = Color.Black.copy(alpha = 0.85f),
                shadowElevation = 8.dp) {
            Row(Modifier.padding(horizontal = 16.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                Icon(icon, null, tint = color, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(8.dp))
                Text(message, color = Color.White, style = MaterialTheme.typography.bodyMedium)
            }
        }
    }
}
```

### Cart Fly Animation (CartAnimationManager equivalent)

```kotlin
data class CartParticle(val id: UUID = UUID.randomUUID(), val startOffset: Offset, val icon: ImageVector)

@Composable
fun FlyingCartParticle(particle: CartParticle, targetOffset: Offset, onFinished: () -> Unit) {
    val progress = remember { Animatable(0f) }

    LaunchedEffect(particle.id) {
        progress.animateTo(1f, animationSpec = tween(600, easing = FastOutSlowInEasing))
        onFinished()
    }

    val currentOffset = lerp(particle.startOffset, targetOffset, progress.value)

    Box(Modifier.offset { IntOffset(currentOffset.x.roundToInt(), currentOffset.y.roundToInt()) }
               .alpha(1f - progress.value)) {
        Icon(particle.icon, null, tint = Color(0xFF5856D6), modifier = Modifier.size(28.dp))
    }
}
```

### Shimmer Skeleton

```kotlin
@Composable
fun ShimmerBox(modifier: Modifier = Modifier) {
    val transition = rememberInfiniteTransition(label = "shimmer")
    val alpha by transition.animateFloat(
        initialValue = 0.3f, targetValue = 0.9f,
        animationSpec = infiniteRepeatable(tween(900), RepeatMode.Reverse), label = "alpha"
    )
    Box(modifier.background(MaterialTheme.colorScheme.onSurface.copy(alpha = alpha), RoundedCornerShape(8.dp)))
}
```

### Haptic Feedback

```kotlin
object HapticUtil {
    fun impact(context: Context) {
        val v = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            v.vibrate(VibrationEffect.createOneShot(30, VibrationEffect.DEFAULT_AMPLITUDE))
        }
    }

    fun selection(context: Context) {
        val v = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            v.vibrate(VibrationEffect.createOneShot(15, 50))
        }
    }
}
```

### Promo Code Validation (same SHA-256 logic as iOS)

```kotlin
object PromoService {
    private val VALID_HASHES = setOf(
        "6a3b...hash_of_SAVE10...",
        "9f2c...hash_of_SAVE20...",
        "d4e1...hash_of_WELCOME5...",
        "7ab8...hash_of_FREESHIP..."
    )

    fun validate(code: String): PromoResult {
        val hash = sha256(code.trim().uppercase())
        return when {
            hash == sha256("SAVE10")    -> PromoResult.Percent(0.10)
            hash == sha256("SAVE20")    -> PromoResult.Percent(0.20)
            hash == sha256("WELCOME5")  -> PromoResult.Flat(5.0)
            hash == sha256("FREESHIP")  -> PromoResult.FreeShipping
            else                        -> PromoResult.Invalid
        }
    }

    private fun sha256(input: String): String {
        val bytes = MessageDigest.getInstance("SHA-256").digest(input.toByteArray())
        return bytes.joinToString("") { "%02x".format(it) }
    }
}

sealed class PromoResult {
    data class Percent(val rate: Double) : PromoResult()
    data class Flat(val amount: Double) : PromoResult()
    object FreeShipping : PromoResult()
    object Invalid : PromoResult()
}
```

---

## `AndroidManifest.xml` Required Permissions

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />  <!-- API 33+ -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

<!-- Optional: Camera for QR scanning future feature -->
<!-- <uses-permission android:name="android.permission.CAMERA" /> -->
```

---

## Promo Codes (identical to iOS)

| Code | Discount |
|---|---|
| `SAVE10` | 10% off subtotal |
| `SAVE20` | 20% off subtotal |
| `WELCOME5` | $5 flat off |
| `FREESHIP` | Free shipping |

---

## Constants (`AppConstants.kt`)

```kotlin
object AppConstants {
    object Shipping {
        const val FREE_THRESHOLD = 50.0
        const val STANDARD_COST  = 4.99
    }
    object Loyalty {
        const val POINTS_PER_DOLLAR = 10
        const val GOLD_THRESHOLD    = 1000
    }
    object App {
        const val NAME        = "GeekCommerZ"
        const val VERSION     = "1.0"
        const val PRIVACY_URL = "https://geekcommerz.app/privacy"
        const val TERMS_URL   = "https://geekcommerz.app/terms"
    }
}
```

---

## Third-Party SDK Initialization (`GeekCommerZ.kt`)

```kotlin
@HiltAndroidApp
class GeekCommerZ : Application() {

    override fun onCreate() {
        super.onCreate()

        // Stripe
        if (BuildConfig.STRIPE_KEY.isNotBlank()) {
            PaymentConfiguration.init(applicationContext, BuildConfig.STRIPE_KEY)
        }

        // OneSignal
        if (BuildConfig.ONESIGNAL_APP_ID.isNotBlank()) {
            OneSignal.initWithContext(this, BuildConfig.ONESIGNAL_APP_ID)
        }

        // Sentry
        if (BuildConfig.SENTRY_DSN.isNotBlank()) {
            SentryAndroid.init(this) { options ->
                options.dsn = BuildConfig.SENTRY_DSN
                options.tracesSampleRate = 1.0
            }
        }
    }
}
```

---

## Build Variants

```kotlin
// build.gradle.kts
buildTypes {
    debug {
        applicationIdSuffix = ".debug"
        versionNameSuffix   = "-debug"
        isDebuggable        = true
    }
    release {
        isMinifyEnabled   = true
        isShrinkResources = true
        proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        signingConfig = signingConfigs.getByName("release")
    }
}
```

---

## ProGuard Rules

```proguard
# Supabase / Ktor
-keep class io.ktor.** { *; }
-keep class io.github.jan.tennert.** { *; }

# Kotlinx Serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

# Stripe
-keep class com.stripe.** { *; }

# Sentry
-keep class io.sentry.** { *; }

# Room
-keep class * extends androidx.room.RoomDatabase
-keep @androidx.room.Entity class *
```

---

## Animations Summary

| Feature | iOS | Android |
|---|---|---|
| Cart fly particle | Custom UIKit layer | `Animatable` + `Box` overlay |
| Heart pulse | `.scaleEffect` + spring | `animateFloatAsState` with spring |
| Quantity ticker | `.contentTransition(.numericText())` | `AnimatedContent` with slide |
| Filter spring | `.scaleEffect` spring | `animateFloatAsState` |
| Wishlist exit | `.transition(scale+opacity)` | `AnimatedVisibility(scaleOut+fadeOut)` |
| Skeleton shimmer | Custom shimmer modifier | `InfiniteTransition` alpha |
| Confetti | Custom particle view | Konfetti `KonfettiView` |
| Banner auto-scroll | Timer + `.tabViewStyle(.page)` | `LaunchedEffect` + `PagerState.scrollToPage` |

---

## Testing Plan

### Unit tests (`app/src/test/`)

```kotlin
// CartRepositoryTest.kt
@Test fun `adding same product increments quantity`() = runTest {
    val db = Room.inMemoryDatabaseBuilder(ctx, AppDatabase::class.java).build()
    val repo = CartRepository(db.cartDao())
    repo.add(mockProduct)
    repo.add(mockProduct)
    assertEquals(2, repo.items.first().first().quantity)
}

// PromoServiceTest.kt
@Test fun `SAVE10 returns 10 percent discount`() {
    val result = PromoService.validate("SAVE10")
    assertTrue(result is PromoResult.Percent && result.rate == 0.10)
}
```

### UI tests (`app/src/androidTest/`)

```kotlin
// CartScreenTest.kt
@Test fun `tapping add to cart shows item in cart`() {
    composeTestRule.setContent { GeekCommerZTheme { ShopScreen(navController) } }
    composeTestRule.onNodeWithText("Add to Cart").performClick()
    composeTestRule.onNodeWithContentDescription("Cart badge").assertTextContains("1")
}
```

---

## Roadmap

- [ ] Project scaffold (Hilt + Room + Navigation + Theme)
- [ ] Supabase client + Auth
- [ ] ProductRepository (mock data + Supabase fetch)
- [ ] HomeScreen + SplashScreen + OnboardingScreen
- [ ] ShopScreen + ProductDetailScreen
- [ ] CartScreen + CartManager
- [ ] CheckoutScreen + BiometricPrompt + Konfetti
- [ ] OrdersScreen + OrderDetailScreen
- [ ] WishlistScreen
- [ ] ProfileScreen (auth-aware)
- [ ] NotificationsScreen + badge
- [ ] AuthScreen
- [ ] SearchScreen
- [ ] SupportScreen
- [ ] Cart fly animation
- [ ] Dark mode
- [ ] Stripe payment sheet
- [ ] OneSignal push notifications
- [ ] Sentry crash reporting
- [ ] Cart & wishlist sync to Supabase
- [ ] Orders written to Supabase
- [ ] User profile sync (loyalty points, addresses)
- [ ] Google Pay integration
- [ ] Tablet layout (two-pane)
- [ ] App Widget (cart count + flash sale)

---

## Quick Start

```bash
# Clone and open
git clone https://github.com/siraajul/GeekCommerz.git
cd GeekCommerz

# The iOS app is in geekcommerze/ — create the Android project alongside it
# Open Android Studio → New Project → Empty Activity
# Name: GeekCommerz  Package: com.geekcommerz  Min SDK: API 26

# Run without any API keys — mock product data works offline
# Press ▶ Run in Android Studio
```

**Requirements:** Android Studio Meerkat+ · Android 8.0 (API 26)+ · JDK 17

---

<div align="center">

Same Supabase backend · Same feature set · True native Android

</div>
