import Foundation
import SwiftData

// MARK: - ViewModel

@MainActor @Observable
internal final class InsightsViewModel {
    internal var selectedPeriod: TimePeriod = .month

    private let calendar = Calendar.current

    // MARK: - Date Range

    internal var dateRange: (start: Date, end: Date) {
        let now = Date()
        switch selectedPeriod {
        case .week: return weekRange(for: now)
        case .month: return monthRange(for: now)
        case .threeMonths: return threeMonthRange(for: now)
        case .year: return yearRange(for: now)
        }
    }

    // MARK: - Category Breakdown

    internal func categoryBreakdown(
        from transactions: [Transaction]
    ) -> [CategoryBreakdownItem] {
        let filtered = filteredExpenses(from: transactions)
        let total = filtered.reduce(Decimal.zero) { $0 + $1.amount }
        guard total > 0 else { return [] }

        let grouped = Dictionary(grouping: filtered) { tx in
            tx.category?.localizedName ?? String(localized: "Khác")
        }
        return grouped.map { name, txs in
            buildCategoryItem(name: name, txs: txs, total: total)
        }
        .sorted { $0.amount > $1.amount }
    }

    // MARK: - Monthly Trend

    internal func monthlyTrend(
        from transactions: [Transaction]
    ) -> [MonthlyTrendItem] {
        let range = dateRange
        let expenses = transactions.filter {
            $0.type == .expense
            && $0.date >= range.start && $0.date <= range.end
        }
        let months = monthsInRange(start: range.start, end: range.end)
        return months.compactMap { year, month in
            buildTrendItem(year: year, month: month, expenses: expenses)
        }
    }

    // MARK: - Income vs Expense

    internal func incomeVsExpense(
        from transactions: [Transaction]
    ) -> [IncomeExpenseItem] {
        let range = dateRange
        let filtered = transactions.filter {
            $0.date >= range.start && $0.date <= range.end
        }
        let months = monthsInRange(start: range.start, end: range.end)
        return months.compactMap { year, month in
            buildIncomeExpenseItem(
                year: year, month: month, transactions: filtered
            )
        }
    }

    // MARK: - Daily Trend (Week period)

    internal func dailyTrend(from transactions: [Transaction]) -> [DailyTrendItem] {
        let range = dateRange
        let expenses = transactions.filter {
            $0.type == .expense && $0.date >= range.start && $0.date <= range.end
        }
        return daysInWeek(start: range.start).map { buildDailyItem(date: $0, expenses: expenses) }
    }

    // MARK: - Income Category Breakdown

    internal func incomeCategoryBreakdown(from transactions: [Transaction]) -> [CategoryBreakdownItem] {
        let filtered = filteredIncome(from: transactions)
        let total = filtered.reduce(Decimal.zero) { $0 + $1.amount }
        guard total > 0 else { return [] }
        let grouped = Dictionary(grouping: filtered) { $0.category?.localizedName ?? String(localized: "Khác") }
        return grouped.map { buildCategoryItem(name: $0.key, txs: $0.value, total: total) }
            .sorted { $0.amount > $1.amount }
    }

    // MARK: - Budget Utilization

    internal func budgetSpent(for budget: Budget, transactions: [Transaction]) -> Decimal {
        let range = dateRange
        let expenses = transactions.filter {
            $0.type == .expense && $0.date >= range.start && $0.date <= range.end
        }
        guard let cat = budget.category else {
            return expenses.reduce(Decimal.zero) { $0 + $1.amount }
        }
        let catID = cat.persistentModelID
        return expenses.filter { $0.category?.persistentModelID == catID }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    // MARK: - Savings Rate

    internal func savingsRateData(from transactions: [Transaction]) -> SavingsRateData {
        let range = dateRange
        let totals = TransactionAggregator.totals(
            from: transactions,
            in: range.start...range.end
        )
        return SavingsRateData(income: totals.income, expense: totals.expense)
    }

    // MARK: - Formatting (public for View access)

    internal func formatVND(_ amount: Decimal) -> String {
        amount.formattedVND
    }
}

// MARK: - Private Helpers

private extension InsightsViewModel {
    private func buildCategoryItem(
        name: String, txs: [Transaction], total: Decimal
    ) -> CategoryBreakdownItem {
        let sum = txs.reduce(Decimal.zero) { $0 + $1.amount }
        let pct = doubleFromDecimal(sum / total) * 100
        return CategoryBreakdownItem(
            id: name, categoryName: name,
            icon: txs.first?.category?.icon ?? "ellipsis.circle.fill",
            colorHex: txs.first?.category?.colorHex ?? Category.defaultColorHex,
            amount: sum, percentage: pct
        )
    }

    private func buildTrendItem(
        year: Int, month: Int, expenses: [Transaction]
    ) -> MonthlyTrendItem? {
        guard let date = calendar.date(
            from: DateComponents(year: year, month: month)
        ) else { return nil }
        let monthStart = calendar.startOfMonth(for: date)
        let monthEnd = calendar.endOfMonth(for: date)
        let now = Date()
        let sum = expenses
            .filter { $0.date >= monthStart && $0.date <= monthEnd }
            .reduce(Decimal.zero) { $0 + $1.amount }
        let isCurrent = month == calendar.component(.month, from: now)
            && year == calendar.component(.year, from: now)
        return MonthlyTrendItem(
            id: "month-\(year)-\(month)", monthLabel: String(localized: "Thg \(month)"),
            monthIndex: month, amount: sum, isCurrentMonth: isCurrent
        )
    }

    private func buildIncomeExpenseItem(
        year: Int, month: Int, transactions: [Transaction]
    ) -> IncomeExpenseItem? {
        guard let date = calendar.date(
            from: DateComponents(year: year, month: month)
        ) else { return nil }
        let monthStart = calendar.startOfMonth(for: date)
        let monthEnd = calendar.endOfMonth(for: date)
        let now = Date()
        let monthTxs = transactions.filter {
            $0.date >= monthStart && $0.date <= monthEnd
        }
        let income = monthTxs
            .filter { $0.type == .income }
            .reduce(Decimal.zero) { $0 + $1.amount }
        let expense = monthTxs
            .filter { $0.type == .expense }
            .reduce(Decimal.zero) { $0 + $1.amount }
        let isCurrent = month == calendar.component(.month, from: now)
            && year == calendar.component(.year, from: now)
        return IncomeExpenseItem(
            id: "ie-\(year)-\(month)", monthLabel: String(localized: "Thg \(month)"),
            monthIndex: month, income: income,
            expense: expense, isCurrentMonth: isCurrent
        )
    }

    private func monthsInRange(
        start: Date, end: Date
    ) -> [(year: Int, month: Int)] {
        var result: [(year: Int, month: Int)] = []
        var current = calendar.startOfMonth(for: start)
        let endBound = calendar.startOfMonth(for: end)
        while current <= endBound {
            result.append((
                calendar.component(.year, from: current),
                calendar.component(.month, from: current)
            ))
            guard let next = calendar.date(
                byAdding: .month, value: 1, to: current
            ) else { break }
            current = next
        }
        return result
    }

    private func filteredExpenses(
        from transactions: [Transaction]
    ) -> [Transaction] {
        let range = dateRange
        return transactions.filter {
            $0.type == .expense
            && $0.date >= range.start && $0.date <= range.end
        }
    }

    private func filteredIncome(
        from transactions: [Transaction]
    ) -> [Transaction] {
        let range = dateRange
        return transactions.filter {
            $0.type == .income
            && $0.date >= range.start && $0.date <= range.end
        }
    }

    private func daysInWeek(
        start: Date
    ) -> [Date] {
        (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: start)
        }
    }

    private func buildDailyItem(
        date: Date,
        expenses: [Transaction]
    ) -> DailyTrendItem {
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.endOfDay(for: date)
        let sum = expenses
            .filter { $0.date >= dayStart && $0.date <= dayEnd }
            .reduce(Decimal.zero) { $0 + $1.amount }
        return DailyTrendItem(
            id: "day-\(dayStart.timeIntervalSince1970)",
            dayLabel: vietnameseDayLabel(for: date),
            date: date,
            amount: sum,
            isToday: calendar.isDateInToday(date)
        )
    }

    private func vietnameseDayLabel(for date: Date) -> String {
        let weekday = calendar.component(.weekday, from: date)
        let labels = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"]
        return labels[weekday - 1]
    }

    private func weekRange(for date: Date) -> (Date, Date) {
        let start = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let end = calendar.date(byAdding: .day, value: 6, to: start) ?? date
        return (start, calendar.endOfDay(for: end))
    }

    private func monthRange(for date: Date) -> (Date, Date) {
        (calendar.startOfMonth(for: date), calendar.endOfMonth(for: date))
    }

    private func threeMonthRange(for date: Date) -> (Date, Date) {
        let start = calendar.date(byAdding: .month, value: -2, to: calendar.startOfMonth(for: date)) ?? date
        return (start, calendar.endOfMonth(for: date))
    }

    private func yearRange(for date: Date) -> (Date, Date) {
        let year = calendar.component(.year, from: date)
        let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? date
        let end = calendar.date(from: DateComponents(year: year, month: 12, day: 31)) ?? date
        return (start, calendar.endOfDay(for: end))
    }

    private func doubleFromDecimal(_ value: Decimal) -> Double {
        NSDecimalNumber(decimal: value).doubleValue
    }
}
