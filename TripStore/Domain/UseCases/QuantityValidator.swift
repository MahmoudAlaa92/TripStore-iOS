import Foundation

/// Enforces the quantity business rule: 1...stock, with stock == 0 meaning
/// ordering is disabled entirely.
enum QuantityValidator {
    static func isValid(quantity: Int, stock: Int) -> Bool {
        guard stock > 0 else { return false }
        return quantity >= 1 && quantity <= stock
    }

    /// Clamps a requested quantity into the valid range for the given stock.
    /// Returns 0 when stock is 0 (there is no valid quantity to select).
    static func clamp(_ quantity: Int, stock: Int) -> Int {
        guard stock > 0 else { return 0 }
        return min(max(quantity, 1), stock)
    }
}
