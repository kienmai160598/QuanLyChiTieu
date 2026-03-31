import SwiftUI

// MARK: - Dashboard Supporting Types

internal struct YearlySpending: Identifiable, Sendable {
    internal let year: Int
    internal let label: String
    internal let amount: Double
    internal let isCurrent: Bool
    internal var id: Int { year }
}

// MARK: - Chart Period

internal enum ChartPeriod: String, CaseIterable, Sendable {
    case day = "Ngày"
    case week = "Tuần"
    case month = "Tháng"
    case year = "Năm"

    internal var localizedName: String {
        switch self {
        case .day: String(localized: "Ngày")
        case .week: String(localized: "Tuần")
        case .month: String(localized: "Tháng")
        case .year: String(localized: "Năm")
        }
    }
}

// MARK: - Chart Bar Data

internal struct ChartBarData: Identifiable, Sendable {
    internal let label: String
    internal let income: Double
    internal let expense: Double
    internal var id: String { label }
}

// MARK: - Pill Arc Slice (used by SharedUI/PillArcChart)

internal struct PillArcSlice: Identifiable, Sendable {
    internal let id: String
    internal let label: String
    internal let icon: String
    internal let value: Double   // ratio 0-1
    internal let color: Color
}

// MARK: - Upcoming Recurring (used by UpcomingRecurringBuilder)

internal struct UpcomingRecurring: Identifiable, Sendable {
    internal var id: String { note + icon + formattedAmount + String(daysUntilNext) }
    internal let note: String
    internal let amount: Decimal
    internal let formattedAmount: String
    internal let nextDate: Date
    internal let daysUntilNext: Int
    internal let icon: String
    internal let colorHex: String
    internal let isExpense: Bool
}
