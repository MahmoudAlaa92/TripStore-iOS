import SwiftUI

struct RootTabView: View {
    let dependencies: AppDependencies

    var body: some View {
        TabView {
            CatalogueView(viewModel: CatalogueViewModel(
                repository: dependencies.productsRepository,
                categoriesRepository: dependencies.categoriesRepository
            ))
            .tabItem { Label("Catalogue", systemImage: "bag") }

            FavoritesView()
                .tabItem { Label("Favorites", systemImage: "heart") }
        }
        .environmentObject(dependencies.favoritesStore)
    }
}
