import XCTest
@testable import TripStore

@MainActor
final class CatalogueViewModelConcurrencyTests: XCTestCase {

    /// The critical requirement: if search A starts and search B starts
    /// afterwards, a late response from A must never overwrite B's result —
    /// even when A happens to resolve *after* B because of network timing.
    func test_obsoleteSlowerSearchResponse_doesNotReplaceNewerResult() async {
        let repository = MockProductsRepository()
        await repository.setResponseProvider { query, _, _ in
            if query.searchText == "slow" {
                try await Task.sleep(nanoseconds: 150_000_000)
                return CataloguePage(products: [TestFixtures.product(id: 1, title: "Slow Result")], total: 1, skip: 0, limit: 20, isStale: false)
            } else {
                try await Task.sleep(nanoseconds: 10_000_000)
                return CataloguePage(products: [TestFixtures.product(id: 2, title: "Fast Result")], total: 1, skip: 0, limit: 20, isStale: false)
            }
        }

        // A large debounce keeps the automatic didSet-triggered reload from
        // firing during the test; the two `reload()` calls below are driven
        // directly so their timing is fully controlled.
        let viewModel = CatalogueViewModel(
            repository: repository,
            categoriesRepository: MockCategoriesRepository(),
            searchDebounceNanoseconds: 10_000_000_000
        )

        viewModel.searchText = "slow"
        let slowRequest = Task { await viewModel.reload() }

        try? await Task.sleep(nanoseconds: 30_000_000)

        viewModel.searchText = "fast"
        let fastRequest = Task { await viewModel.reload() }

        await fastRequest.value
        await slowRequest.value

        XCTAssertEqual(viewModel.products.map(\.title), ["Fast Result"])
        XCTAssertEqual(viewModel.loadState, .loaded)
    }

    /// Rapid typing must not fire a request per keystroke: only the last
    /// value after the debounce window should ever reach the repository.
    func test_rapidTyping_onlyTriggersOneRequest() async {
        let repository = MockProductsRepository()
        await repository.setResponseProvider { _, _, _ in
            CataloguePage(products: [TestFixtures.product()], total: 1, skip: 0, limit: 20, isStale: false)
        }

        let viewModel = CatalogueViewModel(
            repository: repository,
            categoriesRepository: MockCategoriesRepository(),
            searchDebounceNanoseconds: 50_000_000
        )

        for character in "trip" {
            viewModel.searchText.append(character)
            try? await Task.sleep(nanoseconds: 5_000_000)
        }

        try? await Task.sleep(nanoseconds: 150_000_000)

        let queries = await repository.receivedQueries
        XCTAssertEqual(queries.count, 1)
        XCTAssertEqual(queries.first?.searchText, "trip")
    }
}
