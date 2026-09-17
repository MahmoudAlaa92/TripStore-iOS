import Foundation
@testable import TripStore

/// Closure-based mock so each test can script exactly the responses/delays
/// it needs (including per-query delays, used by the search concurrency
/// test) without a combinatorial explosion of mock subclasses. An actor so
/// concurrent overlapping calls from a test (the whole point of the
/// concurrency tests) don't race on its stored state.
actor MockProductsRepository: ProductsRepository {
    var responseProvider: (CatalogueQuery, Int, Int) async throws -> CataloguePage = { _, _, _ in .empty }
    private(set) var receivedQueries: [CatalogueQuery] = []

    func setResponseProvider(_ provider: @escaping (CatalogueQuery, Int, Int) async throws -> CataloguePage) {
        responseProvider = provider
    }

    nonisolated func fetchCatalogue(query: CatalogueQuery, limit: Int, skip: Int) async throws -> CataloguePage {
        await recordQuery(query)
        return try await currentProvider()(query, limit, skip)
    }

    private func recordQuery(_ query: CatalogueQuery) {
        receivedQueries.append(query)
    }

    private func currentProvider() -> (CatalogueQuery, Int, Int) async throws -> CataloguePage {
        responseProvider
    }
}

final class MockCategoriesRepository: CategoriesRepository {
    var categoriesToReturn: [String] = []

    func fetchCategories() async throws -> [String] {
        categoriesToReturn
    }
}
