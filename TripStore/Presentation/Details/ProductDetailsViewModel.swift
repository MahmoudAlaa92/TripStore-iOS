import Foundation

@MainActor
final class ProductDetailsViewModel: ObservableObject {
    let product: Product

    @Published var quantity: Int
    @Published private(set) var isFavorite: Bool = false

    init(product: Product) {
        self.product = product
        _quantity = Published(initialValue: product.stock > 0 ? 1 : 0)
    }

    var orderSummary: OrderSummary {
        CalculateOrderSummaryUseCase.execute(unitPrice: product.price, quantity: quantity, stock: product.stock)
    }

    var canOrder: Bool {
        orderSummary.isQuantityValid
    }

    func increaseQuantity() {
        quantity = QuantityValidator.clamp(quantity + 1, stock: product.stock)
    }

    func decreaseQuantity() {
        quantity = QuantityValidator.clamp(quantity - 1, stock: product.stock)
    }

    /// Local-only for now; wired to persisted favourites in a later phase.
    func toggleFavorite() {
        isFavorite.toggle()
    }
}
