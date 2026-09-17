import Foundation

/// Simple constructor-injection container. Views/ViewModels receive their
/// dependencies through initializers rather than reaching into a global, so
/// tests can substitute mocks without touching this type at all.
@MainActor
final class AppDependencies {
    let apiClient: APIClient
    let catalogueCache: CatalogueCache
    let productsRepository: ProductsRepository
    let categoriesRepository: CategoriesRepository

    init() {
        let apiClient = URLSessionAPIClient()
        self.apiClient = apiClient
        self.catalogueCache = FileCatalogueCache()
        self.productsRepository = DefaultProductsRepository(apiClient: apiClient, cache: catalogueCache)
        self.categoriesRepository = DefaultCategoriesRepository(apiClient: apiClient)
    }
}
