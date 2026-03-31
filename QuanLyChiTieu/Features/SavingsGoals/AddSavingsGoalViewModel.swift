import Foundation
import SwiftData

@MainActor @Observable
internal final class AddSavingsGoalViewModel {

    // MARK: - State

    internal var name: String = ""
    internal var amountText: String = ""
    internal var selectedIcon: String = "fork.knife"
    internal var selectedColorHex: String = "#D7A49A"
    internal var hasDeadline: Bool = false
    internal var deadline: Date = Calendar.current.date(
        byAdding: .month, value: 3, to: .now
    ) ?? .now
    internal var errorMessage: String?

    // MARK: - Computed

    internal var parsedAmount: Decimal? {
        amountText.parsedVNDAmount
    }

    internal var hasChanges: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            || !amountText.isEmpty
            || !selectedIcon.isEmpty
    }

    internal var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && parsedAmount != nil
            && !selectedIcon.isEmpty
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

        guard let amount = parsedAmount else {
            errorMessage = String(localized: "Số tiền mục tiêu phải lớn hơn 0")
            return false
        }

        guard !selectedIcon.isEmpty else {
            errorMessage = String(localized: "Vui lòng chọn biểu tượng")
            return false
        }

        let goal = SavingsGoal(
            name: trimmedName,
            targetAmount: amount,
            deadline: hasDeadline ? deadline : nil,
            icon: selectedIcon,
            colorHex: selectedColorHex
        )
        context.insert(goal)

        do {
            try context.save()
        } catch {
            errorMessage = String(localized: "Không thể lưu mục tiêu")
            return false
        }
        return true
    }
}
