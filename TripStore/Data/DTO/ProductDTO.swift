import Foundation

/// Mirrors dummyjson's product object. Every field is decoded defensively:
/// remote data is untrusted, so a missing or malformed field falls back to a
/// safe default instead of failing the whole decode.
struct ProductDTO: Decodable {
    let id: Int?
    let title: String?
    let description: String?
    let category: String?
    let price: Double?
    let rating: Double?
    let stock: Int?
    let thumbnail: String?
    let images: [String]?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try? container.decodeIfPresent(Int.self, forKey: .id)
        title = try? container.decodeIfPresent(String.self, forKey: .title)
        description = try? container.decodeIfPresent(String.self, forKey: .description)
        category = try? container.decodeIfPresent(String.self, forKey: .category)
        price = try? container.decodeIfPresent(Double.self, forKey: .price)
        rating = try? container.decodeIfPresent(Double.self, forKey: .rating)
        stock = try? container.decodeIfPresent(Int.self, forKey: .stock)
        thumbnail = try? container.decodeIfPresent(String.self, forKey: .thumbnail)
        images = try? container.decodeIfPresent([String].self, forKey: .images)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, description, category, price, rating, stock, thumbnail, images
    }
}

extension ProductDTO {
    /// Maps to the domain entity, substituting safe fallbacks for any field
    /// that was missing or invalid so the app never crashes on partial data.
    /// A product with no usable `id` cannot be identified or ordered, so it
    /// is dropped by the caller rather than mapped.
    func toDomain() -> Product? {
        guard let id else { return nil }
        return Product(
            id: id,
            title: title.flatMap { $0.isEmpty ? nil : $0 } ?? "Untitled product",
            description: description ?? "",
            category: category.flatMap { $0.isEmpty ? nil : $0 } ?? "Uncategorized",
            price: max(price ?? 0, 0),
            rating: min(max(rating ?? 0, 0), 5),
            stock: max(stock ?? 0, 0),
            thumbnailURL: thumbnail.flatMap(URL.init(string:)),
            imageURLs: (images ?? []).compactMap(URL.init(string:))
        )
    }
}
