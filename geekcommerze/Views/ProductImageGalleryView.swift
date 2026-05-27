import SwiftUI

/// Full-screen multi-slide image gallery opened from ProductDetailView's expand button.
/// Shows 4 styled "views" of the product in a swipeable carousel with pinch-to-zoom per slide.
struct ProductImageGalleryView: View {
    let product: Product
    @Environment(\.dismiss) private var dismiss

    @State private var currentPage = 0
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    @State private var dragOffset: CGSize = .zero
    @State private var lastDragOffset: CGSize = .zero

    // MARK: - Slide Data

    private struct Slide {
        let label: String
        let background: Color
        let iconScale: CGFloat
        let useGradient: Bool
        let solidTint: Color
    }

    private var slides: [Slide] {[
        Slide(label: "Product",   background: Color(white: 0.07),                          iconScale: 1.0,  useGradient: true,  solidTint: .white),
        Slide(label: "Close-up",  background: Color(red: 0.06, green: 0.06, blue: 0.18),   iconScale: 1.55, useGradient: true,  solidTint: .white),
        Slide(label: "Studio",    background: Color(white: 0.95),                          iconScale: 1.0,  useGradient: false, solidTint: Color(white: 0.25)),
        Slide(label: "Lifestyle", background: Color(red: 0.07, green: 0.10, blue: 0.18),   iconScale: 0.88, useGradient: false, solidTint: AppTheme.Colors.accent),
    ]}

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                slides[currentPage].background
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.35), value: currentPage)

                carousel
                if zoomScale <= 1.0 { pageIndicator }
                if zoomScale <= 1.0 { productInfoOverlay }
                if zoomScale > 1.0  { resetHint }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .accessibilityLabel("Close gallery")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(currentPage + 1) / \(slides.count)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: "Check out \(product.name) for $\(String(format: "%.2f", product.price)) on GeekCommerz!") {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(Color.black.opacity(0.5), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Carousel

    /// Swipeable TabView of product slides. Resets zoom state on page change.
    private var carousel: some View {
        TabView(selection: $currentPage) {
            ForEach(slides.indices, id: \.self) { index in
                slideImage(slides[index])
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .onChange(of: currentPage) { _, _ in
            withAnimation(.spring(response: 0.3)) {
                zoomScale = 1.0;     lastZoomScale = 1.0
                dragOffset = .zero;  lastDragOffset = .zero
            }
        }
    }

    /// Single slide image with zoom, drag, and double-tap gestures.
    private func slideImage(_ slide: Slide) -> some View {
        Image(systemName: product.imageName)
            .font(.system(size: 170 * slide.iconScale))
            .foregroundStyle(
                slide.useGradient
                    ? AnyShapeStyle(LinearGradient(
                            colors: [AppTheme.Colors.primary, AppTheme.Colors.accent],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                    : AnyShapeStyle(slide.solidTint)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scaleEffect(zoomScale)
            .offset(dragOffset)
            .gesture(
                MagnificationGesture()
                    .onChanged { v in zoomScale = max(1.0, min(5.0, lastZoomScale * v)) }
                    .onEnded { _ in
                        lastZoomScale = zoomScale
                        if zoomScale < 1.2 {
                            withAnimation(.spring(response: 0.3)) {
                                zoomScale = 1.0;     lastZoomScale = 1.0
                                dragOffset = .zero;  lastDragOffset = .zero
                            }
                        }
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { v in
                        guard zoomScale > 1.0 else { return }
                        dragOffset = CGSize(
                            width:  lastDragOffset.width  + v.translation.width,
                            height: lastDragOffset.height + v.translation.height
                        )
                    }
                    .onEnded { _ in lastDragOffset = dragOffset }
            )
            .onTapGesture(count: 2) {
                withAnimation(.spring(response: 0.3)) {
                    if zoomScale > 1.0 {
                        zoomScale = 1.0;     lastZoomScale = 1.0
                        dragOffset = .zero;  lastDragOffset = .zero
                    } else {
                        zoomScale = 2.5;     lastZoomScale = 2.5
                    }
                }
            }
    }

    // MARK: - Overlays

    /// Animated page-dot indicator at the top, showing which slide is active.
    private var pageIndicator: some View {
        VStack {
            HStack(spacing: 6) {
                ForEach(slides.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == currentPage ? Color.white : Color.white.opacity(0.35))
                        .frame(width: i == currentPage ? 22 : 6, height: 6)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                }
            }
            .padding(.top, 12)

            HStack(spacing: 12) {
                ForEach(slides.indices, id: \.self) { i in
                    Text(slides[i].label)
                        .font(.system(size: 10, weight: i == currentPage ? .bold : .regular))
                        .foregroundColor(i == currentPage ? .white : .white.opacity(0.4))
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }
            .padding(.top, 4)

            Spacer()
        }
    }

    /// Gradient footer with product name and price, hidden while zoomed.
    private var productInfoOverlay: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Text("$\(product.price, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                LinearGradient(colors: [.clear, .black.opacity(0.7)],
                               startPoint: .top, endPoint: .bottom)
            )
        }
    }

    /// Double-tap hint shown only while the image is zoomed.
    private var resetHint: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text("Double-tap to reset")
                    .font(.caption2)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(.black.opacity(0.5))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .padding(20)
            }
        }
    }
}
