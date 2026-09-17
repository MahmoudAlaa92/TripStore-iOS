import SwiftUI

struct ProductDetailsView: View {
    @StateObject private var viewModel: ProductDetailsViewModel
    @EnvironmentObject private var favoritesStore: FavoritesStore

    init(product: Product) {
        _viewModel = StateObject(wrappedValue: ProductDetailsViewModel(product: product))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                gallery

                VStack(alignment: .leading, spacing: 12) {
                    header
                    RatingView(rating: viewModel.product.rating)
                    Text(viewModel.product.description)
                        .font(.body)
                        .foregroundStyle(.secondary)

                    stockLabel

                    Divider()

                    if viewModel.product.isInStock {
                        quantitySection
                        PriceSummaryView(summary: viewModel.orderSummary)
                    }

                    ctaButton
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 24)
        }
        .navigationTitle(viewModel.product.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var gallery: some View {
        let urls = viewModel.product.galleryURLs
        return TabView {
            ForEach(Array(urls.enumerated()), id: \.offset) { index, url in
                ProductImageView(url: url)
                    .clipped()
                    .accessibilityLabel("Photo \(index + 1) of \(urls.count)")
            }
        }
        .tabViewStyle(.page)
        .frame(height: 280)
        .background(Color(.secondarySystemBackground))
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.product.category.capitalized)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(viewModel.product.title)
                    .font(.title2.weight(.bold))
                Text(viewModel.product.price, format: .currency(code: "USD"))
                    .font(.title3.weight(.semibold))
            }
            Spacer()
            FavoriteButton(isFavorite: favoritesStore.isFavorite(viewModel.product.id)) {
                Task { await favoritesStore.toggle(viewModel.product) }
            }
            .font(.title2)
        }
    }

    @ViewBuilder
    private var stockLabel: some View {
        if viewModel.product.isInStock {
            Label("\(viewModel.product.stock) in stock", systemImage: "shippingbox")
                .font(.footnote)
                .foregroundStyle(.secondary)
        } else {
            Label("Out of stock", systemImage: "xmark.circle")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.red)
        }
    }

    private var quantitySection: some View {
        HStack {
            Text("Quantity")
                .font(.subheadline.weight(.medium))
            Spacer()
            QuantitySelector(quantity: $viewModel.quantity, stock: viewModel.product.stock)
        }
    }

    private var ctaButton: some View {
        Group {
            if viewModel.product.isInStock {
                NavigationLink(value: OrderDraft(product: viewModel.product, quantity: viewModel.quantity)) {
                    Text("Book Now")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canOrder)
                .accessibilityHint(viewModel.canOrder ? "Reviews your order before confirming" : "Choose a valid quantity to continue")
            } else {
                Text("This product is currently out of stock")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(.top, 8)
    }
}
