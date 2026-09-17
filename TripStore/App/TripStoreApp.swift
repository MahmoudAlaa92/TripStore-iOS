import SwiftUI

@main
struct TripStoreApp: App {
    @State private var dependencies = AppDependencies()

    init() {
        URLCache.shared = URLCache(memoryCapacity: 20 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024)
    }

    var body: some Scene {
        WindowGroup {
            CatalogueView(viewModel: CatalogueViewModel(
                repository: dependencies.productsRepository,
                categoriesRepository: dependencies.categoriesRepository
            ))
        }
    }
}
