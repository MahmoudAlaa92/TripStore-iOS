import SwiftUI

struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .foregroundStyle(isFavorite ? .red : .secondary)
        }
        .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
        .accessibilityHint(isFavorite ? "Removes this product from your favorites" : "Adds this product to your favorites")
    }
}
