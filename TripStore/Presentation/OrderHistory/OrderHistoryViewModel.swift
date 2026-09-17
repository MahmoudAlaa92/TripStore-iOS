import Foundation

@MainActor
final class OrderHistoryViewModel: ObservableObject {
    @Published private(set) var orders: [Order] = []

    private let repository: OrdersRepository

    init(repository: OrdersRepository) {
        self.repository = repository
    }

    func refresh() async {
        orders = (try? await repository.fetchOrders()) ?? []
    }
}
