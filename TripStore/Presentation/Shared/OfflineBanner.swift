import SwiftUI

struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "wifi.slash")
            Text("Offline — showing saved products")
                .font(.footnote.weight(.medium))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.15))
        .foregroundStyle(.orange)
        .accessibilityElement(children: .combine)
    }
}
