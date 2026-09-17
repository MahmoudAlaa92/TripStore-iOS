import SwiftUI

/// `FavoritesStore` already holds exactly the state this screen needs
/// (the list, load-on-appear, remove) — a pass-through ViewModel here would
/// just forward calls without adding behavior, so the view observes the
/// shared store directly.
struct FavoritesView: View {
    @EnvironmentObject private var favoritesStore: FavoritesStore

    var body: some View {
        NavigationStack {
            Group {
                if favoritesStore.favorites.isEmpty {
                    EmptyStateView(
                        systemImage: "heart",
                        title: "No favorites yet",
                        message: "Tap the heart on any product to save it here."
                    )
                } else {
                    List {
                        ForEach(favoritesStore.favorites) { favorite in
                            FavoriteRow(favorite: favorite)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let productId = favoritesStore.favorites[index].productId
                                Task { await favoritesStore.remove(productId: productId) }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Favorites")
            .task { await favoritesStore.loadIfNeeded() }
        }
    }
}

private struct FavoriteRow: View {
    let favorite: FavoriteProduct

    var body: some View {
        HStack(spacing: 12) {
            ProductImageView(url: favorite.thumbnailURL)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(favorite.title)
                    .font(.subheadline.weight(.semibold))
                Text(favorite.category.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                RatingView(rating: favorite.rating)
            }

            Spacer()

            Text(favorite.price, format: .currency(code: "USD"))
                .font(.subheadline.weight(.semibold))
        }
        .accessibilityElement(children: .combine)
    }
}
