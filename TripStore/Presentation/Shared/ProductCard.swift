import SwiftUI

struct ProductCard: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProductImageView(url: product.thumbnailURL)
                .frame(height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

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
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityLabel: String {
        var parts = [product.title, product.category]
        parts.append(String(format: "Rating %.1f out of 5", product.rating))
        parts.append(product.price.formatted(.currency(code: "USD")))
        if !product.isInStock { parts.append("Out of stock") }
        return parts.joined(separator: ", ")
    }
}
