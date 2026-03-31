import SwiftUI
import SwiftData

// MARK: - Dashboard ViewModel

@MainActor @Observable
internal final class DashboardViewModel {

    // MARK: - State

    internal private(set) var totalIncome: Decimal = 0
    internal private(set) var totalExpense: Decimal = 0
    internal private(set) var chartBars: [ChartBarData] = []
    internal var chartPeriod: ChartPeriod = .month
    internal private(set) var recentTransactions: [Transaction] = []
    internal private(set) var daysRemaining: Int = 0
    internal private(set) var safeDailyAmount: Decimal = 0
    internal private(set) var selectedMonth: Date = Date().startOfMonth

    // MARK: - Derived Properties

    internal var totalBalance: Decimal { totalIncome - totalExpense }
    internal var formattedIncome: String { totalIncome.formattedVND }
    internal var formattedExpense: String { totalExpense.formattedVND }
    internal var formattedBalance: String { totalBalance.formattedVND }
    internal var formattedSafeDailyAmount: String { safeDailyAmount.formattedVND }

    internal var currentMonthYearName: String {
        selectedMonth.monthYear
    }

    internal var canGoToNextMonth: Bool {
        guard let next = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) else {
            return false
        }
        return next <= Date.now.startOfMonth
    }

    // MARK: - Month Navigation

    internal func goToPreviousMonth() {
        guard let prev = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) else { return }
        selectedMonth = prev.startOfMonth
    }

    internal func goToNextMonth() {
        guard let next = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) else { return }
        guard next <= Date.now.startOfMonth else { return }
        selectedMonth = next.startOfMonth
    }

    // MARK: - Data Loading

    internal func loadData(
        transactions: [Transaction],
        budgets: [Budget],
        recurring: [RecurringTransaction]
    ) {
        let now = Date()
        let start = selectedMonth.startOfMonth
        let end = selectedMonth.endOfMonth
        let monthTx = transactions.filter { $0.date >= start && $0.date <= end }
        let totals = TransactionAggregator.totals(from: monthTx, in: start...end)
        totalIncome = totals.income
        totalExpense = totals.expense
        recentTransactions = Array(monthTx.sorted { $0.date > $1.date }.prefix(5))
        computeTemporalContext(now: now)
        computeDailyPace()
        chartBars = buildChartBars(from: transactions)
    }

    internal func buildChartBars(from transactions: [Transaction]) -> [ChartBarData] {
        let calendar = Calendar.current
        switch chartPeriod {
        case .day:
            return buildDayBars(transactions: transactions, calendar: calendar)
        case .week:
            return buildWeekBars(transactions: transactions, calendar: calendar)
        case .month:
            return buildMonthBars(transactions: transactions, calendar: calendar)
        case .year:
            return buildYearBars(transactions: transactions, calendar: calendar)
        }
    }
}

// MARK: - Chart Bar Builders

private extension DashboardViewModel {
    private func buildDayBars(transactions: [Transaction], calendar: Calendar) -> [ChartBarData] {
        let start = selectedMonth.startOfMonth
        let end = selectedMonth.endOfMonth
        let monthTx = transactions.filter { $0.date >= start && $0.date <= end }
        let days = calendar.range(of: .day, in: .month, for: selectedMonth)?.count ?? 30
        return (1...days).map { day in
            let dayTx = monthTx.filter { calendar.component(.day, from: $0.date) == day }
            return ChartBarData(
                label: "\(day)",
                income: dayTx.filter { $0.type == .income }.reduce(0.0) { $0 + NSDecimalNumber(decimal: $1.amount).doubleValue },
                expense: dayTx.filter { $0.type == .expense }.reduce(0.0) { $0 + NSDecimalNumber(decimal: $1.amount).doubleValue }
            )
        }
    }

    private func buildWeekBars(transactions: [Transaction], calendar: Calendar) -> [ChartBarData] {
        let start = selectedMonth.startOfMonth
        let end = selectedMonth.endOfMonth
        let monthTx = transactions.filter { $0.date >= start && $0.date <= end }
        let weeks = calendar.range(of: .weekOfMonth, in: .month, for: selectedMonth) ?? 1..<6
        return weeks.map { week in
            let weekTx = monthTx.filter { calendar.component(.weekOfMonth, from: $0.date) == week }
            return ChartBarData(
                label: "T\(week)",
                income: weekTx.filter { $0.type == .income }.reduce(0.0) { $0 + NSDecimalNumber(decimal: $1.amount).doubleValue },
                expense: weekTx.filter { $0.type == .expense }.reduce(0.0) { $0 + NSDecimalNumber(decimal: $1.amount).doubleValue }
            )
        }
    }

    private func buildMonthBars(transactions: [Transaction], calendar: Calendar) -> [ChartBarData] {
        let year = calendar.component(.year, from: selectedMonth)
        let yearTx = transactions.filter { calendar.component(.year, from: $0.date) == year }
        return (1...12).map { month in
            let mTx = yearTx.filter { calendar.component(.month, from: $0.date) == month }
            let label = calendar.shortMonthSymbols[month - 1]
            return ChartBarData(
                label: label,
                income: mTx.filter { $0.type == .income }.reduce(0.0) { $0 + NSDecimalNumber(decimal: $1.amount).doubleValue },
                expense: mTx.filter { $0.type == .expense }.reduce(0.0) { $0 + NSDecimalNumber(decimal: $1.amount).doubleValue }
            )
        }
    }

    private func buildYearBars(transactions: [Transaction], calendar: Calendar) -> [ChartBarData] {
        let currentYear = calendar.component(.year, from: Date())
        let grouped = Dictionary(grouping: transactions) { calendar.component(.year, from: $0.date) }
        let minYear = min(grouped.keys.min() ?? currentYear, currentYear - 4)
        return (minYear...currentYear).map { year in
            let yTx = grouped[year] ?? []
            return ChartBarData(
                label: "\(year)",
                income: yTx.filter { $0.type == .income }.reduce(0.0) { $0 + NSDecimalNumber(decimal: $1.amount).doubleValue },
                expense: yTx.filter { $0.type == .expense }.reduce(0.0) { $0 + NSDecimalNumber(decimal: $1.amount).doubleValue }
            )
        }
    }
}

// MARK: - Private Temporal Builders

private extension DashboardViewModel {
    func computeTemporalContext(now: Date) {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: selectedMonth)
        let daysInMonth = range?.count ?? 30
        let daysElapsed: Int
        if calendar.isDate(selectedMonth, equalTo: now, toGranularity: .month) {
            daysElapsed = max(calendar.component(.day, from: now), 1)
        } else if selectedMonth < now.startOfMonth {
            daysElapsed = daysInMonth
        } else {
            daysElapsed = 0
        }
        daysRemaining = max(daysInMonth - daysElapsed, 0)
    }

    func computeDailyPace() {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: selectedMonth)
        let daysInMonth = max(range?.count ?? 30, 1)
        safeDailyAmount = totalBalance > 0 ? totalBalance / Decimal(daysInMonth) : 0
    }
}
