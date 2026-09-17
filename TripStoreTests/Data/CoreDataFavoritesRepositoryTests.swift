import XCTest
@testable import TripStore

final class CoreDataFavoritesRepositoryTests: XCTestCase {

    /// A fresh in-memory stack per test — never touches the user's real
    /// persistent store, and each test starts from an empty database.
    private func makeRepository() -> CoreDataFavoritesRepository {
        CoreDataFavoritesRepository(stack: CoreDataStack(inMemory: true))
    }

    func test_add_savesFavoriteAndIsReturnedByLoadAll() async throws {
        let repository = makeRepository()
        let product = TestFixtures.product(id: 42, title: "Travel Pillow")

        try await repository.add(product)
        let favorites = try await repository.loadAll()

        XCTAssertEqual(favorites.count, 1)
        XCTAssertEqual(favorites.first?.productId, 42)
        XCTAssertEqual(favorites.first?.title, "Travel Pillow")
    }

    func test_add_sameProductTwice_doesNotCreateDuplicate() async throws {
        let repository = makeRepository()
        let product = TestFixtures.product(id: 7)

        try await repository.add(product)
        try await repository.add(product)

        let favorites = try await repository.loadAll()
        XCTAssertEqual(favorites.count, 1)
    }

    func test_remove_deletesFavorite() async throws {
        let repository = makeRepository()
        let product = TestFixtures.product(id: 3)
        try await repository.add(product)

        try await repository.remove(productId: 3)

        let favorites = try await repository.loadAll()
        XCTAssertTrue(favorites.isEmpty)
    }

    /// Favourites must survive being re-read through a fresh repository
    /// instance backed by the same underlying store — simulating "persists
    /// across app relaunch" without actually relaunching the app.
    func test_favoritesPersistAcrossRepositoryInstancesOnSameStore() async throws {
        let stack = CoreDataStack(inMemory: true)
        let firstRepository = CoreDataFavoritesRepository(stack: stack)
        try await firstRepository.add(TestFixtures.product(id: 11, title: "Packing Cubes"))

        let secondRepository = CoreDataFavoritesRepository(stack: stack)
        let favorites = try await secondRepository.loadAll()

        XCTAssertEqual(favorites.count, 1)
        XCTAssertEqual(favorites.first?.productId, 11)
    }

    func test_loadAll_ordersByMostRecentlyAddedFirst() async throws {
        let repository = makeRepository()
        try await repository.add(TestFixtures.product(id: 1))
        try? await Task.sleep(nanoseconds: 5_000_000)
        try await repository.add(TestFixtures.product(id: 2))

        let favorites = try await repository.loadAll()

        XCTAssertEqual(favorites.map(\.productId), [2, 1])
    }
}
