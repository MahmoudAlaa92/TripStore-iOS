import Foundation

@MainActor
final class CatalogueViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case error(AppError)
    }

    @Published private(set) var products: [Product] = []
    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var isLoadingMore = false
    @Published private(set) var isShowingStaleData = false

    private let repository: ProductsRepository
    private let pageSize: Int
    private var total = 0

    /// Guards against an in-flight request (base load, refresh, or pagination)
    /// applying its result after a *newer* request has already started —
    /// e.g. the user pulls to refresh while a page-2 fetch is still pending.
    private var currentRequestID = UUID()

    init(repository: ProductsRepository, pageSize: Int = 20) {
        self.repository = repository
        self.pageSize = pageSize
    }

    var isEmpty: Bool { loadState == .loaded && products.isEmpty }

    func loadInitial() async {
        guard loadState == .idle else { return }
        await reload()
    }

    func refresh() async {
        await reload()
    }

    func retry() async {
        await reload()
    }

    private func reload() async {
        let requestID = UUID()
        currentRequestID = requestID
        loadState = .loading

        do {
            let page = try await repository.fetchCatalogue(query: CatalogueQuery(), limit: pageSize, skip: 0)
            guard requestID == currentRequestID else { return }
            products = page.products
            total = page.total
            isShowingStaleData = page.isStale
            loadState = .loaded
        } catch {
            guard requestID == currentRequestID else { return }
            loadState = .error((error as? AppError) ?? .unknown)
        }
    }

    /// Called from each card's `onAppear`; triggers the next page once the
    /// user scrolls within a few rows of the end.
    func loadMoreIfNeeded(currentItem product: Product) async {
        guard let index = products.firstIndex(of: product) else { return }
        let lookAhead = 5
        guard index >= products.count - lookAhead else { return }
        await loadMore()
    }

    private func loadMore() async {
        guard !isLoadingMore, loadState == .loaded, products.count < total else { return }
        let requestID = currentRequestID
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let page = try await repository.fetchCatalogue(query: CatalogueQuery(), limit: pageSize, skip: products.count)
            guard requestID == currentRequestID else { return }
            products += page.products
            total = page.total
        } catch {
            // Pagination failures are non-blocking: the base list stays usable
            // and the user can retry by scrolling again or pulling to refresh.
        }
    }
}
