import Foundation

protocol FavoritesRepository {
    func loadAll() async throws -> [FavoriteProduct]
    func add(_ product: Product) async throws
    func remove(productId: Int) async throws
}
