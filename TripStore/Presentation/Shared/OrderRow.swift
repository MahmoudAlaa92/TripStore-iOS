import SwiftUI

struct OrderRow: View {
    let order: Order

    var body: some View {
        HStack(spacing: 12) {
            ProductImageView(url: order.productThumbnailURL)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(order.productTitle)
                    .font(.subheadline.weight(.semibold))
                Text("Qty \(order.quantity) · \(order.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Order #\(order.id.uuidString.prefix(8))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Text(order.total, format: .currency(code: "USD"))
                .font(.subheadline.weight(.semibold))
        }
        .accessibilityElement(children: .combine)
    }
}
