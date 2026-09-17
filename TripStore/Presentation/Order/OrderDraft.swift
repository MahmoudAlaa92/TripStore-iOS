import Foundation

/// Navigation payload from the details screen to order confirmation —
/// nothing here is persisted; a real `Order` is only created once the user
/// confirms.
struct OrderDraft: Hashable {
    let product: Product
    let quantity: Int
}
