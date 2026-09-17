import SwiftUI

struct CatalogueView: View {
    @StateObject private var viewModel: CatalogueViewModel

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    init(viewModel: @autoclosure @escaping () -> CatalogueViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("TripStore")
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
                EmptyStateView(
                    systemImage: "bag",
                    title: "No products found",
                    message: "The catalogue is empty right now."
                )
            } else {
                productGrid
            }
        }
    }

    private var productGrid: some View {
        ScrollView {
            if viewModel.isShowingStaleData {
                OfflineBanner()
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.products) { product in
                    ProductCard(product: product)
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
}
