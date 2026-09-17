import Foundation

/// A lightweight snapshot of a product saved for offline favourites display.
/// Kept separate from `Product` because favourites must remain viewable even
/// when the full catalogue can no longer be fetched or has changed.
struct FavoriteProduct: Identifiable, Equatable, Hashable {
    let productId: Int
    let title: String
    let category: String
    let price: Double
    let rating: Double
    let thumbnailURL: URL?
    let addedAt: Date

    var id: Int { productId }
}
