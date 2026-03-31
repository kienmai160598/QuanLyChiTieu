import SwiftUI

// MARK: - Savings History List

internal struct SavingsHistoryList: View {
    internal let transactions: [SavingsTransaction]
    internal var limit: Int?
    internal var showHeader: Bool
    internal var onViewAll: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    internal init(
        transactions: [SavingsTransaction],
        limit: Int? = nil,
        showHeader: Bool = true,
        onViewAll: (() -> Void)? = nil
    ) {
        self.transactions = transactions
        self.limit = limit
        self.showHeader = showHeader
        self.onViewAll = onViewAll
    }

    internal var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if showHeader {
                sectionHeader
            }
            if hasTransactions {
                transactionsList
                if hasMoreItems {
                    viewAllButton
                }
            } else {
                emptyState
            }
        }
    }

    // MARK: - Header

    private var sectionHeader: some View {
        Label(
            String(localized: "Lịch sử giao dịch"),
            systemImage: "list.bullet.rectangle"
        )
        .font(Typography.titleSmall)
        .foregroundStyle(Color.onSurface)
    }

    // MARK: - Transactions List

    private var transactionsList: some View {
        LazyVStack(spacing: Spacing.sm) {
            ForEach(displayedTransactions) { transaction in
                SavingsTransactionRow(transaction: transaction)
            }
        }
    }

    private var sortedTransactions: [SavingsTransaction] {
        transactions.sorted { $0.date > $1.date }
    }

    private var displayedTransactions: [SavingsTransaction] {
        guard let limit else { return sortedTransactions }
        return Array(sortedTransactions.prefix(limit))
    }

    private var hasMoreItems: Bool {
        guard let limit else { return false }
        return sortedTransactions.count > limit
    }

    // MARK: - View All Button

    private var viewAllButton: some View {
        Button {
            HapticService.lightImpact()
            onViewAll?()
        } label: {
            HStack(spacing: Spacing.sm) {
                Text(String(localized: "Xem tất cả"))
                    .font(Typography.labelMediumEmphasized)
                Text("(\(sortedTransactions.count))")
                    .font(Typography.labelMedium)
            }
            .foregroundStyle(Color.appPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "Xem tất cả \(sortedTransactions.count) giao dịch"))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "tray")
                .font(Typography.displayLarge)
                .foregroundStyle(Color.outlineVariant)
            Text(String(localized: "Chưa có giao dịch"))
                .font(Typography.bodyMedium)
                .foregroundStyle(Color.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
        .accessibilityLabel(String(localized: "Chưa có giao dịch tiết kiệm"))
    }

    // MARK: - Helpers

    private var hasTransactions: Bool {
        !transactions.isEmpty
    }
}

// MARK: - Transaction Row

private struct SavingsTransactionRow: View {
    internal let transaction: SavingsTransaction

    internal var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            transactionIcon
            transactionDetails
            Spacer()
            amountLabel
        }
        .padding(.vertical, Spacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Icon

    private var transactionIcon: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor.opacity(0.15))
                .frame(width: 40, height: 40)
            Image(systemName: iconName)
                .font(Typography.bodyMedium)
                .foregroundStyle(iconColor)
        }
    }

    private var iconName: String {
        transaction.isDeposit ? "arrow.down.circle.fill" : "arrow.up.circle.fill"
    }

    private var iconColor: Color {
        transaction.isDeposit ? Color.appIncome : Color.appError
    }

    private var iconBackgroundColor: Color {
        transaction.isDeposit ? Color.appIncome : Color.appError
    }

    // MARK: - Details

    private var transactionDetails: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(spacing: Spacing.xs) {
                Text(transactionTypeLabel)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Color.onSurface)
                if transaction.isAutomatic {
                    automaticBadge
                }
            }
            if !transaction.note.isEmpty {
                Text(transaction.note)
                    .font(Typography.labelSmall)
                    .foregroundStyle(Color.onSurfaceVariant)
                    .lineLimit(1)
            }
            Text(formattedDate)
                .font(Typography.labelSmall)
                .foregroundStyle(Color.onSurfaceVariant)
        }
    }

    private var transactionTypeLabel: String {
        transaction.isDeposit
            ? String(localized: "Nạp tiền")
            : String(localized: "Rút tiền")
    }

    private var automaticBadge: some View {
        Text(String(localized: "Tu dong"))
            .font(Typography.labelSmall)
            .foregroundStyle(Color.onSecondaryContainer)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(
                Color.secondaryContainer,
                in: RoundedRectangle(cornerRadius: Spacing.cornerExtraSmall)
            )
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.string(from: transaction.date)
    }

    // MARK: - Amount

    private var amountLabel: some View {
        Text(formattedAmount)
            .font(Typography.titleSmallEmphasized)
            .monospacedDigit()
            .foregroundStyle(amountColor)
    }

    private var formattedAmount: String {
        let absAmount = abs(transaction.amount)
        let prefix = transaction.isDeposit ? "+" : "-"
        return "\(prefix)\(absAmount.formattedVND)"
    }

    private var amountColor: Color {
        transaction.isDeposit ? Color.appIncome : Color.appError
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        let type = transaction.isDeposit
            ? String(localized: "Nap tien")
            : String(localized: "Rut tien")
        let automatic = transaction.isAutomatic
            ? String(localized: ", tu dong")
            : ""
        let note = transaction.note.isEmpty
            ? ""
            : String(localized: ", ghi chu: \(transaction.note)")
        return "\(type)\(automatic), \(formattedAmount), \(formattedDate)\(note)"
    }
}

// MARK: - Preview

#if DEBUG
#Preview("With Transactions") {
    let mockTransactions = [
        SavingsTransaction(
            amount: 1_000_000,
            date: Date().addingTimeInterval(-86400 * 2),
            note: "Tien luong thang 3",
            isAutomatic: false
        ),
        SavingsTransaction(
            amount: 500_000,
            date: Date().addingTimeInterval(-86400),
            note: "",
            isAutomatic: true
        ),
        SavingsTransaction(
            amount: -200_000,
            date: Date(),
            note: "Rut mua qua sinh nhat",
            isAutomatic: false
        )
    ]
    return ScrollView {
        SavingsHistoryList(transactions: mockTransactions)
            .padding()
    }
}

#Preview("Empty State") {
    SavingsHistoryList(transactions: [])
        .padding()
}
#endif
