import Foundation

/// The remote-facing subset of catalogue state (what gets sent to the API).
/// Minimum-rating filtering is intentionally excluded — dummyjson has no
/// server-side support for it, so it is applied client-side after fetch
/// (see `ProductRatingFilter`).
struct CatalogueQuery: Equatable {
    var searchText: String = ""
    var category: String? = nil
    var sortOption: ProductSortOption = .featured

    var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
