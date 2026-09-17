import SwiftUI

struct OrderConfirmationView: View {
    @StateObject private var viewModel: OrderConfirmationViewModel

    init(draft: OrderDraft, ordersRepository: OrdersRepository) {
        _viewModel = StateObject(wrappedValue: OrderConfirmationViewModel(
            product: draft.product,
            quantity: draft.quantity,
            ordersRepository: ordersRepository
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if viewModel.isConfirmed {
                    confirmationBanner
                }

                productRow

                PriceSummaryView(summary: viewModel.summary)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                confirmButton
            }
            .padding(16)
        }
        .navigationTitle("Confirm Order")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var productRow: some View {
        HStack(spacing: 12) {
            ProductImageView(url: viewModel.product.thumbnailURL)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.product.title)
                    .font(.subheadline.weight(.semibold))
                Text("Quantity: \(viewModel.quantity)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    private var confirmationBanner: some View {
        Label("Order placed", systemImage: "checkmark.circle.fill")
            .font(.headline)
            .foregroundStyle(.green)
            .accessibilityLabel("Order placed successfully")
    }

    private var confirmButton: some View {
        Button {
            Task { await viewModel.confirm() }
        } label: {
            HStack {
                if viewModel.isSubmitting {
                    ProgressView().tint(.white)
                }
                Text(viewModel.isConfirmed ? "Order Confirmed" : "Confirm Order")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.isSubmitting || viewModel.isConfirmed)
        .accessibilityHint(viewModel.isConfirmed ? "This order has already been placed" : "Places your order")
    }
}
