import Foundation
@testable import TripStore

final class MockAPIClient: APIClient {
    var dataProvider: (Endpoint) async throws -> Data = { _ in Data() }
    private(set) var requestedEndpoints: [Endpoint] = []

    func data(for endpoint: Endpoint) async throws -> Data {
        requestedEndpoints.append(endpoint)
        return try await dataProvider(endpoint)
    }
}

final class InMemoryCatalogueCache: CatalogueCache {
    private var stored: CataloguePage?

    func save(_ page: CataloguePage) {
        stored = page
    }

    func load() -> CataloguePage? {
        guard let stored else { return nil }
        return CataloguePage(products: stored.products, total: stored.total, skip: stored.skip, limit: stored.limit, isStale: true)
    }
}
