import CoreData

/// Owns the app's one `NSPersistentContainer`. Repositories never touch
/// `NSManagedObjectContext` directly from outside this layer — they each get
/// their own background context from `newBackgroundContext()` and confine
/// all work to it via `context.perform`.
final class CoreDataStack {
    let persistentContainer: NSPersistentContainer

    /// `inMemory` backs the store with `NSInMemoryStoreType` — used by tests
    /// so they never touch the user's real persistent store.
    init(inMemory: Bool = false) {
        persistentContainer = NSPersistentContainer(name: "TripStore", managedObjectModel: CoreDataModel.model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            persistentContainer.persistentStoreDescriptions = [description]
        }

        // loadPersistentStores' completion can in principle fire on a
        // background queue; block until it does so the stack is guaranteed
        // ready the moment init() returns, matching how the rest of the app
        // (AppDependencies, then FavoritesStore.loadIfNeeded()) assumes a
        // synchronously-ready store.
        let semaphore = DispatchSemaphore(value: 0)
        var loadError: Error?
        persistentContainer.loadPersistentStores { _, error in
            loadError = error
            semaphore.signal()
        }
        semaphore.wait()

        // A fixed, programmatic schema can only fail to load here if the
        // device's storage itself is unusable — there is no valid fallback
        // UI state for that, so this is one of the few justified crashes
        // (same invariant the prior SwiftData `try! ModelContainer` relied on).
        if let loadError {
            fatalError("Failed to load Core Data persistent store: \(loadError)")
        }

        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}
