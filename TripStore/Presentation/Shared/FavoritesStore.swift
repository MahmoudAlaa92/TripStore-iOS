import Foundation

/// The single source of truth for favourite state across Catalogue, Details
/// and Favourites — each screen reads `favoriteIds`/`favorites` from the same
/// instance so toggling a favourite anywhere is reflected everywhere without
/// re-fetching.
@MainActor
final class FavoritesStore: ObservableObject {
    @Published private(set) var favoriteIds: Set<Int> = []
    @Published private(set) var favorites: [FavoriteProduct] = []

    private let repository: FavoritesRepository
    private var isLoaded = false

    init(repository: FavoritesRepository) {
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard !isLoaded else { return }
        isLoaded = true
        await reload()
    }

    func reload() async {
        let loaded = (try? await repository.loadAll()) ?? []
        favorites = loaded
        favoriteIds = Set(loaded.map(\.productId))
    }

    func isFavorite(_ productId: Int) -> Bool {
        favoriteIds.contains(productId)
    }

    func toggle(_ product: Product) async {
        if favoriteIds.contains(product.id) {
            await remove(productId: product.id)
        } else {
            favoriteIds.insert(product.id)
            do {
                try await repository.add(product)
                await reload()
            } catch {
                favoriteIds.remove(product.id)
            }
        }
    }

    func remove(productId: Int) async {
        favoriteIds.remove(productId)
        favorites.removeAll { $0.productId == productId }
        try? await repository.remove(productId: productId)
    }
}
