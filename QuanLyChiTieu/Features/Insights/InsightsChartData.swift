import Foundation

// MARK: - TimePeriod

internal enum TimePeriod: String, CaseIterable, Sendable {
    case week = "Tuần"
    case month = "Tháng"
    case threeMonths = "3 Tháng"
    case year = "Năm"

    internal var displayName: String {
        switch self {
        case .week: String(localized: "Tuần")
        case .month: String(localized: "Tháng")
        case .threeMonths: String(localized: "3 Tháng")
        case .year: String(localized: "Năm")
        }
    }
}

// MARK: - Chart Data Types

internal struct CategoryBreakdownItem: Identifiable, Sendable {
    internal let id: String
    internal let categoryName: String
    internal let icon: String
    internal let colorHex: String
    internal let amount: Decimal
    internal let percentage: Double
}

internal struct MonthlyTrendItem: Identifiable, Sendable {
    internal let id: String
    internal let monthLabel: String
    internal let monthIndex: Int
    internal let amount: Decimal
    internal let isCurrentMonth: Bool
}

internal struct IncomeExpenseItem: Identifiable, Sendable {
    internal let id: String
    internal let monthLabel: String
    internal let monthIndex: Int
    internal let income: Decimal
    internal let expense: Decimal
    internal let isCurrentMonth: Bool
    internal var netSavings: Decimal { income - expense }
}

internal struct DailyTrendItem: Identifiable, Sendable {
    internal let id: String
    internal let dayLabel: String
    internal let date: Date
    internal let amount: Decimal
    internal let isToday: Bool
}

internal struct SavingsRateData: Sendable {
    internal let income: Decimal
    internal let expense: Decimal
    internal var savings: Decimal { income - expense }
    internal var rate: Double {
        guard income > 0 else { return 0 }
        let ratio = savings / income
        return NSDecimalNumber(decimal: ratio).doubleValue * 100
    }
}
