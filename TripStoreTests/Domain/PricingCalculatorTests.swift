import XCTest
@testable import TripStore

final class PricingCalculatorTests: XCTestCase {
    func test_subtotal_multipliesPriceByQuantity() {
        XCTAssertEqual(PricingCalculator.subtotal(unitPrice: 10.0, quantity: 3), 30.0)
    }

    func test_serviceFee_isFivePercentOfSubtotal() {
        XCTAssertEqual(PricingCalculator.serviceFee(subtotal: 100.0), 5.0)
    }

    func test_total_isSubtotalPlusServiceFee() {
        XCTAssertEqual(PricingCalculator.total(subtotal: 100.0, serviceFee: 5.0), 105.0)
    }

    func test_round2_roundsToTwoDecimalPlaces() {
        XCTAssertEqual(PricingCalculator.round2(19.995), 20.0)
        XCTAssertEqual(PricingCalculator.round2(19.994), 19.99)
        XCTAssertEqual(PricingCalculator.round2(0.1 + 0.2), 0.3)
    }

    func test_endToEnd_priceWithOddDecimals_roundsCorrectlyAtEachStep() {
        // 19.99 * 3 = 59.97, fee = 2.9985 -> rounds to 3.00, total = 62.97
        let subtotal = PricingCalculator.subtotal(unitPrice: 19.99, quantity: 3)
        let fee = PricingCalculator.serviceFee(subtotal: subtotal)
        let total = PricingCalculator.total(subtotal: subtotal, serviceFee: fee)

        XCTAssertEqual(subtotal, 59.97)
        XCTAssertEqual(fee, 3.00)
        XCTAssertEqual(total, 62.97)
    }
}
