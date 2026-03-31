import SwiftUI

// MARK: - Summary Bar

/// Compact capsule showing total income and expense for filtered transactions.
internal struct TransactionSummaryBar: View {
    internal let transactions: [Transaction]
    internal let filterType: TransactionType?

    internal init(transactions: [Transaction], filterType: TransactionType? = nil) {
        self.transactions = transactions
        self.filterType = filterType
    }

    internal var body: some View {
        HStack(spacing: Spacing.lg) {
            if filterType != .expense {
                summaryItem(
                    label: String(localized: "Thu"),
                    amount: totalIncome,
                    color: Color.appIncome
                )
            }

            if filterType == nil {
                capsuleDivider
            }

            if filterType != .income {
                summaryItem(
                    label: String(localized: "Chi"),
                    amount: totalExpense,
                    color: Color.appError
                )
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
        .frame(maxWidth: .infinity)
        .m3Card(cornerRadius: Spacing.cornerExtraLarge, background: .surfaceContainerHigh)
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }
}

// MARK: - Subviews

private extension TransactionSummaryBar {
    private func summaryItem(
        label: String,
        amount: Decimal,
        color: Color
    ) -> some View {
        HStack(spacing: Spacing.xs) {
            Text(label)
                .font(Typography.labelLarge)
                .foregroundStyle(Color.onSurfaceVariant)
            Text(amount.formattedVND)
                .font(Typography.titleSmall)
                .monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1)
        }
    }

    private var capsuleDivider: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(Color.outlineVariant.opacity(0.5))
            .frame(width: 1, height: Spacing.xl)
    }
}

// MARK: - Computed Properties

private extension TransactionSummaryBar {
    private var totalIncome: Decimal {
        transactions
            .filter { $0.type == .income }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    private var totalExpense: Decimal {
        transactions
            .filter { $0.type == .expense }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    private var accessibilityDescription: String {
        let income = totalIncome.formattedVND
        let expense = totalExpense.formattedVND
        return String(localized: "Thu nhập \(income), Chi tiêu \(expense)")
    }
}
