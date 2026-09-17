import Foundation

/// Combines quantity validation and pricing into the single summary the
/// presentation layer needs to render a live total and to gate the CTA.
enum CalculateOrderSummaryUseCase {
    static func execute(unitPrice: Double, quantity: Int, stock: Int) -> OrderSummary {
        let isValid = QuantityValidator.isValid(quantity: quantity, stock: stock)
        let effectiveQuantity = max(quantity, 0)
        let subtotal = PricingCalculator.subtotal(unitPrice: unitPrice, quantity: effectiveQuantity)
        let fee = PricingCalculator.serviceFee(subtotal: subtotal)
        let total = PricingCalculator.total(subtotal: subtotal, serviceFee: fee)
        return OrderSummary(
            unitPrice: unitPrice,
            quantity: quantity,
            subtotal: subtotal,
            serviceFee: fee,
            total: total,
            isQuantityValid: isValid
        )
    }
}
