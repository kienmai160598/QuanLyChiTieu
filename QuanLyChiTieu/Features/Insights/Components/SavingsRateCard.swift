import SwiftUI

internal struct SavingsRateCard: View {
    internal let data: SavingsRateData
    internal let formatVND: (Decimal) -> String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    internal var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader
            rateDisplay
            savingsBreakdown
        }
        .padding(Spacing.lg)
        .m3Card(cornerRadius: Spacing.cornerLarge)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "Tỷ lệ tiết kiệm"))
        .accessibilityValue(accessibilityText)
    }

    // MARK: - Header

    private var sectionHeader: some View {
        Label(String(localized: "Tỷ lệ tiết kiệm"), systemImage: "leaf.fill")
            .font(Typography.titleSmall)
            .foregroundStyle(Color.onSurface)
    }

    // MARK: - Rate Display

    private var rateDisplay: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(rateText)
                .font(Typography.heroLarge)
                .monospacedDigit()
                .foregroundStyle(rateColor)
                .contentTransition(.numericText())
                .animation(reduceMotion ? .none : Motion.effectDefault, value: data.rate)
            Spacer()
            rateIndicator
        }
    }

    private var rateIndicator: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: rateIconName)
                .font(Typography.labelMedium)
            Text(rateLabel)
                .font(Typography.labelSmall)
        }
        .foregroundStyle(rateColor)
    }

    // MARK: - Breakdown

    private var savingsBreakdown: some View {
        VStack(spacing: Spacing.sm) {
            breakdownRow(
                label: String(localized: "Thu nhập"),
                amount: data.income,
                color: .appIncome
            )
            breakdownRow(
                label: String(localized: "Chi tiêu"),
                amount: data.expense,
                color: .appError
            )
            Divider().foregroundStyle(Color.outlineVariant)
            breakdownRow(
                label: String(localized: "Tiết kiệm"),
                amount: data.savings,
                color: rateColor
            )
        }
    }

    private func breakdownRow(label: String, amount: Decimal, color: Color) -> some View {
        HStack {
            Text(label)
                .font(Typography.bodyMedium)
                .foregroundStyle(Color.onSurfaceVariant)
            Spacer()
            Text(formatVND(amount))
                .font(Typography.labelMedium)
                .monospacedDigit()
                .foregroundStyle(color)
        }
    }

    // MARK: - Computed Properties

    private var rateText: String {
        guard data.income > 0 else { return "0%" }
        return String(format: "%.0f%%", data.rate)
    }

    private var rateColor: Color {
        switch data.rate {
        case 20...: .appIncome
        case 10..<20: .appWarning
        default: .appError
        }
    }

    private var rateIconName: String {
        switch data.rate {
        case 20...: "arrow.up.right"
        case 10..<20: "arrow.right"
        default: "arrow.down.right"
        }
    }

    private var rateLabel: String {
        switch data.rate {
        case 20...: String(localized: "Tốt")
        case 10..<20: String(localized: "Trung bình")
        default: String(localized: "Cần cải thiện")
        }
    }

    private var accessibilityText: String {
        let pct = String(format: "%.0f", data.rate)
        return String(localized: "\(pct) phần trăm, \(rateLabel)")
    }
}
