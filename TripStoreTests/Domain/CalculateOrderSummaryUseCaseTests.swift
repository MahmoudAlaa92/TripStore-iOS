import XCTest
@testable import TripStore

final class CalculateOrderSummaryUseCaseTests: XCTestCase {
    func test_validQuantity_producesCorrectSummary() {
        let summary = CalculateOrderSummaryUseCase.execute(unitPrice: 20.0, quantity: 2, stock: 5)

        XCTAssertTrue(summary.isQuantityValid)
        XCTAssertEqual(summary.subtotal, 40.0)
        XCTAssertEqual(summary.serviceFee, 2.0)
        XCTAssertEqual(summary.total, 42.0)
    }

    func test_zeroStock_isInvalidRegardlessOfQuantity() {
        let summary = CalculateOrderSummaryUseCase.execute(unitPrice: 20.0, quantity: 1, stock: 0)
        XCTAssertFalse(summary.isQuantityValid)
    }

    func test_quantityExceedingStock_isInvalidButStillPricesForDisplay() {
        let summary = CalculateOrderSummaryUseCase.execute(unitPrice: 10.0, quantity: 99, stock: 5)
        XCTAssertFalse(summary.isQuantityValid)
        XCTAssertEqual(summary.subtotal, 990.0)
    }
}
