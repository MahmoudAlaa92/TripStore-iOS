import Foundation
import SwiftData

@Model
final class OrderRecord {
    @Attribute(.unique) var id: UUID
    var productId: Int
    var productTitle: String
    var productThumbnailURLString: String?
    var quantity: Int
    var unitPrice: Double
    var subtotal: Double
    var serviceFee: Double
    var total: Double
    var createdAt: Date

    init(
        id: UUID, productId: Int, productTitle: String, productThumbnailURLString: String?,
        quantity: Int, unitPrice: Double, subtotal: Double, serviceFee: Double, total: Double, createdAt: Date
    ) {
        self.id = id
        self.productId = productId
        self.productTitle = productTitle
        self.productThumbnailURLString = productThumbnailURLString
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.subtotal = subtotal
        self.serviceFee = serviceFee
        self.total = total
        self.createdAt = createdAt
    }
}

extension OrderRecord {
    convenience init(order: Order) {
        self.init(
            id: order.id,
            productId: order.productId,
            productTitle: order.productTitle,
            productThumbnailURLString: order.productThumbnailURL?.absoluteString,
            quantity: order.quantity,
            unitPrice: order.unitPrice,
            subtotal: order.subtotal,
            serviceFee: order.serviceFee,
            total: order.total,
            createdAt: order.createdAt
        )
    }

    /// Defensive against a corrupt record: a negative quantity or non-finite
    /// price collapses to 0 rather than crashing the order history screen.
    func toDomain() -> Order {
        Order(
            id: id,
            productId: productId,
            productTitle: productTitle.isEmpty ? "Untitled product" : productTitle,
            productThumbnailURL: productThumbnailURLString.flatMap(URL.init(string:)),
            quantity: max(quantity, 0),
            unitPrice: unitPrice.isFinite ? max(unitPrice, 0) : 0,
            subtotal: subtotal.isFinite ? max(subtotal, 0) : 0,
            serviceFee: serviceFee.isFinite ? max(serviceFee, 0) : 0,
            total: total.isFinite ? max(total, 0) : 0,
            createdAt: createdAt
        )
    }
}
