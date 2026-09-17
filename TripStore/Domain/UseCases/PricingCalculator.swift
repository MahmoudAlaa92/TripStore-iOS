import Foundation

/// Pure pricing math. No dependencies, no side effects — kept out of
/// ViewModels so it can be tested directly and reused by both the details
/// screen (live total) and order creation.
enum PricingCalculator {
    static let serviceFeeRate: Double = 0.05

    static func subtotal(unitPrice: Double, quantity: Int) -> Double {
        round2(unitPrice * Double(quantity))
    }

    static func serviceFee(subtotal: Double) -> Double {
        round2(subtotal * serviceFeeRate)
    }

    static func total(subtotal: Double, serviceFee: Double) -> Double {
        round2(subtotal + serviceFee)
    }

    /// Rounds to exactly 2 decimal places using standard half-up rounding,
    /// avoiding binary floating point artifacts like 19.999999999999996.
    static func round2(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }
}
