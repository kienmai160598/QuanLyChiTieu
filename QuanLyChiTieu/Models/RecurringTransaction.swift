import Foundation
import SwiftData

// MARK: - RecurrenceFrequency

internal enum RecurrenceFrequency: String, Codable, CaseIterable, Sendable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"

    internal var displayName: String {
        switch self {
        case .daily: String(localized: "Hàng ngày")
        case .weekly: String(localized: "Hàng tuần")
        case .monthly: String(localized: "Hàng tháng")
        case .yearly: String(localized: "Hàng năm")
        }
    }

    internal var icon: String {
        switch self {
        case .daily: "clock.arrow.circlepath"
        case .weekly: "calendar.badge.clock"
        case .monthly: "calendar.circle"
        case .yearly: "calendar.badge.exclamationmark"
        }
    }
}

// MARK: - RecurringTransaction

@Model
internal final class RecurringTransaction {
    internal var amount: Decimal
    internal var note: String
    internal var type: TransactionType

    @Relationship(deleteRule: .nullify)
    internal var category: Category?

    internal var frequency: RecurrenceFrequency
    internal var startDate: Date
    internal var endDate: Date?
    internal var isActive: Bool
    internal var lastGeneratedDate: Date?

    internal init(
        amount: Decimal,
        note: String = "",
        type: TransactionType,
        category: Category? = nil,
        frequency: RecurrenceFrequency = .monthly,
        startDate: Date = .now,
        endDate: Date? = nil,
        isActive: Bool = true,
        lastGeneratedDate: Date? = nil
    ) {
        self.amount = amount
        self.note = note
        self.type = type
        self.category = category
        self.frequency = frequency
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.lastGeneratedDate = lastGeneratedDate
    }

    // MARK: - Display

    internal var formattedAmount: String {
        amount.formattedVND
    }
}
