import SwiftUI

/// Thin AsyncImage wrapper with a placeholder and failure fallback.
/// Deliberately avoids a custom image-caching layer: `URLCache.shared` is
/// sized generously at app launch (see TripStoreApp) so AsyncImage's
/// URLSession-backed loads are cached for free without extra dependencies.
struct ProductImageView: View {
    let url: URL?
    var contentMode: ContentMode = .fill

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: contentMode)
            case .failure:
                placeholder(systemImage: "photo")
            case .empty:
                placeholder(systemImage: nil)
            @unknown default:
                placeholder(systemImage: "photo")
            }
        }
    }

    @ViewBuilder
    private func placeholder(systemImage: String?) -> some View {
        ZStack {
            Rectangle().fill(Color(.secondarySystemBackground))
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
            }
        }
    }
}
