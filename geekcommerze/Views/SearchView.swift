import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(ProductStore.self) private var productStore
    @Environment(CartStore.self) private var cartStore
    @AppStorage(AppConstants.StorageKeys.recentSearches) private var recentSearchesData: String = ""
    @State private var searchText: String = ""
    @State private var selectedProduct: Product? = nil
    @State private var resultsCategory: ProductCategory? = nil
    @FocusState private var isSearchFocused: Bool

    static let trendingSearches = ["Wireless Headphones", "Running Shoes", "Coffee Maker", "Yoga Mat", "Mechanical Keyboard"]

    // MARK: - Computed Properties

    /// Decodes the @AppStorage pipe-delimited string into a reversed array of recent query strings shown in SearchView.
    var recentSearches: [String] {
        recentSearchesData.components(separatedBy: "|||").filter { !$0.isEmpty }.reversed()
    }

    /// Full product list matching the current search text with no category filter applied; used to derive resultCategories.
    var allSearchResults: [Product] {
        let q = searchText.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }
        return productStore.filtered(search: q, category: nil)
    }

    /// Category-filtered subset of allSearchResults; bound to the active FilterChip selection in SearchView.
    var searchResults: [Product] {
        guard let cat = resultsCategory else { return allSearchResults }
        return allSearchResults.filter { $0.category == cat }
    }

    /// Unique, sorted categories present in allSearchResults; used to build the horizontal filter chip row in SearchView.
    var resultCategories: [ProductCategory] {
        Array(Set(allSearchResults.map { $0.category })).sorted { $0.rawValue < $1.rawValue }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                Divider()
                Group {
                    if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                        recentAndCategoriesView
                    } else if allSearchResults.isEmpty {
                        noResultsView
                    } else {
                        resultsView
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .onChange(of: searchText) { resultsCategory = nil }
            .sheet(item: $selectedProduct) { product in
                ProductDetailView(product: product)
            }
        }
    }

    // MARK: - Search Bar

    /// Styled text field with leading icon and trailing clear button pinned below the nav bar in SearchView.
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search products, categories...", text: $searchText)
                .autocorrectionDisabled()
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit { saveSearch(searchText) }
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Idle State

    /// Default scroll content shown in SearchView when the search field is empty; contains recent history, trending chips, and category cards.
    private var recentAndCategoriesView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if !recentSearches.isEmpty {
                    HStack {
                        Text("Recent")
                            .font(AppTheme.Typography.sectionHeader)
                        Spacer()
                        Button("Clear All") { recentSearchesData = "" }
                            .font(.subheadline)
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                    ForEach(recentSearches, id: \.self) { query in
                        Button {
                            searchText = query
                        } label: {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(.secondary)
                                    .frame(width: 24)
                                Text(query)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "arrow.up.left")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 11)
                        }
                        Divider().padding(.leading, 52)
                    }
                    Divider().padding(.top, 8)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Trending")
                        .font(AppTheme.Typography.sectionHeader)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(SearchView.trendingSearches, id: \.self) { term in
                                Button {
                                    searchText = term
                                    saveSearch(term)
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.up.right")
                                            .font(.caption2)
                                        Text(term)
                                            .font(.subheadline)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemBackground))
                                    .foregroundColor(.primary)
                                    .clipShape(Capsule())
                                    .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Browse Categories")
                        .font(AppTheme.Typography.sectionHeader)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(ProductCategory.allCases, id: \.self) { cat in
                            Button {
                                searchText = cat.rawValue
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: cat.icon)
                                        .font(.title3)
                                        .foregroundColor(AppTheme.Colors.primary)
                                        .frame(width: 36, height: 36)
                                        .background(AppTheme.Brand.tint)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    Text(cat.rawValue)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
        }
    }

    // MARK: - No Results State

    /// Full-screen placeholder shown in SearchView when a query returns zero products from ProductStore.
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 52))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No results for \"\(searchText)\"")
                .font(.headline)
            Text("Try checking your spelling or use more general terms.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 60)
    }

    // MARK: - Results

    /// Two-column product grid with a category filter chip row shown in SearchView when the query has matches.
    private var resultsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if resultCategories.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(title: "All (\(allSearchResults.count))", isSelected: resultsCategory == nil) {
                                resultsCategory = nil
                            }
                            ForEach(resultCategories, id: \.self) { cat in
                                let count = allSearchResults.filter { $0.category == cat }.count
                                FilterChip(title: "\(cat.rawValue) (\(count))", isSelected: resultsCategory == cat) {
                                    resultsCategory = resultsCategory == cat ? nil : cat
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 8)
                }

                Text("\(searchResults.count) result\(searchResults.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(searchResults) { product in
                        ProductCard(product: product)
                            .onTapGesture {
                                saveSearch(searchText)
                                selectedProduct = product
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Actions

    /// Appends a query to the @AppStorage recent-searches string (capped at 8, deduped); called on submit and on product tap in SearchView.
    private func saveSearch(_ query: String) {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        var searches = recentSearchesData.components(separatedBy: "|||").filter { !$0.isEmpty }
        searches.removeAll { $0.lowercased() == q.lowercased() }
        searches.append(q)
        if searches.count > 8 { searches = Array(searches.suffix(8)) }
        recentSearchesData = searches.joined(separator: "|||")
    }
}

#Preview {
    SearchView()
        .environment(ProductStore())
        .environment(CartStore())
        .modelContainer(for: [CartItem.self, Order.self, OrderItem.self], inMemory: true)
}
