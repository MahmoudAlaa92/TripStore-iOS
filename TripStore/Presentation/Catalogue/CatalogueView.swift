import SwiftUI

struct CatalogueView: View {
    @StateObject private var viewModel: CatalogueViewModel
    @EnvironmentObject private var favoritesStore: FavoritesStore
    @State private var isShowingFilters = false

    private let ordersRepository: OrdersRepository
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    init(viewModel: @autoclosure @escaping () -> CatalogueViewModel, ordersRepository: OrdersRepository) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.ordersRepository = ordersRepository
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchAndFilterBar
                categoryChipsRow
                content
            }
            .navigationTitle("TripStore")
            .sheet(isPresented: $isShowingFilters) {
                FilterSheet(viewModel: viewModel)
            }
            .navigationDestination(for: Product.self) { product in
                ProductDetailsView(product: product)
            }
            .navigationDestination(for: OrderDraft.self) { draft in
                OrderConfirmationView(draft: draft, ordersRepository: ordersRepository)
            }
            .task { await viewModel.loadInitial() }
        }
    }

    private var searchAndFilterBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search products", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .submitLabel(.search)
                    .accessibilityLabel("Search products")
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            Button {
                isShowingFilters = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.body.weight(.medium))
                    .foregroundStyle(viewModel.hasActiveFilters ? Color.white : Color.accentColor)
                    .padding(10)
                    .background(
                        viewModel.hasActiveFilters ? Color.accentColor : Color(.secondarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
            }
            .accessibilityLabel("Filter and sort")
            .accessibilityHint(viewModel.hasActiveFilters ? "Filters are active" : "No filters active")
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var categoryChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(title: "All", isSelected: viewModel.selectedCategory == nil) {
                    Task { await viewModel.setCategory(nil) }
                }
                ForEach(viewModel.availableCategories, id: \.self) { category in
                    categoryChip(title: category.capitalized, isSelected: viewModel.selectedCategory == category) {
                        Task { await viewModel.setCategory(category) }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 8)
    }

    private func categoryChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground), in: Capsule())
                .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle:
            LoadingView()

        case .loading:
            if viewModel.products.isEmpty {
                LoadingView()
            } else {
                productGrid
            }

        case .error(let appError):
            if viewModel.products.isEmpty {
                ErrorStateView(
                    message: appError.userMessage,
                    retryAction: { Task { await viewModel.retry() } }
                )
            } else {
                productGrid
            }

        case .loaded:
            if viewModel.isEmpty {
                emptyState
            } else {
                productGrid
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if viewModel.hasActiveFilters {
            EmptyStateView(
                systemImage: "magnifyingglass",
                title: "No matches",
                message: "No products match your search and filters.",
                actionTitle: "Reset filters",
                action: { Task { await viewModel.resetFilters() } }
            )
        } else {
            EmptyStateView(
                systemImage: "bag",
                title: "No products found",
                message: "The catalogue is empty right now."
            )
        }
    }

    private var productGrid: some View {
        ScrollView {
            if viewModel.isShowingStaleData {
                OfflineBanner()
            }

            if viewModel.hasActiveFilters {
                activeFiltersBar
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.displayedProducts) { product in
                    ZStack(alignment: .topTrailing) {
                        NavigationLink(value: product) {
                            ProductCard(product: product)
                        }
                        .buttonStyle(.plain)

                        // Kept as a sibling of the NavigationLink (not nested
                        // inside its label) — a Button nested in a
                        // NavigationLink's label can end up triggering both
                        // the button action and the navigation from a single
                        // tap, which would favorite *and* navigate at once.
                        FavoriteButton(
                            isFavorite: favoritesStore.isFavorite(product.id),
                            action: { Task { await favoritesStore.toggle(product) } }
                        )
                        .padding(6)
                        .background(.ultraThinMaterial, in: Circle())
                        .padding(16)
                    }
                    .onAppear {
                        Task { await viewModel.loadMoreIfNeeded(currentItem: product) }
                    }
                }
            }
            .padding(12)

            if viewModel.isLoadingMore {
                ProgressView()
                    .padding(.bottom, 16)
            }
        }
        .refreshable { await viewModel.refresh() }
    }

    private var activeFiltersBar: some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease.circle")
            Text("Filters active")
                .font(.footnote.weight(.medium))
            Spacer()
            Button("Reset") { Task { await viewModel.resetFilters() } }
                .font(.footnote.weight(.semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .foregroundStyle(Color.accentColor)
        .accessibilityElement(children: .combine)
    }
}
