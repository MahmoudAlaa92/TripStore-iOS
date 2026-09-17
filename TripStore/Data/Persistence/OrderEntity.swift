import CoreData

/// Core Data managed object for a persisted order. Holds only data — order
/// pricing math stays in the Domain layer (PricingCalculator /
/// CalculateOrderSummaryUseCase); this type never computes anything.
@objc(OrderEntity)
final class OrderEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var productId: Int64
    @NSManaged var productTitle: String
    @NSManaged var productThumbnailURLString: String?
    @NSManaged var quantity: Int64
    @NSManaged var unitPrice: Double
    @NSManaged var subtotal: Double
    @NSManaged var serviceFee: Double
    @NSManaged var total: Double
    @NSManaged var createdAt: Date
}

extension OrderEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<OrderEntity> {
        NSFetchRequest<OrderEntity>(entityName: "OrderEntity")
    }

    func apply(_ order: Order) {
        id = order.id
        productId = Int64(order.productId)
        productTitle = order.productTitle
        productThumbnailURLString = order.productThumbnailURL?.absoluteString
        quantity = Int64(order.quantity)
        unitPrice = order.unitPrice
        subtotal = order.subtotal
        serviceFee = order.serviceFee
        total = order.total
        createdAt = order.createdAt
    }

    /// Defensive against a corrupt record: a negative quantity or
    /// non-finite price collapses to 0 rather than crashing order history.
    func toDomain() -> Order {
        Order(
            id: id,
            productId: Int(productId),
            productTitle: productTitle.isEmpty ? "Untitled product" : productTitle,
            productThumbnailURL: productThumbnailURLString.flatMap(URL.init(string:)),
            quantity: max(Int(quantity), 0),
            unitPrice: unitPrice.isFinite ? max(unitPrice, 0) : 0,
            subtotal: subtotal.isFinite ? max(subtotal, 0) : 0,
            serviceFee: serviceFee.isFinite ? max(serviceFee, 0) : 0,
            total: total.isFinite ? max(total, 0) : 0,
            createdAt: createdAt
        )
    }
}
