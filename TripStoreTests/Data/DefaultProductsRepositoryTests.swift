import XCTest
@testable import TripStore

final class DefaultProductsRepositoryTests: XCTestCase {
    private let sampleJSON = """
    {
        "products": [
            { "id": 1, "title": "Travel Pillow", "description": "Soft", "category": "accessories", "price": 19.99, "rating": 4.2, "stock": 10, "thumbnail": "https://example.com/1.jpg", "images": [] }
        ],
        "total": 1,
        "skip": 0,
        "limit": 20
    }
    """.data(using: .utf8)!

    func test_successfulPlainFetch_savesToCache() async throws {
        let apiClient = MockAPIClient()
        apiClient.dataProvider = { _ in self.sampleJSON }
        let cache = InMemoryCatalogueCache()
        let repository = DefaultProductsRepository(apiClient: apiClient, cache: cache)

        let page = try await repository.fetchCatalogue(query: CatalogueQuery(), limit: 20, skip: 0)

        XCTAssertEqual(page.products.count, 1)
        XCTAssertFalse(page.isStale)
        XCTAssertNotNil(cache.load(), "the plain first page should have been cached")
    }

    func test_connectivityFailureWithCache_returnsStaleCachedPage() async throws {
        let apiClient = MockAPIClient()
        let cache = InMemoryCatalogueCache()
        cache.save(CataloguePage(products: [TestFixtures.product(id: 9)], total: 1, skip: 0, limit: 20, isStale: false))
        apiClient.dataProvider = { _ in throw AppError.connectivity }
        let repository = DefaultProductsRepository(apiClient: apiClient, cache: cache)

        let page = try await repository.fetchCatalogue(query: CatalogueQuery(), limit: 20, skip: 0)

        XCTAssertTrue(page.isStale)
        XCTAssertEqual(page.products.first?.id, 9)
    }

    func test_connectivityFailureWithoutCache_rethrowsError() async {
        let apiClient = MockAPIClient()
        apiClient.dataProvider = { _ in throw AppError.connectivity }
        let repository = DefaultProductsRepository(apiClient: apiClient, cache: InMemoryCatalogueCache())

        do {
            _ = try await repository.fetchCatalogue(query: CatalogueQuery(), limit: 20, skip: 0)
            XCTFail("expected connectivity error to propagate when no cache exists")
        } catch let error as AppError {
            XCTAssertEqual(error, .connectivity)
        } catch {
            XCTFail("unexpected error type: \(error)")
        }
    }

    func test_searchQuery_hitsSearchEndpointAndIsNeverCached() async throws {
        let apiClient = MockAPIClient()
        apiClient.dataProvider = { _ in self.sampleJSON }
        let cache = InMemoryCatalogueCache()
        let repository = DefaultProductsRepository(apiClient: apiClient, cache: cache)

        _ = try await repository.fetchCatalogue(query: CatalogueQuery(searchText: "pillow"), limit: 20, skip: 0)

        XCTAssertEqual(apiClient.requestedEndpoints.count, 1)
        XCTAssertEqual(apiClient.requestedEndpoints.first?.url?.path, "/products/search")
        XCTAssertNil(cache.load(), "search results must never be cached as the offline baseline")
    }

    func test_categoryFilter_hitsCategoryEndpoint() async throws {
        let apiClient = MockAPIClient()
        apiClient.dataProvider = { _ in self.sampleJSON }
        let repository = DefaultProductsRepository(apiClient: apiClient, cache: InMemoryCatalogueCache())

        _ = try await repository.fetchCatalogue(query: CatalogueQuery(category: "beauty"), limit: 20, skip: 0)

        XCTAssertEqual(apiClient.requestedEndpoints.first?.url?.path, "/products/category/beauty")
    }
}
