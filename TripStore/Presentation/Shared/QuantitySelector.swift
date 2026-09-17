import SwiftUI

/// Stepper-style quantity control clamped to 1...stock. Fully accessible:
/// VoiceOver gets a single adjustable element instead of two separate
/// unlabeled buttons.
struct QuantitySelector: View {
    @Binding var quantity: Int
    let stock: Int

    var body: some View {
        HStack(spacing: 20) {
            Button {
                quantity = QuantityValidator.clamp(quantity - 1, stock: stock)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
            }
            .disabled(stock <= 0 || quantity <= 1)

            Text("\(quantity)")
                .font(.title3.weight(.semibold))
                .frame(minWidth: 32)
                .monospacedDigit()

            Button {
                quantity = QuantityValidator.clamp(quantity + 1, stock: stock)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            }
            .disabled(stock <= 0 || quantity >= stock)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Quantity")
        .accessibilityValue("\(quantity)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                quantity = QuantityValidator.clamp(quantity + 1, stock: stock)
            case .decrement:
                quantity = QuantityValidator.clamp(quantity - 1, stock: stock)
            @unknown default:
                break
            }
        }
    }
}
