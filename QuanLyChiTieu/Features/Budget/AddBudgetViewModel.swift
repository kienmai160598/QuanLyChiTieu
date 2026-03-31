import Foundation
import SwiftData

internal enum BudgetMode: String, CaseIterable, Sendable {
    case category
    case overallCap

    internal var label: String {
        switch self {
        case .category: return String(localized: "Ngân sách danh mục")
        case .overallCap: return String(localized: "Hạn mức tổng tháng")
        }
    }
}

@MainActor @Observable
internal final class AddBudgetViewModel {

    // MARK: - State

    internal var selectedCategory: Category?
    internal var limitText: String = ""
    internal var errorMessage: String?
    internal var editingBudget: Budget?
    internal var monthYear: String = Date().monthYearKey
    internal var budgetMode: BudgetMode = .category
    internal var autoRollover: Bool = false

    internal var isEditing: Bool { editingBudget != nil }

    // MARK: - Computed

    internal var parsedLimit: Decimal? {
        limitText.parsedVNDAmount
    }

    internal var hasChanges: Bool {
        selectedCategory != nil || !limitText.isEmpty || budgetMode == .overallCap
    }

    internal var canSave: Bool {
        guard !limitText.isEmpty else { return false }
        if budgetMode == .overallCap { return true }
        return selectedCategory != nil
    }

    // MARK: - Actions

    internal func loadForEdit(_ budget: Budget) {
        editingBudget = budget
        selectedCategory = budget.category
        budgetMode = budget.isOverallCap ? .overallCap : .category
        autoRollover = budget.autoRollover
        let intValue = NSDecimalNumber(decimal: budget.limitAmount).intValue
        limitText = String(intValue)
    }

    internal func selectCategory(_ category: Category) {
        selectedCategory = category
        errorMessage = nil
    }

    internal func clearError() { errorMessage = nil }

    internal func save(context: ModelContext, existingBudgets: [Budget]) -> Bool {
        guard let amount = parsedLimit else {
            errorMessage = String(localized: "Hạn mức phải lớn hơn 0")
            return false
        }
        if let existing = editingBudget {
            return updateExisting(existing, amount: amount, context: context)
        }
        return createNew(amount: amount, existingBudgets: existingBudgets, context: context)
    }

    // MARK: - Private

    private func updateExisting(_ budget: Budget, amount: Decimal, context: ModelContext) -> Bool {
        budget.limitAmount = amount
        budget.autoRollover = autoRollover
        do {
            try context.save()
        } catch {
            errorMessage = String(localized: "Không thể lưu ngân sách")
            return false
        }
        return true
    }

    private func createNew(
        amount: Decimal,
        existingBudgets: [Budget],
        context: ModelContext
    ) -> Bool {
        if budgetMode == .overallCap {
            return createOverallCap(amount: amount, existingBudgets: existingBudgets, context: context)
        }
        return createCategoryBudget(amount: amount, existingBudgets: existingBudgets, context: context)
    }

    private func createOverallCap(
        amount: Decimal,
        existingBudgets: [Budget],
        context: ModelContext
    ) -> Bool {
        if existingBudgets.contains(where: { $0.isOverallCap }) {
            errorMessage = String(localized: "Đã có hạn mức tổng cho tháng này")
            return false
        }
        let budget = Budget(
            limitAmount: amount,
            monthYear: monthYear,
            isOverallCap: true,
            autoRollover: autoRollover
        )
        return insertAndSave(budget, context: context)
    }

    private func createCategoryBudget(
        amount: Decimal,
        existingBudgets: [Budget],
        context: ModelContext
    ) -> Bool {
        if let selected = selectedCategory,
           existingBudgets.contains(where: {
               $0.category?.persistentModelID == selected.persistentModelID
               && $0.monthYear == monthYear
           }) {
            errorMessage = String(localized: "Đã có ngân sách cho danh mục này trong tháng")
            return false
        }
        let budget = Budget(
            limitAmount: amount,
            monthYear: monthYear,
            category: selectedCategory,
            autoRollover: autoRollover
        )
        return insertAndSave(budget, context: context)
    }

    private func insertAndSave(_ budget: Budget, context: ModelContext) -> Bool {
        context.insert(budget)
        do {
            try context.save()
        } catch {
            errorMessage = String(localized: "Không thể lưu ngân sách")
            return false
        }
        return true
    }
}
