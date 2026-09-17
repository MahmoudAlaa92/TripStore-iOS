import Foundation

/// A travel-accessory product shown in the catalogue. All fields are already
/// sanitized (defensive defaults applied) by the time a `Product` exists —
/// nothing downstream needs to re-validate remote data.
struct Product: Identifiable, Equatable, Hashable {
    let id: Int
    let title: String
    let description: String
    let category: String
    let price: Double
    let rating: Double
    let stock: Int
    let thumbnailURL: URL?
    let imageURLs: [URL]

    var isInStock: Bool { stock > 0 }

    /// Every product must have at least one image for the gallery; falls back
    /// to the thumbnail so the details screen never renders an empty gallery.
    var galleryURLs: [URL] {
        imageURLs.isEmpty ? [thumbnailURL].compactMap { $0 } : imageURLs
    }
}
