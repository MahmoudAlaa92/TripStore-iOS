import CoreData

/// An actor wrapping a dedicated background `NSManagedObjectContext`, mirroring
/// the isolation the prior `@ModelActor` SwiftData repository gave: the
/// context is confined to one place, and every access still goes through
/// `context.perform` as Core Data itself requires regardless of Swift
/// concurrency isolation.
actor CoreDataFavoritesRepository: FavoritesRepository {
    private let context: NSManagedObjectContext

    init(stack: CoreDataStack) {
        self.context = stack.newBackgroundContext()
    }

    func loadAll() async throws -> [FavoriteProduct] {
        try await context.perform {
            let request = FavoriteEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "addedAt", ascending: false)]
            return try self.context.fetch(request).map { $0.toDomain() }
        }
    }

    func add(_ product: Product) async throws {
        try await context.perform {
            let request = FavoriteEntity.fetchRequest()
            request.predicate = NSPredicate(format: "productId == %d", product.id)
            request.fetchLimit = 1
            guard try self.context.fetch(request).first == nil else { return }

            let entity = FavoriteEntity(context: self.context)
            entity.apply(product, addedAt: Date())
            try self.context.save()
        }
    }

    func remove(productId: Int) async throws {
        try await context.perform {
            let request = FavoriteEntity.fetchRequest()
            request.predicate = NSPredicate(format: "productId == %d", productId)
            for entity in try self.context.fetch(request) {
                self.context.delete(entity)
            }
            try self.context.save()
        }
    }
}
