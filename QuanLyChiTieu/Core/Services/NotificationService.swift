import UserNotifications
import SwiftData
import OSLog

// MARK: - NotificationService

@MainActor
@Observable
internal final class NotificationService {

    private static let logger = Logger(
        subsystem: "com.quanlychitieu",
        category: "Notifications"
    )

    // MARK: - Budget Alerts

    internal func scheduleBudgetAlerts(
        budgets: [Budget],
        spent: [String: Decimal]
    ) {
        for budget in budgets {
            let categoryName = budget.category?.localizedName
                ?? String(localized: "Không rõ")
            let spentAmount = spent[budget.monthYear + (budget.category?.name ?? "")] ?? 0

            guard budget.limitAmount > 0 else { continue }

            let ratio = spentAmount / budget.limitAmount
            scheduleBudgetNotificationIfNeeded(
                ratio: ratio,
                categoryName: categoryName,
                budgetId: budget.monthYear + (budget.category?.name ?? "")
            )
        }
    }

    private func scheduleBudgetNotificationIfNeeded(
        ratio: Decimal,
        categoryName: String,
        budgetId: String
    ) {
        if ratio >= 1 {
            scheduleNotification(
                id: "budget-exceeded-\(budgetId)",
                title: String(localized: "Vượt ngân sách!"),
                body: String(localized: "Ngân sách \(categoryName) đã hết"),
                date: Date()
            )
        } else if ratio >= Decimal(string: "0.8") ?? 0 {
            scheduleNotification(
                id: "budget-warning-\(budgetId)",
                title: String(localized: "Cảnh báo ngân sách"),
                body: String(localized: "Bạn đã chi 80% ngân sách \(categoryName)"),
                date: Date()
            )
        }
    }

    // MARK: - Recurring Transaction Reminders

    internal func scheduleRecurringReminders(
        transactions: [RecurringTransaction]
    ) {
        let calendar = Calendar.current
        let now = Date()

        for transaction in transactions where transaction.isActive {
            guard let nextDate = nextOccurrence(
                for: transaction, after: now, calendar: calendar
            ) else { continue }

            guard let reminderDate = calendar.date(
                byAdding: .day, value: -1, to: nextDate
            ), reminderDate > now else { continue }

            let note = transaction.note.isEmpty
                ? (transaction.category?.localizedName ?? String(localized: "Giao dịch"))
                : transaction.note

            scheduleNotification(
                id: "recurring-\(transaction.note)-\(nextDate.timeIntervalSince1970)",
                title: String(localized: "Giao dịch sắp tới"),
                body: note,
                date: reminderDate
            )
        }
    }

    // MARK: - Remove All

    internal func removeAllPendingNotifications() {
        UNUserNotificationCenter.current()
            .removeAllPendingNotificationRequests()
    }

    // MARK: - Private Helpers

    private func scheduleNotification(
        id: String,
        title: String,
        body: String,
        date: Date
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour], from: date
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components, repeats: false
        )

        let request = UNNotificationRequest(
            identifier: id, content: content, trigger: trigger
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                Self.logger.error(
                    "Failed to schedule notification: \(error.localizedDescription)"
                )
            }
        }
    }

    private func nextOccurrence(
        for rec: RecurringTransaction,
        after now: Date,
        calendar: Calendar
    ) -> Date? {
        let baseDate = rec.lastGeneratedDate ?? rec.startDate
        return RecurrenceCalculator.nextOccurrence(
            baseDate: baseDate,
            frequency: rec.frequency,
            after: now,
            calendar: calendar
        )
    }
}
