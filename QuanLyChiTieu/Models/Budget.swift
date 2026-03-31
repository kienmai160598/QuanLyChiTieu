import Foundation
import SwiftData

@Model
internal final class Budget {
    internal var limitAmount: Decimal
    internal var monthYear: String // "2026-03"
    internal var isOverallCap: Bool = false
    internal var autoRollover: Bool = false

    @Relationship(deleteRule: .nullify)
    internal var category: Category?

    internal init(
        limitAmount: Decimal,
        monthYear: String,
        category: Category? = nil,
        isOverallCap: Bool = false,
        autoRollover: Bool = false
    ) {
        self.limitAmount = limitAmount
        self.monthYear = monthYear
        self.category = category
        self.isOverallCap = isOverallCap
        self.autoRollover = autoRollover
    }

    // MARK: - Display

    internal var formattedLimit: String {
        limitAmount.formattedVND
    }

    #Index<Budget>([\.monthYear])
}
