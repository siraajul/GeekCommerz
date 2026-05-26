<div align="center">

# 🛍️ GeekCommerz

**A production-grade iOS e-commerce app built entirely with SwiftUI & SwiftData**

[![Swift](https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-0071E3?logo=apple&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![iOS](https://img.shields.io/badge/iOS-17%2B-000000?logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Xcode](https://img.shields.io/badge/Xcode-16-147EFB?logo=xcode&logoColor=white)](https://developer.apple.com/xcode/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

*Shop smarter. Earn rewards. Track everything.*

</div>

---

## 📱 Overview

GeekCommerz is a fully-featured iOS shopping app that demonstrates real-world production patterns — offline persistence, biometric checkout, loyalty rewards, live order tracking, and more — all built with first-party Apple frameworks and **zero third-party dependencies**.

---

## ✨ Feature Highlights

### 🏠 Home
- Animated promotional banners with auto-scroll and manual swipe
- Category quick-links with SF Symbol icons
- Flash sale countdown timer with live updates
- Recently viewed products (persisted across launches)
- Featured & new arrivals sections
- Tappable flash sale banner → jumps to filtered shop
- Skeleton loading placeholders during initial load
- Promo popup on cold app launch (once per session only)

### 🔍 Search
- Real-time search across all products
- Trending search chips
- Recent search history (max 8, persisted)
- Per-category filter chips on results
- Browse by category grid

### 🛒 Shop
- 2-column product grid with badges (BESTSELLER · HOT DEAL · LIMITED)
- Sort: Featured, Price ↑↓, Top Rated, A–Z
- Filter: In Stock, Has Discount
- Active filter chips with one-tap clear
- Pull-to-refresh
- Long-press context menu (Add to Cart · Wishlist · Share)

### 📦 Product Detail
- Pinch-to-zoom image (1× → 3×, double-tap to reset)
- Color & size variant picker
- Social proof ("14 viewing now · 37 sold today")
- 30-day price sparkline chart (Charts framework)
- Description / Details / Reviews tab picker
- Verified customer reviews with star breakdown
- Frequently Bought Together (deterministic, per-product)
- Related products carousel
- Back-in-stock notification request

### 🛒 Cart
- Swipe-left → save to Wishlist
- Swipe-right → remove
- Live subtotal, shipping threshold ($50 free shipping), grand total
- Instant quantity stepper

### 💳 Checkout
- Saved address picker (auto-fills form)
- Promo codes: `SAVE10` · `SAVE20` · `WELCOME5` · `FREESHIP`
- Three payment methods (Card · Cash on Delivery · Mobile Banking)
- Face ID / Touch ID biometric confirmation
- Apple Pay button (demo mode)
- Loyalty points earned preview
- Order confirmation with confetti animation
- In-app notification triggered on order placement

### 📋 Orders
- Full order history sorted by date (SwiftData)
- Order status timeline (Pending → Processing → Shipped → Delivered)
- Reorder button (re-adds all available items to cart)
- Return request flow for delivered orders (6 reason categories)

### ❤️ Wishlist
- Heart toggle from any screen
- Remove by tapping the filled heart
- Empty state CTA → Browse Products

### 👤 Profile
- Avatar with initials
- Shopping stats (order count · total spent · deliveries)
- Loyalty rewards (Silver → Gold at 1,000 pts, progress bar)
- Saved address book (add · delete)
- Dark mode toggle
- Push notification toggle
- App version, Privacy Policy, Terms links

### 🔔 Notifications
- In-app notification center (bell icon, red badge)
- Today / Earlier sections
- Swipe-left mark-as-read, swipe-right delete
- "Mark All Read" toolbar action
- Persisted to UserDefaults (survives app restarts)
- Seeded with 3 sample notifications on first launch

### 🎬 Onboarding
- 3-page tab-based flow shown on first launch only
- Skip or page-through at any time

---

## 🏗️ Architecture

```
GeekCommerz
├── @Observable stores (ProductStore, CartStore, ToastManager, NotificationStore)
├── SwiftData persistence (CartItem, Order, OrderItem)
├── AppStorage for user preferences & lightweight state
└── Pure SwiftUI view hierarchy — no UIKit, no Combine
```

### Data Flow

```
User Action
    │
    ▼
SwiftUI View  ──▶  @Observable Store  ──▶  SwiftData / UserDefaults
    ▲                                              │
    └──────────────── @Query / @AppStorage ◀───────┘
```

### Key Design Decisions

| Decision | Rationale |
|---|---|
| `@Observable` over `ObservableObject` | Finer-grained observation, less boilerplate |
| SwiftData over Core Data | Native Swift syntax, automatic schema migration |
| `@AppStorage` for lightweight state | Avoids SwiftData overhead for single-value flags |
| LCG for "Frequently Bought Together" | Deterministic per-product, zero API calls |
| `scenePhase` for promo popup | Fires only on cold launch, not tab switches |

---

## 📁 Project Structure

```
geekcommerze/
├── geekcommerze/                  # App target sources
│   ├── geekcommerzeApp.swift      # App entry, onboarding gate, colour scheme
│   ├── ContentView.swift          # Root tab bar, toast overlay, promo popup
│   ├── AppConstants.swift         # All string keys, thresholds, promo codes
│   ├── ToastManager.swift         # Global toast + HapticFeedback utility
│   ├── NotificationStore.swift    # In-app notification persistence
│   │
│   ├── Models/
│   │   ├── Product.swift          # Product, ProductCategory, ProductStore seed
│   │   ├── CartItem.swift         # SwiftData model
│   │   └── Order.swift            # Order + OrderItem SwiftData models
│   │
│   ├── Stores/
│   │   ├── CartStore.swift        # Cart state & SwiftData mutations
│   │   └── ProductStore.swift     # In-memory product catalogue
│   │
│   └── Views/
│       ├── HomeView.swift         # Home feed, banners, recently viewed
│       ├── ShopView.swift         # Grid, sort/filter, ProductCard
│       ├── SearchView.swift       # Search, trending, category browse
│       ├── CartView.swift         # Cart list, swipe actions, summary
│       ├── CheckoutView.swift     # Multi-step checkout, biometric, confetti
│       ├── ProductDetailView.swift# Detail, zoom, variants, charts, reviews
│       ├── OrdersView.swift       # Order history, timeline, returns
│       ├── WishlistView.swift     # Saved products grid
│       ├── ProfileView.swift      # User stats, addresses, settings
│       ├── NotificationsView.swift# Notification centre + BellBadgeIcon
│       ├── OnboardingView.swift   # First-launch walkthrough
│       ├── SkeletonView.swift     # Shimmer loading cards
│       └── ConfettiView.swift     # Order success animation
│
├── geekcommerzeTests/             # Unit tests (Testing framework)
├── geekcommerzeUITests/           # UI tests (XCUIAutomation)
└── geekcommerze.xcodeproj
```

---

## 🚀 Getting Started

### Requirements

| Tool | Version |
|---|---|
| Xcode | 16.0 + |
| iOS Deployment Target | 17.0 + |
| Swift | 5.9 + |
| macOS (for dev) | Sonoma 14+ |

### Setup

```bash
# Clone the repo
git clone https://github.com/your-username/geekcommerze.git
cd geekcommerze

# Open in Xcode (no package dependencies to resolve)
open geekcommerze.xcodeproj
```

1. Select your target device or simulator (iPhone 15 / iOS 17+ recommended)
2. Press **⌘R** to build and run
3. No API keys, no backend, no configuration required — everything runs offline

---

## 🧪 Testing

```bash
# Run unit tests
⌘U  (or Product → Test in Xcode)
```

Unit tests live in `geekcommerzeTests/` using Swift's **Testing** framework.  
UI tests live in `geekcommerzeUITests/` using **XCUIAutomation**.

---

## 🔑 Promo Codes

| Code | Effect |
|---|---|
| `SAVE10` | 10% off subtotal |
| `SAVE20` | 20% off subtotal |
| `WELCOME5` | $5 flat discount |
| `FREESHIP` | Free shipping |

---

## 📐 Constants Reference

All magic values live in `AppConstants.swift`:

```swift
AppConstants.StorageKeys.*   // UserDefaults / @AppStorage keys
AppConstants.Loyalty.*       // Points per dollar, Gold threshold
AppConstants.Shipping.*      // Free threshold ($50), standard cost ($4.99)
AppConstants.PromoCodes.*    // Valid promo code strings
AppConstants.App.*           // Name, version, privacy/terms URLs
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI 5 |
| Persistence | SwiftData |
| Lightweight state | `@AppStorage` (UserDefaults) |
| Charts | Swift Charts (Apple) |
| Biometrics | LocalAuthentication |
| Haptics | UIImpactFeedbackGenerator |
| Async/Await | Swift Concurrency |
| Architecture | `@Observable` (Observation framework) |
| Testing | Swift Testing + XCUIAutomation |

**Zero third-party dependencies.**

---

## 🗺️ Roadmap

- [ ] Real backend integration (REST / GraphQL)
- [ ] Push notification support (APNs)
- [ ] Product image support (AsyncImage from CDN)
- [ ] Apple Pay live integration
- [ ] iPad layout optimisation
- [ ] Widget extension (recently viewed / cart badge)
- [ ] App Clip for quick checkout

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m "Add your feature"`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a Pull Request

Please keep PRs focused — one feature or fix per PR.

---

## 📄 License

```
MIT License

Copyright (c) 2026 GeekCommerz

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
```

---

<div align="center">

Built with ❤️ using Swift & SwiftUI · No third-party dependencies · Runs entirely on-device

</div>
