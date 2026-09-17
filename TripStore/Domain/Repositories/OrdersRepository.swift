import Foundation

protocol OrdersRepository {
    func createOrder(_ order: Order) async throws
    func fetchOrders() async throws -> [Order]
}
