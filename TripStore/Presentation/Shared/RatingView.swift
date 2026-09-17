import SwiftUI

/// Compact 5-star rating readout. Renders full/half/empty stars visually but
/// exposes a single combined accessibility label so VoiceOver reads one
/// sentence instead of five separate star glyphs.
struct RatingView: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                image(for: index)
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rating \(String(format: "%.1f", rating)) out of 5")
    }

    private func image(for index: Int) -> Image {
        let threshold = Double(index)
        if rating >= threshold + 1 {
            return Image(systemName: "star.fill")
        } else if rating > threshold {
            return Image(systemName: "star.leadinghalf.filled")
        } else {
            return Image(systemName: "star")
        }
    }
}

#Preview {
    VStack(alignment: .leading) {
        RatingView(rating: 4.5)
        RatingView(rating: 3.0)
        RatingView(rating: 0)
    }
    .padding()
}
