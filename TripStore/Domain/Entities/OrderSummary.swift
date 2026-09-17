import Foundation

/// The result of pricing a quantity of a product — used both for the live
/// total on the details screen and for building a confirmed `Order`.
struct OrderSummary: Equatable {
    let unitPrice: Double
    let quantity: Int
    let subtotal: Double
    let serviceFee: Double
    let total: Double
    let isQuantityValid: Bool
}
