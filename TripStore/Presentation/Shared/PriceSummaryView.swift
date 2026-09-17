import SwiftUI

struct PriceSummaryView: View {
    let summary: OrderSummary

    var body: some View {
        VStack(spacing: 8) {
            row(label: "Subtotal", value: summary.subtotal)
            row(label: "Service fee (5%)", value: summary.serviceFee)
            Divider()
            row(label: "Total", value: summary.total, emphasized: true)
        }
        .accessibilityElement(children: .combine)
    }

    private func row(label: String, value: Double, emphasized: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(emphasized ? .headline : .subheadline)
                .foregroundStyle(emphasized ? .primary : .secondary)
            Spacer()
            Text(value, format: .currency(code: "USD"))
                .font(emphasized ? .headline : .subheadline)
        }
    }
}
