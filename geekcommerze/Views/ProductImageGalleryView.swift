import SwiftUI

/// Full-screen image viewer opened by tapping the hero image in ProductDetailView.
/// Supports pinch-to-zoom (up to 5×), drag-when-zoomed, and double-tap to toggle zoom.
struct ProductImageGalleryView: View {
    let product: Product
    @Environment(\.dismiss) private var dismiss

    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    @State private var dragOffset: CGSize = .zero
    @State private var lastDragOffset: CGSize = .zero

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                galleryImage
                if zoomScale <= 1.0 { productInfoOverlay }
                if zoomScale > 1.0 { resetHint }
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: "Check out \(product.name) for $\(String(format: "%.2f", product.price)) on GeekCommerz!") {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(Color.black.opacity(0.7), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Gallery Image

    /// Large product image with combined magnification, drag, and double-tap gestures.
    private var galleryImage: some View {
        Image(systemName: product.imageName)
            .font(.system(size: 180))
            .foregroundStyle(
                LinearGradient(
                    colors: [AppTheme.Colors.primary, AppTheme.Colors.accent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scaleEffect(zoomScale)
            .offset(dragOffset)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        zoomScale = max(1.0, min(5.0, lastZoomScale * value))
                    }
                    .onEnded { _ in
                        lastZoomScale = zoomScale
                        if zoomScale < 1.2 {
                            withAnimation(.spring(response: 0.3)) {
                                zoomScale = 1.0; lastZoomScale = 1.0
                                dragOffset = .zero; lastDragOffset = .zero
                            }
                        }
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        guard zoomScale > 1.0 else { return }
                        dragOffset = CGSize(
                            width: lastDragOffset.width + value.translation.width,
                            height: lastDragOffset.height + value.translation.height
                        )
                    }
                    .onEnded { _ in lastDragOffset = dragOffset }
            )
            .onTapGesture(count: 2) {
                withAnimation(.spring(response: 0.3)) {
                    if zoomScale > 1.0 {
                        zoomScale = 1.0; lastZoomScale = 1.0
                        dragOffset = .zero; lastDragOffset = .zero
                    } else {
                        zoomScale = 2.5; lastZoomScale = 2.5
                    }
                }
            }
    }

    // MARK: - Overlays

    /// Gradient footer overlay showing product name and price when not zoomed.
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
                LinearGradient(colors: [.clear, .black.opacity(0.65)],
                               startPoint: .top, endPoint: .bottom)
            )
        }
    }

    /// Hint capsule visible only while zoomed, reminding the user they can double-tap to reset.
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
