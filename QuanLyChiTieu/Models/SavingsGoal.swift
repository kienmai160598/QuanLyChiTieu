import Foundation
import SwiftData

@Model
internal final class SavingsGoal {
    internal var name: String
    internal var targetAmount: Decimal
    internal var currentAmount: Decimal
    internal var deadline: Date?
    internal var icon: String
    internal var colorHex: String
    internal var isArchived: Bool = false
    internal var completedAt: Date?
    internal var createdAt: Date

    // MARK: - Enhanced Savings Properties

    internal var categoryRawValue: String?
    internal var tags: [String] = []
    internal var milestoneNotificationsEnabled: Bool = true
    internal var deadlineReminderEnabled: Bool = true

    // MARK: - Relationships

    @Relationship(deleteRule: .cascade)
    internal var history: [SavingsTransaction]? = []

    @Relationship(deleteRule: .cascade, inverse: \RecurringSavingsDeposit.goal)
    internal var recurringDeposit: RecurringSavingsDeposit?

    // MARK: - Category Accessor

    internal var category: SavingsCategory? {
        get {
            guard let rawValue = categoryRawValue else { return nil }
            return SavingsCategory(rawValue: rawValue)
        }
        set {
            categoryRawValue = newValue?.rawValue
        }
    }

    internal init(
        name: String,
        targetAmount: Decimal,
        currentAmount: Decimal = 0,
        deadline: Date? = nil,
        icon: String,
        colorHex: String,
        category: SavingsCategory? = nil,
        tags: [String] = [],
        milestoneNotificationsEnabled: Bool = true,
        deadlineReminderEnabled: Bool = true,
        createdAt: Date = .now
    ) {
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.deadline = deadline
        self.icon = icon
        self.colorHex = colorHex
        self.categoryRawValue = category?.rawValue
        self.tags = tags
        self.milestoneNotificationsEnabled = milestoneNotificationsEnabled
        self.deadlineReminderEnabled = deadlineReminderEnabled
        self.createdAt = createdAt
    }

    // MARK: - Computed

    internal var isCompleted: Bool {
        currentAmount >= targetAmount
    }

    internal var progress: Double {
        guard targetAmount > 0 else { return 0 }
        let ratio = (currentAmount as NSDecimalNumber).doubleValue
            / (targetAmount as NSDecimalNumber).doubleValue
        return min(max(ratio, 0), 1)
    }

    internal var remainingAmount: Decimal {
        max(targetAmount - currentAmount, 0)
    }

    internal var formattedTarget: String {
        targetAmount.formattedVND
    }

    internal var formattedCurrent: String {
        currentAmount.formattedVND
    }

    internal var formattedRemaining: String {
        remainingAmount.formattedVND
    }

    internal var isExpired: Bool {
        guard let deadline else { return false }
        return !isCompleted && Date.now > deadline
    }

    // MARK: - Deposit Projection Computed Properties

    /// Average monthly deposit based on history (last 3 months)
    internal var averageMonthlyDeposit: Decimal {
        guard let transactions = history, !transactions.isEmpty else { return 0 }

        let calendar = Calendar.current
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: .now) ?? .now

        let recentDeposits = transactions.filter { transaction in
            transaction.isDeposit && transaction.date >= threeMonthsAgo
        }

        guard !recentDeposits.isEmpty else { return 0 }

        let totalDeposits = recentDeposits.reduce(Decimal.zero) { $0 + $1.amount }

        // Calculate months span (minimum 1, maximum 3)
        let oldestDate = recentDeposits.map(\.date).min() ?? .now
        let components = calendar.dateComponents([.month], from: oldestDate, to: .now)
        let monthsSpan = max(1, min(3, (components.month ?? 0) + 1))

        return totalDeposits / Decimal(monthsSpan)
    }

    /// Projected completion date based on average deposit rate
    internal var projectedCompletionDate: Date? {
        guard !isCompleted else { return nil }
        guard averageMonthlyDeposit > 0 else { return nil }

        let remainingDecimal = remainingAmount
        let monthsNeeded = (remainingDecimal as NSDecimalNumber).doubleValue
            / (averageMonthlyDeposit as NSDecimalNumber).doubleValue

        let calendar = Calendar.current
        return calendar.date(
            byAdding: .day,
            value: Int(monthsNeeded * 30),
            to: .now
        )
    }

    /// Daily deposit needed to meet deadline
    internal var dailyDepositNeeded: Decimal? {
        guard !isCompleted else { return nil }
        guard let deadline else { return nil }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: .now, to: deadline)
        guard let daysRemaining = components.day, daysRemaining > 0 else { return nil }

        return remainingAmount / Decimal(daysRemaining)
    }

    /// Monthly deposit needed to meet deadline
    internal var monthlyDepositNeeded: Decimal? {
        guard !isCompleted else { return nil }
        guard let deadline else { return nil }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: .now, to: deadline)

        let months = components.month ?? 0
        let days = components.day ?? 0

        // Convert to fractional months (approximate: 30 days per month)
        let totalMonths = Double(months) + Double(days) / 30.0
        guard totalMonths > 0 else { return nil }

        let remainingDouble = (remainingAmount as NSDecimalNumber).doubleValue
        let monthlyNeeded = remainingDouble / totalMonths

        return Decimal(monthlyNeeded)
    }

    #Index<SavingsGoal>([\.createdAt], [\.isArchived])
}
