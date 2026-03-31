import Foundation
import SwiftData

@Model
internal final class Event {
    internal var name: String
    internal var icon: String
    internal var colorHex: String
    internal var startDate: Date
    internal var endDate: Date
    internal var budgetLimit: Decimal
    internal var spentAmount: Decimal = 0
    internal var notes: String = ""

    internal init(
        name: String,
        icon: String,
        colorHex: String,
        startDate: Date,
        endDate: Date,
        budgetLimit: Decimal,
        spentAmount: Decimal = 0,
        notes: String = ""
    ) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.startDate = startDate
        self.endDate = endDate
        self.budgetLimit = budgetLimit
        self.spentAmount = spentAmount
        self.notes = notes
    }

    // MARK: - Computed

    internal var formattedBudget: String {
        budgetLimit.formattedVND
    }

    internal var formattedSpent: String {
        spentAmount.formattedVND
    }

    internal var isActive: Bool {
        let now = Date.now
        return now >= startDate && now <= endDate
    }

    internal var remainingBudget: Decimal {
        max(budgetLimit - spentAmount, 0)
    }

    internal var budgetProgress: Double {
        guard budgetLimit > 0 else { return 0 }
        let ratio = NSDecimalNumber(decimal: spentAmount / budgetLimit).doubleValue
        return min(max(ratio, 0), 1)
    }

    #Index<Event>([\.startDate])
}
