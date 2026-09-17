import CoreData

actor CoreDataOrdersRepository: OrdersRepository {
    private let context: NSManagedObjectContext

    init(stack: CoreDataStack) {
        self.context = stack.newBackgroundContext()
    }

    func createOrder(_ order: Order) async throws {
        try await context.perform {
            let entity = OrderEntity(context: self.context)
            entity.apply(order)
            try self.context.save()
        }
    }

    func fetchOrders() async throws -> [Order] {
        try await context.perform {
            let request = OrderEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            return try self.context.fetch(request).map { $0.toDomain() }
        }
    }
}
