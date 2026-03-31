import Foundation
import SwiftData

@MainActor @Observable
internal final class TetBudgetViewModel {

    // MARK: - State

    internal var startDate: Date
    internal var endDate: Date
    internal var savingsTarget: Decimal = 0
    internal var savingsTargetText: String = ""
    internal var errorMessage: String?

    // MARK: - Computed Data

    internal private(set) var spentByCategory: [String: Decimal] = [:]
    internal private(set) var totalReceived: Decimal = 0

    internal var totalSpent: Decimal {
        spentByCategory.values.reduce(0, +)
    }

    internal var netAmount: Decimal {
        totalReceived - totalSpent
    }

    internal var budgetRemaining: Decimal {
        savingsTarget - totalSpent
    }

    internal var formattedTotalSpent: String {
        totalSpent.formattedVND
    }

    internal var formattedTotalReceived: String {
        totalReceived.formattedVND
    }

    internal var formattedNet: String {
        netAmount.formattedVND
    }

    internal var formattedRemaining: String {
        budgetRemaining.formattedVND
    }

    internal var remainingIsNegative: Bool {
        budgetRemaining < 0
    }

    // MARK: - Init

    internal init() {
        let calendar = Calendar.current
        let tetDate = Self.tetDate(for: 2027)
        let start = calendar.date(byAdding: .day, value: -7, to: tetDate) ?? tetDate
        let end = calendar.date(byAdding: .day, value: 7, to: tetDate) ?? tetDate
        self.startDate = start
        self.endDate = end
    }

    // MARK: - Data Loading

    internal func loadData(transactions: [Transaction]) {
        let tetTransactions = transactions.filter {
            $0.date >= startDate && $0.date <= endDate
        }
        computeSpentByCategory(tetTransactions)
        computeReceived(tetTransactions)
        parseSavingsTarget()
    }

    private func computeSpentByCategory(_ transactions: [Transaction]) {
        let expenses = transactions.filter { $0.type == .expense }
        var spent: [String: Decimal] = [:]
        for tx in expenses {
            let key = tx.category?.localizedName ?? String(localized: "Khác")
            spent[key, default: 0] += tx.amount
        }
        spentByCategory = spent
    }

    private func computeReceived(_ transactions: [Transaction]) {
        totalReceived = transactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }

    private func parseSavingsTarget() {
        savingsTarget = savingsTargetText.parsedVNDAmount ?? 0
    }

    internal func updateSavingsTarget() {
        parseSavingsTarget()
    }

    // MARK: - Tet Date Calculation

    private static func tetDate(for year: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = 1
        components.day = 29
        return Calendar.current.date(from: components) ?? .now
    }
}
