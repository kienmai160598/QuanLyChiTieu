import Foundation
import SwiftData

// MARK: - SavingsTransaction

@Model
internal final class SavingsTransaction {
    internal var amount: Decimal
    internal var date: Date
    internal var note: String
    internal var isAutomatic: Bool

    @Relationship(deleteRule: .nullify, inverse: \SavingsGoal.history)
    internal var goal: SavingsGoal?

    internal init(
        amount: Decimal,
        date: Date = .now,
        note: String = "",
        isAutomatic: Bool = false,
        goal: SavingsGoal? = nil
    ) {
        self.amount = amount
        self.date = date
        self.note = note
        self.isAutomatic = isAutomatic
        self.goal = goal
    }

    // MARK: - Computed

    internal var isDeposit: Bool {
        amount > 0
    }

    internal var isWithdrawal: Bool {
        amount < 0
    }

    internal var formattedAmount: String {
        amount.formattedVND
    }

    internal var signedFormattedAmount: String {
        amount.signedFormattedVND
    }

    #Index<SavingsTransaction>([\.date])
}
