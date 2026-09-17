import SwiftUI

struct OrderHistoryView: View {
    @StateObject private var viewModel: OrderHistoryViewModel

    init(viewModel: @autoclosure @escaping () -> OrderHistoryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.orders.isEmpty {
                    EmptyStateView(
                        systemImage: "clock",
                        title: "No orders yet",
                        message: "Orders you confirm will show up here."
                    )
                } else {
                    List(viewModel.orders) { order in
                        OrderRow(order: order)
                    }
                }
            }
            .navigationTitle("Orders")
            // .onAppear (not .task) so returning to this tab after a new
            // order is confirmed elsewhere always reflects it.
            .onAppear { Task { await viewModel.refresh() } }
        }
    }
}
