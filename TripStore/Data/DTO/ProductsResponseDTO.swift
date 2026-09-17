import Foundation

struct ProductsResponseDTO: Decodable {
    let products: [ProductDTO]
    let total: Int?
    let skip: Int?
    let limit: Int?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        products = (try? container.decodeIfPresent([ProductDTO].self, forKey: .products)) ?? []
        total = try? container.decodeIfPresent(Int.self, forKey: .total)
        skip = try? container.decodeIfPresent(Int.self, forKey: .skip)
        limit = try? container.decodeIfPresent(Int.self, forKey: .limit)
    }

    private enum CodingKeys: String, CodingKey {
        case products, total, skip, limit
    }
}

extension ProductsResponseDTO {
    /// `isStale` is always false here — freshness is decided by the caller
    /// (the repository), not by the DTO mapping itself.
    func toDomain() -> CataloguePage {
        let mapped = products.compactMap { $0.toDomain() }
        return CataloguePage(
            products: mapped,
            total: total ?? mapped.count,
            skip: skip ?? 0,
            limit: limit ?? mapped.count,
            isStale: false
        )
    }
}
