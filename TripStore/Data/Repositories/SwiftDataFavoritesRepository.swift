import Foundation
import SwiftData

/// `@ModelActor` gives this repository its own actor-isolated `ModelContext`,
/// so favourites can be read/written safely off the main actor without
/// touching SwiftUI's main-thread context.
@ModelActor
actor SwiftDataFavoritesRepository: FavoritesRepository {
    func loadAll() async throws -> [FavoriteProduct] {
        let descriptor = FetchDescriptor<FavoriteRecord>(sortBy: [SortDescriptor(\.addedAt, order: .reverse)])
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func add(_ product: Product) async throws {
        let productId = product.id
        let descriptor = FetchDescriptor<FavoriteRecord>(predicate: #Predicate { $0.productId == productId })
        if try modelContext.fetch(descriptor).first != nil {
            return
        }
        modelContext.insert(FavoriteRecord(product: product))
        try modelContext.save()
    }

    func remove(productId: Int) async throws {
        let descriptor = FetchDescriptor<FavoriteRecord>(predicate: #Predicate { $0.productId == productId })
        for record in try modelContext.fetch(descriptor) {
            modelContext.delete(record)
        }
        try modelContext.save()
    }
}
