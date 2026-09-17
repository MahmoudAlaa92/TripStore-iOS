import Foundation
import SwiftData

@Model
final class FavoriteRecord {
    @Attribute(.unique) var productId: Int
    var title: String
    var category: String
    var price: Double
    var rating: Double
    var thumbnailURLString: String?
    var addedAt: Date

    init(productId: Int, title: String, category: String, price: Double, rating: Double, thumbnailURLString: String?, addedAt: Date) {
        self.productId = productId
        self.title = title
        self.category = category
        self.price = price
        self.rating = rating
        self.thumbnailURLString = thumbnailURLString
        self.addedAt = addedAt
    }
}

extension FavoriteRecord {
    convenience init(product: Product) {
        self.init(
            productId: product.id,
            title: product.title,
            category: product.category,
            price: product.price,
            rating: product.rating,
            thumbnailURLString: product.thumbnailURL?.absoluteString,
            addedAt: Date()
        )
    }

    /// Never crashes on a malformed record: a negative/NaN price collapses to
    /// 0 and an invalid thumbnail URL string simply omits the image.
    func toDomain() -> FavoriteProduct {
        let safePrice = price.isFinite ? max(price, 0) : 0
        let safeRating = rating.isFinite ? min(max(rating, 0), 5) : 0
        return FavoriteProduct(
            productId: productId,
            title: title.isEmpty ? "Untitled product" : title,
            category: category.isEmpty ? "Uncategorized" : category,
            price: safePrice,
            rating: safeRating,
            thumbnailURL: thumbnailURLString.flatMap(URL.init(string:)),
            addedAt: addedAt
        )
    }
}
