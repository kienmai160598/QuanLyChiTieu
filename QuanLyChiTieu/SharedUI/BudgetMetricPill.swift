import SwiftUI

// MARK: - Budget Metric Pill (M3 Expressive)

/// Flow-pill metric card for budget screens.
/// M3E: cornerExtraLarge shape, emphasized value font.
internal struct BudgetMetricPill: View {
    private let icon: String
    private let label: String
    private let value: String
    private let color: Color
    private let valueFont: Font

    internal init(
        icon: String,
        label: String,
        value: String,
        color: Color,
        valueFont: Font = Typography.titleMediumEmphasized
    ) {
        self.icon = icon
        self.label = label
        self.value = value
        self.color = color
        self.valueFont = valueFont
    }

    internal var body: some View {
        VStack(spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(Typography.labelSmall)
                    .foregroundStyle(color)
                Text(label)
                    .font(Typography.bodySmall)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
            Text(value)
                .font(valueFont)
                .monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(Color.onSurface.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerExtraLarge))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }
}
