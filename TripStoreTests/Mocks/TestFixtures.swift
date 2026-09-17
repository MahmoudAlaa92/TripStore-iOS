import Foundation
@testable import TripStore

enum TestFixtures {
    static func product(
        id: Int = 1,
        title: String = "Travel Pillow",
        category: String = "Accessories",
        price: Double = 19.99,
        rating: Double = 4.5,
        stock: Int = 10
    ) -> Product {
        Product(
            id: id,
            title: title,
            description: "A comfortable travel pillow.",
            category: category,
            price: price,
            rating: rating,
            stock: stock,
            thumbnailURL: URL(string: "https://example.com/thumb\(id).jpg"),
            imageURLs: []
        )
    }
}
