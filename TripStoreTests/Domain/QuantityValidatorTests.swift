import XCTest
@testable import TripStore

final class QuantityValidatorTests: XCTestCase {
    func test_quantityBelowOne_isInvalid() {
        XCTAssertFalse(QuantityValidator.isValid(quantity: 0, stock: 10))
        XCTAssertFalse(QuantityValidator.isValid(quantity: -1, stock: 10))
    }

    func test_quantityAboveStock_isInvalid() {
        XCTAssertFalse(QuantityValidator.isValid(quantity: 11, stock: 10))
    }

    func test_quantityWithinRange_isValid() {
        XCTAssertTrue(QuantityValidator.isValid(quantity: 1, stock: 10))
        XCTAssertTrue(QuantityValidator.isValid(quantity: 10, stock: 10))
        XCTAssertTrue(QuantityValidator.isValid(quantity: 5, stock: 10))
    }

    func test_zeroStock_disablesOrderingEntirely() {
        XCTAssertFalse(QuantityValidator.isValid(quantity: 1, stock: 0))
        XCTAssertEqual(QuantityValidator.clamp(1, stock: 0), 0)
    }

    func test_clamp_keepsQuantityWithinBounds() {
        XCTAssertEqual(QuantityValidator.clamp(0, stock: 10), 1)
        XCTAssertEqual(QuantityValidator.clamp(15, stock: 10), 10)
        XCTAssertEqual(QuantityValidator.clamp(5, stock: 10), 5)
    }
}
