import XCTest
@testable import TripStore

@MainActor
final class OrderConfirmationViewModelTests: XCTestCase {

    func test_confirm_createsOrderWithCorrectTotals() async {
        let repository = InMemoryOrdersRepository()
        let viewModel = OrderConfirmationViewModel(
            product: TestFixtures.product(price: 20.0, stock: 5),
            quantity: 2,
            ordersRepository: repository
        )

        await viewModel.confirm()

        XCTAssertTrue(viewModel.isConfirmed)
        let savedOrders = await repository.savedOrders
        XCTAssertEqual(savedOrders.count, 1)
        XCTAssertEqual(savedOrders.first?.subtotal, 40.0)
        XCTAssertEqual(savedOrders.first?.serviceFee, 2.0)
        XCTAssertEqual(savedOrders.first?.total, 42.0)
    }

    /// The core requirement: only one order may ever be created, no matter
    /// how many times confirm() is called after the first success.
    func test_repeatedConfirmCalls_createOnlyOneOrder() async {
        let repository = InMemoryOrdersRepository()
        let viewModel = OrderConfirmationViewModel(
            product: TestFixtures.product(price: 10.0, stock: 5),
            quantity: 1,
            ordersRepository: repository
        )

        await viewModel.confirm()
        await viewModel.confirm()
        await viewModel.confirm()

        let callCount = await repository.createOrderCallCount
        XCTAssertEqual(callCount, 1)
    }

    /// Two near-simultaneous taps before the first request resolves must
    /// still only create one order — isSubmitting is checked synchronously
    /// before either call awaits the repository.
    func test_concurrentConfirmCalls_createOnlyOneOrder() async {
        let repository = InMemoryOrdersRepository()
        let viewModel = OrderConfirmationViewModel(
            product: TestFixtures.product(price: 10.0, stock: 5),
            quantity: 1,
            ordersRepository: repository
        )

        async let first: Void = viewModel.confirm()
        async let second: Void = viewModel.confirm()
        _ = await (first, second)

        let callCount = await repository.createOrderCallCount
        XCTAssertEqual(callCount, 1)
    }

    func test_invalidQuantity_doesNotCreateOrder() async {
        let repository = InMemoryOrdersRepository()
        let viewModel = OrderConfirmationViewModel(
            product: TestFixtures.product(price: 10.0, stock: 0),
            quantity: 1,
            ordersRepository: repository
        )

        await viewModel.confirm()

        XCTAssertFalse(viewModel.isConfirmed)
        let callCount = await repository.createOrderCallCount
        XCTAssertEqual(callCount, 0)
    }
}
