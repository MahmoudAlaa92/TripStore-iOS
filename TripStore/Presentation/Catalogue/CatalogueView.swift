import SwiftUI

struct CatalogueView: View {
    @StateObject private var viewModel: CatalogueViewModel
    @EnvironmentObject private var favoritesStore: FavoritesStore
    @State private var isShowingFilters = false

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    init(viewModel: @autoclosure @escaping () -> CatalogueViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("TripStore")
                .searchable(text: $viewModel.searchText, prompt: "Search products")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isShowingFilters = true
                        } label: {
                            Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        }
                        .accessibilityLabel("Filter and sort")
                        .accessibilityHint(viewModel.hasActiveFilters ? "Filters are active" : "No filters active")
                    }
                }
                .sheet(isPresented: $isShowingFilters) {
                    FilterSheet(viewModel: viewModel)
                }
                .navigationDestination(for: Product.self) { product in
                    ProductDetailsView(product: product)
                }
                .task { await viewModel.loadInitial() }
        }
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
