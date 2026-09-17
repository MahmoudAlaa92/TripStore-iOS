import Foundation

/// Codable mirror of `CataloguePage`/`Product` used only for disk caching.
/// Domain entities stay free of persistence concerns; this type is the
/// translation boundary.
struct CachedProduct: Codable {
    let id: Int
    let title: String
    let description: String
    let category: String
    let price: Double
    let rating: Double
    let stock: Int
    let thumbnailURL: URL?
    let imageURLs: [URL]

    init(product: Product) {
        id = product.id
        title = product.title
        description = product.description
        category = product.category
        price = product.price
        rating = product.rating
        stock = product.stock
        thumbnailURL = product.thumbnailURL
        imageURLs = product.imageURLs
    }

    func toDomain() -> Product {
        Product(
            id: id, title: title, description: description, category: category,
            price: price, rating: rating, stock: stock,
            thumbnailURL: thumbnailURL, imageURLs: imageURLs
        )
    }
}

struct CachedCataloguePage: Codable {
    let products: [CachedProduct]
    let total: Int
    let skip: Int
    let limit: Int

    init(page: CataloguePage) {
        products = page.products.map(CachedProduct.init)
        total = page.total
        skip = page.skip
        limit = page.limit
    }

    func toDomain(isStale: Bool) -> CataloguePage {
        CataloguePage(
            products: products.map { $0.toDomain() },
            total: total, skip: skip, limit: limit, isStale: isStale
        )
    }
}
