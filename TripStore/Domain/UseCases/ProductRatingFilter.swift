import Foundation

/// Client-side minimum-rating filter. dummyjson has no server-side rating
/// filter, so this is applied to whatever page was fetched. Documented as a
/// known trade-off in the README: with a rating filter active, the reported
/// `total` still reflects the server's unfiltered count.
enum ProductRatingFilter {
    static func apply(_ products: [Product], minimumRating: Double) -> [Product] {
        guard minimumRating > 0 else { return products }
        return products.filter { $0.rating >= minimumRating }
    }
}
