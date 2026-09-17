import Foundation

@MainActor
final class OrderConfirmationViewModel: ObservableObject {
    let product: Product
    let quantity: Int

    @Published private(set) var isSubmitting = false
    @Published private(set) var isConfirmed = false
    @Published private(set) var errorMessage: String?

    private let ordersRepository: OrdersRepository

    init(product: Product, quantity: Int, ordersRepository: OrdersRepository) {
        self.product = product
        self.quantity = quantity
        self.ordersRepository = ordersRepository
    }

    var summary: OrderSummary {
        CalculateOrderSummaryUseCase.execute(unitPrice: product.price, quantity: quantity, stock: product.stock)
    }

    /// Guards against duplicate orders two ways: `isSubmitting` blocks a
    /// second tap while the first is still in flight, and `isConfirmed`
    /// blocks any further attempt once an order has already been created —
    /// together they make "exactly one order" hold regardless of how fast
    /// the user taps.
    func confirm() async {
        guard !isSubmitting, !isConfirmed, summary.isQuantityValid else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        let order = Order(
            id: UUID(),
            productId: product.id,
            productTitle: product.title,
            productThumbnailURL: product.thumbnailURL,
            quantity: quantity,
            unitPrice: product.price,
            subtotal: summary.subtotal,
            serviceFee: summary.serviceFee,
            total: summary.total,
            createdAt: Date()
        )

        do {
            try await ordersRepository.createOrder(order)
            isConfirmed = true
        } catch {
            errorMessage = AppError.unknown.userMessage
        }
    }
}
