import Foundation

/// A confirmed local booking-style order. Orders are never sent to a backend
/// — they exist only in local persistence (see PHASE 6 / README).
struct Order: Identifiable, Equatable {
    let id: UUID
    let productId: Int
    let productTitle: String
    let productThumbnailURL: URL?
    let quantity: Int
    let unitPrice: Double
    let subtotal: Double
    let serviceFee: Double
    let total: Double
    let createdAt: Date
}
