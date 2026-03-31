import SwiftUI

internal struct BudgetUtilizationCard: View {
    internal let budget: Budget
    internal let spent: Decimal
    internal let formatVND: (Decimal) -> String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    internal var body: some View {
        HStack(spacing: Spacing.md) {
            circularProgress
            budgetDetails
            Spacer()
            amountSummary
        }
        .padding(Spacing.md)
        .m3Card(cornerRadius: Spacing.cornerLarge)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(budget.category?.localizedName ?? String(localized: "Tổng")) ngân sách"))
        .accessibilityValue(accessibilityText)
    }

    // MARK: - Circular Progress

    private var circularProgress: some View {
        ZStack {
            Circle()
                .stroke(progressColor.opacity(0.15), lineWidth: 5)

            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? .none : Motion.effectDefault, value: clampedProgress)

            categoryIcon
        }
        .frame(width: IconSize.containerXXL, height: IconSize.containerXXL)
        .accessibilityLabel(accessibilityText)
    }

    private var categoryIcon: some View {
        Image(systemName: budget.category?.icon ?? "banknote.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(progressColor)
    }

    // MARK: - Details

    private var budgetDetails: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(budget.category?.localizedName ?? String(localized: "Tổng"))
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurface)
                .lineLimit(1)

            Text(progressPercentText)
                .font(Typography.labelSmall)
                .foregroundStyle(progressColor)
        }
    }

    // MARK: - Amount

    private var amountSummary: some View {
        VStack(alignment: .trailing, spacing: Spacing.xs) {
            Text(formatVND(spent))
                .font(Typography.labelMedium)
                .foregroundStyle(progressColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())

            Text("/ \(formatVND(budget.limitAmount))")
                .font(Typography.labelSmall)
                .foregroundStyle(Color.onSurfaceVariant)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    // MARK: - Computed Properties

    private var progress: Double {
        guard budget.limitAmount > 0 else { return 0 }
        let ratio = spent / budget.limitAmount
        return NSDecimalNumber(decimal: ratio).doubleValue
    }

    private var clampedProgress: Double {
        min(max(progress, 0), 1.0)
    }

    private var progressColor: Color {
        switch progress {
        case ..<0.7:
            return .appPrimary
        case 0.7..<0.9:
            return .appWarning
        default:
            return .appError
        }
    }

    private var progressPercentText: String {
        let pct = String(format: "%.0f", progress * 100)
        return String(localized: "\(pct)% đã dùng")
    }

    private var accessibilityText: String {
        let name = budget.category?.localizedName ?? String(localized: "Tổng")
        let pct = String(format: "%.0f", progress * 100)
        return String(localized: "\(name): \(pct) phần trăm đã sử dụng")
    }
}
