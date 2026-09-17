import SwiftUI

struct ProductCard: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProductImageView(url: product.thumbnailURL)
                .frame(height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityHidden(true)

            infoStack
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var infoStack: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(product.category.capitalized)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(product.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            RatingView(rating: product.rating)

            HStack {
                Text(product.price, format: .currency(code: "USD"))
                    .font(.subheadline.weight(.bold))
                Spacer()
                if !product.isInStock {
                    Text("Out of stock")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.red)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
