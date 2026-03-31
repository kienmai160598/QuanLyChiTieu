import Foundation
import SwiftData

// MARK: - RecurringSavingsDeposit

@Model
internal final class RecurringSavingsDeposit {
    internal var amount: Decimal
    internal var frequency: RecurrenceFrequency
    internal var startDate: Date
    internal var endDate: Date?
    internal var isActive: Bool
    internal var lastDepositDate: Date?

    @Relationship(deleteRule: .nullify)
    internal var goal: SavingsGoal?

    internal init(
        amount: Decimal,
        frequency: RecurrenceFrequency = .monthly,
        startDate: Date = .now,
        endDate: Date? = nil,
        isActive: Bool = true,
        lastDepositDate: Date? = nil,
        goal: SavingsGoal? = nil
    ) {
        self.amount = amount
        self.frequency = frequency
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.lastDepositDate = lastDepositDate
        self.goal = goal
    }

    // MARK: - Computed

    internal var formattedAmount: String {
        amount.formattedVND
    }

    internal var scheduleDescription: String {
        String(
            localized: "\(formattedAmount) \(frequency.displayName.lowercased())"
        )
    }

    internal var isExpired: Bool {
        guard let endDate else { return false }
        return Date.now > endDate
    }

    #Index<RecurringSavingsDeposit>([\.isActive], [\.startDate])
}
