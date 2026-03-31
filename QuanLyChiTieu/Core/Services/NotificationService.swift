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

    // MARK: - Savings Milestone Notifications

    internal func scheduleMilestoneNotification(
        for goal: SavingsGoal,
        milestone: Double
    ) async {
        guard await requestAuthorizationIfNeeded() else { return }

        let goalId = goal.persistentModelID.hashValue
        let identifier = "savings-milestone-\(goalId)-\(Int(milestone * 100))"

        let message: String
        switch milestone {
        case 0.25:
            message = String(localized: "Đã hoàn thành 25% mục tiêu \(goal.name)!")
        case 0.50:
            message = String(localized: "Tuyệt vời! Đã đạt 50% mục tiêu \(goal.name)!")
        case 0.75:
            message = String(localized: "Sắp hoàn thành! 75% mục tiêu \(goal.name)!")
        case 1.0:
            message = String(localized: "Chúc mừng! Hoàn thành mục tiêu \(goal.name)! 🎉")
        default:
            return
        }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Mục tiêu tiết kiệm")
        content.body = message
        content.sound = .default

        // Trigger immediately (1 second delay for immediate delivery)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            Self.logger.error(
                "Failed to schedule milestone notification: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Savings Deadline Reminders

    internal func scheduleDeadlineReminder(for goal: SavingsGoal) async {
        guard await requestAuthorizationIfNeeded() else { return }
        guard let deadline = goal.deadline else { return }
        guard !goal.isCompleted else { return }

        let goalId = goal.persistentModelID.hashValue
        let calendar = Calendar.current
        let now = Date()

        // Schedule 7-day reminder
        if let sevenDaysBefore = calendar.date(byAdding: .day, value: -7, to: deadline),
           sevenDaysBefore > now {
            let identifier = "savings-deadline-\(goalId)-7"
            let remainingFormatted = goal.remainingAmount.formattedVND
            let message = String(
                localized: "Còn 7 ngày để hoàn thành \(goal.name). Cần thêm \(remainingFormatted) nữa!"
            )

            await scheduleDeadlineNotification(
                identifier: identifier,
                title: String(localized: "Nhắc nhở mục tiêu"),
                body: message,
                triggerDate: sevenDaysBefore
            )
        }

        // Schedule 1-day reminder
        if let oneDayBefore = calendar.date(byAdding: .day, value: -1, to: deadline),
           oneDayBefore > now {
            let identifier = "savings-deadline-\(goalId)-1"
            let message = String(localized: "Ngày mai là hạn chót cho \(goal.name)!")

            await scheduleDeadlineNotification(
                identifier: identifier,
                title: String(localized: "Nhắc nhở mục tiêu"),
                body: message,
                triggerDate: oneDayBefore
            )
        }
    }

    internal func cancelDeadlineReminders(for goal: SavingsGoal) {
        let goalId = goal.persistentModelID.hashValue
        let identifiers = [
            "savings-deadline-\(goalId)-7",
            "savings-deadline-\(goalId)-1"
        ]
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private func scheduleDeadlineNotification(
        identifier: String,
        title: String,
        body: String,
        triggerDate: Date
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let timeInterval = triggerDate.timeIntervalSince(Date())
        guard timeInterval > 0 else { return }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            Self.logger.error(
                "Failed to schedule deadline notification: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Authorization

    private func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return true
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                Self.logger.error(
                    "Failed to request notification authorization: \(error.localizedDescription)"
                )
                return false
            }
        case .denied, .ephemeral:
            return false
        @unknown default:
            return false
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
