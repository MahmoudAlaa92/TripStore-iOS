import CoreData

/// Core Data managed object for a persisted favourite. Never crosses out of
/// the Data layer — repositories map it to `FavoriteProduct` before
/// returning, so Domain/Presentation never import CoreData.
@objc(FavoriteEntity)
final class FavoriteEntity: NSManagedObject {
    @NSManaged var productId: Int64
    @NSManaged var title: String
    @NSManaged var category: String
    @NSManaged var price: Double
    @NSManaged var rating: Double
    @NSManaged var thumbnailURLString: String?
    @NSManaged var addedAt: Date
}

extension FavoriteEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<FavoriteEntity> {
        NSFetchRequest<FavoriteEntity>(entityName: "FavoriteEntity")
    }

    func apply(_ product: Product, addedAt: Date) {
        productId = Int64(product.id)
        title = product.title
        category = product.category
        price = product.price
        rating = product.rating
        thumbnailURLString = product.thumbnailURL?.absoluteString
        self.addedAt = addedAt
    }

    /// Never crashes on a malformed record: a negative/NaN price collapses
    /// to 0 and an invalid thumbnail URL string simply omits the image —
    /// same defensive contract the SwiftData version had.
    func toDomain() -> FavoriteProduct {
        let safePrice = price.isFinite ? max(price, 0) : 0
        let safeRating = rating.isFinite ? min(max(rating, 0), 5) : 0
        return FavoriteProduct(
            productId: Int(productId),
            title: title.isEmpty ? "Untitled product" : title,
            category: category.isEmpty ? "Uncategorized" : category,
            price: safePrice,
            rating: safeRating,
            thumbnailURL: thumbnailURLString.flatMap(URL.init(string:)),
            addedAt: addedAt
        )
    }
}
