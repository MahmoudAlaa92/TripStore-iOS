import Foundation
@testable import TripStore

actor InMemoryOrdersRepository: OrdersRepository {
    private(set) var savedOrders: [Order] = []
    var createOrderCallCount = 0

    func createOrder(_ order: Order) async throws {
        createOrderCallCount += 1
        savedOrders.append(order)
    }

    func fetchOrders() async throws -> [Order] {
        savedOrders
    }
}
