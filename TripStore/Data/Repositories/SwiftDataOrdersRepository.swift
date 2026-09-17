import Foundation
import SwiftData

@ModelActor
actor SwiftDataOrdersRepository: OrdersRepository {
    func createOrder(_ order: Order) async throws {
        modelContext.insert(OrderRecord(order: order))
        try modelContext.save()
    }

    func fetchOrders() async throws -> [Order] {
        let descriptor = FetchDescriptor<OrderRecord>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }
}
