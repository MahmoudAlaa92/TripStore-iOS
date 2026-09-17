import Foundation

/// Chooses the right dummyjson endpoint for the current query (search takes
/// precedence over category, which takes precedence over the plain listing),
/// and falls back to the on-disk cache when the *plain, first* page request
/// fails due to connectivity — that is the only shape of response cached.
final class DefaultProductsRepository: ProductsRepository {
    private let apiClient: APIClient
    private let cache: CatalogueCache

    init(apiClient: APIClient, cache: CatalogueCache) {
        self.apiClient = apiClient
        self.cache = cache
    }

    func fetchCatalogue(query: CatalogueQuery, limit: Int, skip: Int) async throws -> CataloguePage {
        let isPlainFirstPage = query.trimmedSearchText.isEmpty && query.category == nil && skip == 0

        do {
            let endpoint = makeEndpoint(query: query, limit: limit, skip: skip)
            let response: ProductsResponseDTO = try await apiClient.send(endpoint)
            let page = response.toDomain()
            if isPlainFirstPage {
                cache.save(page)
            }
            return page
        } catch let error as AppError where error == .connectivity {
            if isPlainFirstPage, let cached = cache.load() {
                return cached
            }
            throw error
        }
    }

    private func makeEndpoint(query: CatalogueQuery, limit: Int, skip: Int) -> Endpoint {
        let sortBy = query.sortOption.remoteSortBy
        let order = query.sortOption.remoteOrder
        let searchText = query.trimmedSearchText

        if !searchText.isEmpty {
            return .search(query: searchText, limit: limit, skip: skip, sortBy: sortBy, order: order)
        }
        if let category = query.category {
            return .category(name: category, limit: limit, skip: skip, sortBy: sortBy, order: order)
        }
        return .products(limit: limit, skip: skip, sortBy: sortBy, order: order)
    }
}
