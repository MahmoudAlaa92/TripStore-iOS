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
    @Published private(set) var categories: [String] = []

    @Published var searchText: String = "" {
        didSet {
            guard oldValue != searchText else { return }
            scheduleDebouncedReload()
        }
    }
    @Published private(set) var selectedCategory: String?
    @Published var minRating: Double = 0
    @Published private(set) var sortOption: ProductSortOption = .featured

    private let repository: ProductsRepository
    private let categoriesRepository: CategoriesRepository
    private let networkMonitor: NetworkMonitor?
    private let pageSize: Int
    private let searchDebounceNanoseconds: UInt64
    private var total = 0
    private var searchDebounceTask: Task<Void, Never>?
    private var connectivityObservationTask: Task<Void, Never>?

    /// Guards against an in-flight request (base load, refresh, pagination, or
    /// a search/filter change) applying its result after a *newer* request
    /// has already started — e.g. the user types "b" right after "a" resolves
    /// slower than "ab", or pulls to refresh while a page-2 fetch is pending.
    private var currentRequestID = UUID()

    init(
        repository: ProductsRepository,
        categoriesRepository: CategoriesRepository,
        networkMonitor: NetworkMonitor? = nil,
        pageSize: Int = 20,
        searchDebounceNanoseconds: UInt64 = 300_000_000
    ) {
        self.repository = repository
        self.categoriesRepository = categoriesRepository
        self.networkMonitor = networkMonitor
        self.pageSize = pageSize
        self.searchDebounceNanoseconds = searchDebounceNanoseconds
    }

    deinit {
        connectivityObservationTask?.cancel()
    }

    /// What the grid actually renders: the fetched page with the client-side
    /// minimum-rating filter applied (dummyjson has no server-side support
    /// for it — see ProductRatingFilter).
    var displayedProducts: [Product] {
        ProductRatingFilter.apply(products, minimumRating: minRating)
    }

    var isEmpty: Bool { loadState == .loaded && displayedProducts.isEmpty }

    var hasActiveFilters: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || selectedCategory != nil
            || minRating > 0
            || sortOption != .featured
    }

    /// Falls back to the categories present in the currently loaded page if
    /// the categories endpoint returned nothing (offline, or malformed
    /// response) so the filter sheet is never left without options.
    var availableCategories: [String] {
        categories.isEmpty ? Array(Set(products.map(\.category))).sorted() : categories
    }

    func loadInitial() async {
        observeConnectivityRestoration()
        if categories.isEmpty {
            categories = (try? await categoriesRepository.fetchCategories()) ?? []
        }
        guard loadState == .idle else { return }
        await reload()
    }

    func refresh() async {
        await reload()
    }

    func retry() async {
        await reload()
    }

    func setCategory(_ category: String?) async {
        guard selectedCategory != category else { return }
        selectedCategory = category
        await reload()
    }

    func setSortOption(_ option: ProductSortOption) async {
        guard sortOption != option else { return }
        sortOption = option
        await reload()
    }

    func resetFilters() async {
        searchDebounceTask?.cancel()
        searchText = ""
        selectedCategory = nil
        minRating = 0
        sortOption = .featured
        await reload()
    }

    private func scheduleDebouncedReload() {
        searchDebounceTask?.cancel()
        searchDebounceTask = Task { [weak self, searchDebounceNanoseconds] in
            try? await Task.sleep(nanoseconds: searchDebounceNanoseconds)
            guard !Task.isCancelled else { return }
            await self?.reload()
        }
    }

    /// Starts listening for connectivity coming back once per view model
    /// lifetime. Only reloads when the last attempt actually failed due to
    /// connectivity — a successful load (including one serving stale cached
    /// data) is left alone, so the existing offline/cache behavior is
    /// unaffected and a restored connection can't trigger repeated fetches.
    private func observeConnectivityRestoration() {
        guard connectivityObservationTask == nil, let networkMonitor else { return }
        let stream = networkMonitor.connectivityRestored()
        connectivityObservationTask = Task { [weak self] in
            for await _ in stream {
                guard let self, self.loadState == .error(.connectivity) else { continue }
                await self.reload()
            }
        }
    }

    /// Performs a fresh (skip 0) fetch using the current search/category/sort
    /// state. Internal rather than private so concurrency tests can drive
    /// overlapping calls directly, without depending on debounce timing.
    func reload() async {
        let requestID = UUID()
        currentRequestID = requestID
        loadState = .loading

        do {
            let page = try await repository.fetchCatalogue(query: currentQuery, limit: pageSize, skip: 0)
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
    /// user scrolls within a few rows of the end of what's currently shown.
    func loadMoreIfNeeded(currentItem product: Product) async {
        guard let index = displayedProducts.firstIndex(of: product) else { return }
        let lookAhead = 5
        guard index >= displayedProducts.count - lookAhead else { return }
        await loadMore()
    }

    private func loadMore() async {
        guard !isLoadingMore, loadState == .loaded, products.count < total else { return }
        let requestID = currentRequestID
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let page = try await repository.fetchCatalogue(query: currentQuery, limit: pageSize, skip: products.count)
            guard requestID == currentRequestID else { return }
            products += page.products
            total = page.total
        } catch {
            // Pagination failures are non-blocking: the base list stays usable
            // and the user can retry by scrolling again or pulling to refresh.
        }
    }

    private var currentQuery: CatalogueQuery {
        CatalogueQuery(searchText: searchText, category: selectedCategory, sortOption: sortOption)
    }
}
