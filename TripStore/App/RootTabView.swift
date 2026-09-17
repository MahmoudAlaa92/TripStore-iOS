import SwiftUI

struct RootTabView: View {
    let dependencies: AppDependencies

    var body: some View {
        TabView {
            CatalogueView(
                viewModel: CatalogueViewModel(
                    repository: dependencies.productsRepository,
                    categoriesRepository: dependencies.categoriesRepository
                ),
                ordersRepository: dependencies.ordersRepository
            )
            .tabItem { Label("Catalogue", systemImage: "bag") }

            FavoritesView()
                .tabItem { Label("Favorites", systemImage: "heart") }

            OrderHistoryView(viewModel: OrderHistoryViewModel(repository: dependencies.ordersRepository))
                .tabItem { Label("Orders", systemImage: "clock") }
        }
        .environmentObject(dependencies.favoritesStore)
    }
}
