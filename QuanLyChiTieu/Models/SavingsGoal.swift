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

    internal init(
        name: String,
        targetAmount: Decimal,
        currentAmount: Decimal = 0,
        deadline: Date? = nil,
        icon: String,
        colorHex: String,
        createdAt: Date = .now
    ) {
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.deadline = deadline
        self.icon = icon
        self.colorHex = colorHex
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

    #Index<SavingsGoal>([\.createdAt], [\.isArchived])
}
