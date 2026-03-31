import SwiftUI

internal enum TransactionType: String, Codable, CaseIterable, Sendable {
    case expense = "expense"
    case income = "income"

    internal var displayName: String {
        switch self {
        case .expense: String(localized: "Chi tiêu")
        case .income: String(localized: "Thu nhập")
        }
    }

    internal var icon: String {
        switch self {
        case .expense: "arrow.up.circle"
        case .income: "arrow.down.circle"
        }
    }

    internal var color: Color {
        switch self {
        case .expense: Color.appError
        case .income: Color.appIncome
        }
    }
}
