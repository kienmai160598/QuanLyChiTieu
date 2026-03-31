import Foundation
import SwiftData

@MainActor @Observable
internal final class EditSavingsGoalViewModel {

    // MARK: - State

    internal var name: String
    internal var amountText: String
    internal var selectedIcon: String
    internal var selectedColorHex: String
    internal var hasDeadline: Bool
    internal var deadline: Date
    internal var errorMessage: String?

    // MARK: - Private

    private let goal: SavingsGoal
    private let originalName: String
    private let originalAmountText: String
    private let originalIcon: String
    private let originalColorHex: String
    private let originalHasDeadline: Bool
    private let originalDeadline: Date

    // MARK: - Init

    internal init(goal: SavingsGoal) {
        self.goal = goal
        let amountInt = NSDecimalNumber(decimal: goal.targetAmount).intValue.description
        self.name = goal.name
        self.amountText = amountInt
        self.selectedIcon = goal.icon
        self.selectedColorHex = goal.colorHex
        self.hasDeadline = goal.deadline != nil
        self.deadline = goal.deadline ?? Calendar.current.date(
            byAdding: .month, value: 3, to: .now
        ) ?? .now
        self.originalName = goal.name
        self.originalAmountText = amountInt
        self.originalIcon = goal.icon
        self.originalColorHex = goal.colorHex
        self.originalHasDeadline = goal.deadline != nil
        self.originalDeadline = goal.deadline ?? .now
    }

    // MARK: - Computed

    internal var parsedAmount: Decimal? {
        amountText.parsedVNDAmount
    }

    internal var hasChanges: Bool {
        name != originalName
            || amountText != originalAmountText
            || selectedIcon != originalIcon
            || selectedColorHex != originalColorHex
            || hasDeadline != originalHasDeadline
            || (hasDeadline && deadline != originalDeadline)
    }

    internal var canSave: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && parsedAmount != nil && !selectedIcon.isEmpty && hasChanges
    }

    // MARK: - Actions

    internal func clearError() {
        errorMessage = nil
    }

    internal func save(context: ModelContext) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = String(localized: "Vui lòng nhập tên mục tiêu")
            return false
        }

        guard let amount = parsedAmount, amount > 0 else {
            errorMessage = String(localized: "Số tiền mục tiêu phải lớn hơn 0")
            return false
        }

        guard !selectedIcon.isEmpty else {
            errorMessage = String(localized: "Vui lòng chọn biểu tượng")
            return false
        }

        goal.name = trimmedName
        goal.targetAmount = amount
        goal.icon = selectedIcon
        goal.colorHex = selectedColorHex
        goal.deadline = hasDeadline ? deadline : nil

        do {
            try context.save()
        } catch {
            errorMessage = String(localized: "Không thể lưu thay đổi")
            return false
        }
        return true
    }
}
