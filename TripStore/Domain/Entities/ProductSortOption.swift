import Foundation

enum ProductSortOption: String, CaseIterable, Identifiable {
    case featured
    case priceAscending
    case priceDescending
    case ratingDescending

    var id: String { rawValue }

    var title: String {
        switch self {
        case .featured: return "Featured"
        case .priceAscending: return "Price: Low to High"
        case .priceDescending: return "Price: High to Low"
        case .ratingDescending: return "Top Rated"
        }
    }

    /// dummyjson's `sortBy`/`order` query parameters, or nil for the
    /// server's default ordering.
    var remoteSortBy: String? {
        switch self {
        case .featured: return nil
        case .priceAscending, .priceDescending: return "price"
        case .ratingDescending: return "rating"
        }
    }

    var remoteOrder: String? {
        switch self {
        case .featured: return nil
        case .priceAscending: return "asc"
        case .priceDescending: return "desc"
        case .ratingDescending: return "desc"
        }
    }
}
