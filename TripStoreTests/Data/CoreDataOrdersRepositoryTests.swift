import XCTest
@testable import TripStore

final class CoreDataOrdersRepositoryTests: XCTestCase {

    private func makeOrder(id: UUID = UUID(), productId: Int = 1, total: Double = 42.0) -> Order {
        Order(
            id: id,
            productId: productId,
            productTitle: "Travel Pillow",
            productThumbnailURL: nil,
            quantity: 2,
            unitPrice: 20.0,
            subtotal: 40.0,
            serviceFee: 2.0,
            total: total,
            createdAt: Date()
        )
    }

    func test_createOrder_savesOrderAndIsReturnedByFetchOrders() async throws {
        let repository = CoreDataOrdersRepository(stack: CoreDataStack(inMemory: true))
        let order = makeOrder()

        try await repository.createOrder(order)
        let orders = try await repository.fetchOrders()

        XCTAssertEqual(orders.count, 1)
        XCTAssertEqual(orders.first?.id, order.id)
        XCTAssertEqual(orders.first?.total, 42.0)
    }

    func test_fetchOrders_ordersByMostRecentFirst() async throws {
        let repository = CoreDataOrdersRepository(stack: CoreDataStack(inMemory: true))
        let first = makeOrder(productId: 1)
        try await repository.createOrder(first)
        try? await Task.sleep(nanoseconds: 5_000_000)
        let second = makeOrder(productId: 2)
        try await repository.createOrder(second)

        let orders = try await repository.fetchOrders()

        XCTAssertEqual(orders.map(\.id), [second.id, first.id])
    }

    /// Orders must survive being re-read through a fresh repository instance
    /// backed by the same underlying store — simulating "persists across app
    /// relaunch" without actually relaunching the app.
    func test_ordersPersistAcrossRepositoryInstancesOnSameStore() async throws {
        let stack = CoreDataStack(inMemory: true)
        let order = makeOrder()
        try await CoreDataOrdersRepository(stack: stack).createOrder(order)

        let orders = try await CoreDataOrdersRepository(stack: stack).fetchOrders()

        XCTAssertEqual(orders.count, 1)
        XCTAssertEqual(orders.first?.id, order.id)
    }
}
