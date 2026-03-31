import SwiftUI
import SwiftData

@MainActor @Observable
internal final class BudgetListViewModel {

    // MARK: - Sheet State

    internal var isShowingAddSheet: Bool = false
    internal var copySuccess: Bool = false
    internal var rolloverSuccess: Bool = false

    // MARK: - Error Handling

    internal var errorMessage: String?

    // MARK: - Computed Data

    internal private(set) var totalSpent: Decimal = 0
    internal private(set) var totalBudget: Decimal = 0
    internal private(set) var currentMonthExpenses: [Transaction] = []
    internal private(set) var spentByBudget: [PersistentIdentifier: Decimal] = [:]

    // MARK: - Overall Cap

    internal private(set) var overallCapBudget: Budget?
    internal private(set) var overallCapSpent: Decimal = 0

    internal var overallCapAmount: Decimal {
        overallCapBudget?.limitAmount ?? 0
    }

    internal var overallCapProgress: Double {
        guard overallCapAmount > 0 else { return 0 }
        let raw = NSDecimalNumber(decimal: overallCapSpent / overallCapAmount)
        return min(max(raw.doubleValue, 0), 1.0)
    }

    internal var overallCapProgressColor: Color {
        progressTint(for: overallCapProgress)
    }

    internal var formattedCapSpent: String {
        overallCapSpent.formattedVND
    }

    internal var formattedCapRemaining: String {
        let remaining = overallCapAmount - overallCapSpent
        if remaining < 0 {
            return "-\(abs(remaining).formattedVND)"
        }
        return remaining.formattedVND
    }

    internal var capRemainingIsNegative: Bool {
        overallCapAmount - overallCapSpent < 0
    }

    // MARK: - Category Budget Totals

    internal var budgetProgress: Double {
        guard totalBudget > 0 else { return 0 }
        let raw = NSDecimalNumber(decimal: totalSpent / totalBudget)
        return min(max(raw.doubleValue, 0), 1.0)
    }

    internal var progressColor: Color {
        progressTint(for: budgetProgress)
    }

    internal var formattedTotal: String {
        totalBudget.formattedVND
    }

    internal var formattedSpent: String {
        totalSpent.formattedVND
    }

    internal var formattedRemaining: String {
        let remaining = totalBudget - totalSpent
        if remaining < 0 {
            return "-\(abs(remaining).formattedVND)"
        }
        return remaining.formattedVND
    }

    internal var remainingIsNegative: Bool {
        totalBudget - totalSpent < 0
    }

    // MARK: - Data Loading

    internal func loadData(
        budgets: [Budget],
        transactions: [Transaction],
        monthYear: String
    ) {
        let monthExpenses = transactions
            .filter { $0.type == .expense }
            .filter { $0.date.monthYearKey == monthYear }
        currentMonthExpenses = monthExpenses

        overallCapBudget = budgets.first { $0.isOverallCap }
        overallCapSpent = monthExpenses.reduce(0) { $0 + $1.amount }

        let categoryBudgets = budgets.filter { !$0.isOverallCap && $0.category != nil }
        computeCategoryTotals(categoryBudgets)
        preComputeSpent(budgets: categoryBudgets)
    }

    private func computeCategoryTotals(_ budgets: [Budget]) {
        let budgetedCategoryIDs = Set(
            budgets.compactMap { $0.category?.persistentModelID }
        )
        totalSpent = currentMonthExpenses
            .filter { tx in
                guard let catID = tx.category?.persistentModelID else { return false }
                return budgetedCategoryIDs.contains(catID)
            }
            .reduce(0) { $0 + $1.amount }
        totalBudget = budgets.reduce(0) { $0 + $1.limitAmount }
    }

    private func preComputeSpent(budgets: [Budget]) {
        spentByBudget = TransactionAggregator.expensesByCategory(
            from: currentMonthExpenses
        )
    }

    // MARK: - Per-Budget Calculations

    internal func spentFor(_ budget: Budget) -> Decimal {
        guard let catID = budget.category?.persistentModelID else { return .zero }
        return spentByBudget[catID] ?? .zero
    }

    internal func progressFor(_ budget: Budget) -> Double {
        guard budget.limitAmount > 0 else { return 0 }
        let spent = spentFor(budget)
        let raw = NSDecimalNumber(decimal: spent / budget.limitAmount)
        return min(raw.doubleValue, 1.0)
    }

    internal func progressColorFor(_ budget: Budget) -> Color {
        let progress = progressFor(budget)
        if progress >= 0.9 { return Color.appError }
        if progress >= 0.7 { return Color.appWarning }
        return budget.category.map { Color(hex: $0.colorHex) } ?? .appPrimary
    }

    // MARK: - Actions

    internal func deleteBudget(_ budget: Budget, context: ModelContext) {
        context.delete(budget)
        do {
            try context.save()
        } catch {
            errorMessage = String(localized: "Không thể xoá ngân sách")
        }
    }

    internal func copyBudgetsToNextMonth(
        budgets: [Budget],
        currentMonthYear: String,
        context: ModelContext
    ) {
        let nextKey = Self.nextMonthKey(from: currentMonthYear)
        let existing = fetchBudgets(for: nextKey, context: context)
        let existingCategoryIDs = Set(
            existing.compactMap { $0.category?.persistentModelID }
        )
        let hasExistingCap = existing.contains { $0.isOverallCap }

        for budget in budgets {
            if budget.isOverallCap {
                guard !hasExistingCap else { continue }
            } else {
                guard let cat = budget.category else { continue }
                guard !existingCategoryIDs.contains(cat.persistentModelID) else { continue }
            }
            insertCopy(of: budget, monthYear: nextKey, context: context)
        }
        saveCopy(context: context)
    }

    // MARK: - Auto Rollover

    internal func autoRolloverIfNeeded(
        currentMonth: String,
        currentBudgets: [Budget],
        context: ModelContext
    ) {
        guard currentBudgets.isEmpty else { return }
        let prevKey = Self.previousMonthKey(from: currentMonth)
        let prevBudgets = fetchBudgets(for: prevKey, context: context)
            .filter { $0.autoRollover }
        guard !prevBudgets.isEmpty else { return }

        for budget in prevBudgets {
            insertCopy(of: budget, monthYear: currentMonth, context: context)
        }
        do {
            try context.save()
            rolloverSuccess = true
        } catch {
            errorMessage = String(localized: "Không thể tự động chuyển ngân sách")
        }
    }

    // MARK: - Month Navigation

    internal static func nextMonthKey(from key: String) -> String {
        offsetMonthKey(from: key, by: 1)
    }

    internal static func previousMonthKey(from key: String) -> String {
        offsetMonthKey(from: key, by: -1)
    }

    internal static func displayLabel(for monthYear: String) -> String {
        guard let date = dateFromMonthYearKey(monthYear) else {
            return monthYear
        }
        return date.formatted(
            .dateTime.month(.wide).year()
                .locale(Locale(identifier: "vi"))
        )
    }

    internal static func formatVND(_ amount: Decimal) -> String {
        amount.formattedVND
    }

    // MARK: - Private Helpers

    private func progressTint(for progress: Double) -> Color {
        switch progress {
        case 0.9...: return Color.appError
        case 0.7...: return Color.appWarning
        default: return Color.appPrimary
        }
    }

    private func fetchBudgets(for monthYear: String, context: ModelContext) -> [Budget] {
        let targetMonth = monthYear
        let descriptor = FetchDescriptor<Budget>(
            predicate: #Predicate { $0.monthYear == targetMonth }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    private func insertCopy(of budget: Budget, monthYear: String, context: ModelContext) {
        let copy = Budget(
            limitAmount: budget.limitAmount,
            monthYear: monthYear,
            category: budget.isOverallCap ? nil : budget.category,
            isOverallCap: budget.isOverallCap,
            autoRollover: budget.autoRollover
        )
        context.insert(copy)
    }

    private func saveCopy(context: ModelContext) {
        do {
            try context.save()
            copySuccess = true
        } catch {
            errorMessage = String(localized: "Không thể sao chép ngân sách")
        }
    }

    private static func offsetMonthKey(from key: String, by offset: Int) -> String {
        guard let date = dateFromMonthYearKey(key) else { return key }
        let calendar = Calendar.current
        guard let newDate = calendar.date(byAdding: .month, value: offset, to: date) else {
            return key
        }
        return newDate.monthYearKey
    }

    private static func dateFromMonthYearKey(_ key: String) -> Date? {
        let parts = key.split(separator: "-")
        guard parts.count == 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]) else {
            return nil
        }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        return Calendar.current.date(from: components)
    }
}
