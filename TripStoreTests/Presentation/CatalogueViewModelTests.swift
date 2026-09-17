import XCTest
@testable import TripStore

@MainActor
final class CatalogueViewModelTests: XCTestCase {

    func test_loadInitial_success_transitionsToLoaded() async {
        let repository = MockProductsRepository()
        await repository.setResponseProvider { _, _, _ in
            CataloguePage(products: [TestFixtures.product(id: 1)], total: 1, skip: 0, limit: 20, isStale: false)
        }
        let viewModel = CatalogueViewModel(repository: repository, categoriesRepository: MockCategoriesRepository())

        XCTAssertEqual(viewModel.loadState, .idle)
        await viewModel.loadInitial()

        XCTAssertEqual(viewModel.loadState, .loaded)
        XCTAssertEqual(viewModel.products.count, 1)
    }

    func test_loadInitial_emptyResult_reportsEmpty() async {
        let repository = MockProductsRepository()
        await repository.setResponseProvider { _, _, _ in .empty }
        let viewModel = CatalogueViewModel(repository: repository, categoriesRepository: MockCategoriesRepository())

        await viewModel.loadInitial()

        XCTAssertEqual(viewModel.loadState, .loaded)
        XCTAssertTrue(viewModel.isEmpty)
    }

    func test_loadInitial_failure_transitionsToError() async {
        let repository = MockProductsRepository()
        await repository.setResponseProvider { _, _, _ in throw AppError.connectivity }
        let viewModel = CatalogueViewModel(repository: repository, categoriesRepository: MockCategoriesRepository())

        await viewModel.loadInitial()

        XCTAssertEqual(viewModel.loadState, .error(.connectivity))
    }

    func test_minRatingFilter_hidesLowRatedProductsWithoutRefetching() async {
        let repository = MockProductsRepository()
        await repository.setResponseProvider { _, _, _ in
            CataloguePage(
                products: [TestFixtures.product(id: 1, rating: 2.0), TestFixtures.product(id: 2, rating: 4.8)],
                total: 2, skip: 0, limit: 20, isStale: false
            )
        }
        let viewModel = CatalogueViewModel(repository: repository, categoriesRepository: MockCategoriesRepository())
        await viewModel.loadInitial()

        viewModel.minRating = 4.0

        XCTAssertEqual(viewModel.displayedProducts.map(\.id), [2])
        let queryCount = await repository.receivedQueries.count
        XCTAssertEqual(queryCount, 1, "Rating filtering is client-side and must not trigger a new fetch")
    }

    func test_setCategory_refetchesAndMarksFiltersActive() async {
        let repository = MockProductsRepository()
        await repository.setResponseProvider { query, _, _ in
            CataloguePage(products: [TestFixtures.product(id: 1, category: query.category ?? "none")], total: 1, skip: 0, limit: 20, isStale: false)
        }
        let viewModel = CatalogueViewModel(repository: repository, categoriesRepository: MockCategoriesRepository())
        await viewModel.loadInitial()

        await viewModel.setCategory("beauty")

        XCTAssertTrue(viewModel.hasActiveFilters)
        XCTAssertEqual(viewModel.products.first?.category, "beauty")
        let queryCount = await repository.receivedQueries.count
        XCTAssertEqual(queryCount, 2)
    }

    func test_setSortOption_sendsCorrespondingSortAndOrderToRepository() async {
        let repository = MockProductsRepository()
        await repository.setResponseProvider { _, _, _ in .empty }
        let viewModel = CatalogueViewModel(repository: repository, categoriesRepository: MockCategoriesRepository())
        await viewModel.loadInitial()

        await viewModel.setSortOption(.priceDescending)

        let queries = await repository.receivedQueries
        XCTAssertEqual(queries.last?.sortOption, .priceDescending)
        XCTAssertTrue(viewModel.hasActiveFilters)
    }

    /// Verifies the transient `.loading` state is actually observable, not
    /// just skipped over between idle and loaded.
    func test_loadInitial_setsLoadingStateWhileRequestIsInFlight() async {
        let repository = MockProductsRepository()
        await repository.setResponseProvider { _, _, _ in
            try await Task.sleep(nanoseconds: 50_000_000)
            return .empty
        }
        let viewModel = CatalogueViewModel(repository: repository, categoriesRepository: MockCategoriesRepository())

        let loadTask = Task { await viewModel.loadInitial() }
        try? await Task.sleep(nanoseconds: 10_000_000)

        XCTAssertEqual(viewModel.loadState, .loading)
        await loadTask.value
        XCTAssertEqual(viewModel.loadState, .loaded)
    }

    func test_resetFilters_clearsAllStateAndReloads() async {
        let repository = MockProductsRepository()
        await repository.setResponseProvider { _, _, _ in
            CataloguePage(products: [TestFixtures.product()], total: 1, skip: 0, limit: 20, isStale: false)
        }
        let viewModel = CatalogueViewModel(repository: repository, categoriesRepository: MockCategoriesRepository())
        await viewModel.loadInitial()
        await viewModel.setCategory("beauty")
        viewModel.minRating = 4.0

        await viewModel.resetFilters()

        XCTAssertFalse(viewModel.hasActiveFilters)
        XCTAssertEqual(viewModel.minRating, 0)
    }
}
