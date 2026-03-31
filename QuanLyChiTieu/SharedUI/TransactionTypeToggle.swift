import SwiftUI

// MARK: - TransactionTypeToggle (M3 Expressive)

/// Shared income/expense toggle with M3E filled/outlined states.
/// M3E: emphasized font when selected, solid fill, spatial spring.
internal struct TransactionTypeToggle: View {
    @Binding internal var selectedType: TransactionType

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    internal var body: some View {
        HStack(spacing: Spacing.sm) {
            typeButton(for: .expense, label: String(localized: "Chi tiêu"))
            typeButton(for: .income, label: String(localized: "Thu nhập"))
        }
        .animation(
            reduceMotion ? .none : Motion.spatialDefault,
            value: selectedType
        )
    }
}

// MARK: - Type Button

private extension TransactionTypeToggle {
    private func typeButton(
        for type: TransactionType,
        label: String
    ) -> some View {
        let isSelected = selectedType == type
        let tintColor = type == .expense ? Color.appError : Color.appIncome

        return Button {
            guard selectedType != type else { return }
            HapticService.lightImpact()
            selectedType = type
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: type.icon)
                    .font(.body.weight(isSelected ? .bold : .semibold))
                Text(label)
                    .font(isSelected ? Typography.labelLargeEmphasized : Typography.labelLarge)
            }
            .foregroundStyle(isSelected ? Color.onPrimary : Color.onSurfaceVariant)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(
                isSelected ? tintColor : Color.surfaceContainerHigh,
                in: .capsule
            )
            .overlay {
                if !isSelected {
                    Capsule()
                        .strokeBorder(Color.outlineVariant, lineWidth: 1)
                }
            }
        }
        .buttonStyle(ExpressivePressStyle())
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
