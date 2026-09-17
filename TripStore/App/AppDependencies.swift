import Foundation
import SwiftData

/// Simple constructor-injection container. Views/ViewModels receive their
/// dependencies through initializers rather than reaching into a global, so
/// tests can substitute mocks without touching this type at all.
@MainActor
final class AppDependencies {
    let apiClient: APIClient
    let catalogueCache: CatalogueCache
    let productsRepository: ProductsRepository
    let categoriesRepository: CategoriesRepository
    let modelContainer: ModelContainer
    let favoritesRepository: FavoritesRepository
    let favoritesStore: FavoritesStore

    init() {
        let apiClient = URLSessionAPIClient()
        self.apiClient = apiClient
        self.catalogueCache = FileCatalogueCache()
        self.productsRepository = DefaultProductsRepository(apiClient: apiClient, cache: catalogueCache)
        self.categoriesRepository = DefaultCategoriesRepository(apiClient: apiClient)

        // A fixed, static schema can only fail to load here if the device's
        // storage itself is unusable — there is no valid fallback UI state
        // for that, so this is one of the few justified force-tries.
        let modelContainer = try! ModelContainer(for: FavoriteRecord.self)
        self.modelContainer = modelContainer
        self.favoritesRepository = SwiftDataFavoritesRepository(modelContainer: modelContainer)
        self.favoritesStore = FavoritesStore(repository: favoritesRepository)
    }
}
