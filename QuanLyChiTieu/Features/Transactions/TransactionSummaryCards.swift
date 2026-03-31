import SwiftUI

// MARK: - TransactionSummaryCards

/// Two side-by-side M3 cards showing total income and total expense.
internal struct TransactionSummaryCards: View {
    private let transactions: [Transaction]

    internal init(transactions: [Transaction]) {
        self.transactions = transactions
    }

    internal var body: some View {
        HStack(spacing: Spacing.md) {
            summaryCard(
                label: String(localized: "Thu nhập"),
                amount: totalIncome,
                color: Color.appIncome,
                prefix: "+"
            )
            summaryCard(
                label: String(localized: "Chi tiêu"),
                amount: totalExpense,
                color: Color.appError,
                prefix: "-"
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }
}

// MARK: - Subviews

private extension TransactionSummaryCards {
    private func summaryCard(
        label: String,
        amount: Decimal,
        color: Color,
        prefix: String
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(Typography.labelMedium)
                .foregroundStyle(Color.onSurfaceVariant)
            Text(formattedAmount(amount, prefix: prefix))
                .font(Typography.titleMediumEmphasized)
                .foregroundStyle(color)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .m3Card(
            cornerRadius: Spacing.cornerExtraLarge,
            background: .surfaceContainerHigh
        )
    }
}

// MARK: - Computed Properties

private extension TransactionSummaryCards {
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

    private func formattedAmount(
        _ amount: Decimal,
        prefix: String
    ) -> String {
        guard amount > 0 else { return "0 \u{20AB}" }
        return "\(prefix)\(amount.formattedVND)"
    }

    private var accessibilityDescription: String {
        let income = totalIncome.formattedVND
        let expense = totalExpense.formattedVND
        return String(localized: "Thu nhập \(income), Chi tiêu \(expense)")
    }
}

// MARK: - Preview

#Preview {
    TransactionSummaryCards(transactions: [])
        .padding()
}
