import SwiftUI

// MARK: - TransactionRowView

/// Shared transaction row matching the Pencil TransactionItem component.
/// Pure visual content — navigation, swipe actions, and context menus
/// are handled by the parent (List or TransactionGroupView).
///
/// Layout: [M3IconBadge 40pt] [VStack: title + date/time] [Spacer] [Amount]
internal struct TransactionRowView: View {
    internal let transaction: Transaction
    internal var showDate: Bool = true

    internal var body: some View {
        HStack(spacing: Spacing.md) {
            M3IconBadge(
                icon: transaction.category?.icon ?? "questionmark.circle",
                size: IconSize.containerLG
            )
            transactionInfo
            Spacer(minLength: Spacing.sm)
            amountLabel
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rowAccessibilityLabel)
        .accessibilityValue(transaction.signedFormattedAmount)
    }
}

// MARK: - Subviews

private extension TransactionRowView {
    private var transactionInfo: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(transaction.displayTitle)
                .font(Typography.bodyLarge)
                .foregroundStyle(Color.onSurface)
                .lineLimit(1)
            if showDate {
                Text(relativeDateTimeLabel)
                    .font(Typography.bodySmall)
                    .foregroundStyle(Color.onSurfaceVariant)
                    .lineLimit(1)
            }
        }
    }

    private var amountLabel: some View {
        Text(transaction.signedFormattedAmount)
            .font(Typography.titleSmall)
            .monospacedDigit()
            .foregroundStyle(transaction.type == .income ? Color.appIncome : Color.appError)
    }

    private var relativeDateTimeLabel: String {
        let calendar = Calendar.current
        let now = Date.now
        let date = transaction.date
        let time = date.formatted(date: .omitted, time: .shortened)

        if calendar.isDateInToday(date) {
            return String(localized: "Hôm nay, \(time)")
        } else if calendar.isDateInYesterday(date) {
            return String(localized: "Hôm qua, \(time)")
        } else if let daysAgo = calendar.dateComponents([.day], from: date, to: now).day, daysAgo < 7 {
            let weekday = date.formatted(.dateTime.weekday(.wide))
            return "\(weekday), \(time)"
        } else {
            return date.formatted(.dateTime.day().month(.abbreviated)) + ", \(time)"
        }
    }

    private var rowAccessibilityLabel: String {
        let category = transaction.category?.localizedName ?? String(localized: "Không rõ")
        let type = transaction.type == .income
            ? String(localized: "Thu nhập")
            : String(localized: "Chi tiêu")
        return "\(transaction.displayTitle), \(category), \(type)"
    }
}
