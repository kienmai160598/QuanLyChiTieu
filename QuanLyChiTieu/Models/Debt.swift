import Foundation
import SwiftData

@Model
internal final class Debt {
    internal var title: String
    internal var personName: String
    internal var principalAmount: Decimal
    internal var remainingAmount: Decimal
    internal var interestRate: Decimal?
    internal var isLent: Bool
    internal var startDate: Date
    internal var dueDate: Date?
    internal var notes: String = ""
    internal var isSettled: Bool = false

    internal init(
        title: String,
        personName: String,
        principalAmount: Decimal,
        remainingAmount: Decimal,
        interestRate: Decimal? = nil,
        isLent: Bool,
        startDate: Date = .now,
        dueDate: Date? = nil,
        notes: String = "",
        isSettled: Bool = false
    ) {
        self.title = title
        self.personName = personName
        self.principalAmount = principalAmount
        self.remainingAmount = remainingAmount
        self.interestRate = interestRate
        self.isLent = isLent
        self.startDate = startDate
        self.dueDate = dueDate
        self.notes = notes
        self.isSettled = isSettled
    }

    // MARK: - Computed

    internal var formattedPrincipal: String {
        principalAmount.formattedVND
    }

    internal var formattedRemaining: String {
        remainingAmount.formattedVND
    }

    internal var isOverdue: Bool {
        guard let dueDate, !isSettled else { return false }
        return Date.now > dueDate
    }

    internal var paidAmount: Decimal {
        principalAmount - remainingAmount
    }

    internal var progress: Double {
        guard principalAmount > 0 else { return 0 }
        let paid = paidAmount
        let ratio = NSDecimalNumber(decimal: paid / principalAmount).doubleValue
        return min(max(ratio, 0), 1)
    }

    #Index<Debt>([\.startDate])
}
