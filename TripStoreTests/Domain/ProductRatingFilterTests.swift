import XCTest
@testable import TripStore

final class ProductRatingFilterTests: XCTestCase {
    func test_zeroMinimum_returnsAllProducts() {
        let products = [TestFixtures.product(id: 1, rating: 1.0), TestFixtures.product(id: 2, rating: 5.0)]
        XCTAssertEqual(ProductRatingFilter.apply(products, minimumRating: 0).count, 2)
    }

    func test_filtersOutProductsBelowMinimum() {
        let products = [
            TestFixtures.product(id: 1, rating: 3.0),
            TestFixtures.product(id: 2, rating: 4.5),
            TestFixtures.product(id: 3, rating: 4.9)
        ]
        let result = ProductRatingFilter.apply(products, minimumRating: 4.5)
        XCTAssertEqual(result.map(\.id).sorted(), [2, 3])
    }

    func test_productExactlyAtMinimum_isIncluded() {
        let products = [TestFixtures.product(id: 1, rating: 4.0)]
        XCTAssertEqual(ProductRatingFilter.apply(products, minimumRating: 4.0).count, 1)
    }
}
