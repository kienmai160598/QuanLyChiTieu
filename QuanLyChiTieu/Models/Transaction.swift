import Foundation
import SwiftData

@Model
internal final class Transaction {
    internal var amount: Decimal
    internal var note: String
    internal var date: Date
    internal var type: TransactionType

    @Relationship(deleteRule: .nullify)
    internal var category: Category?

    internal init(
        amount: Decimal,
        note: String = "",
        date: Date = .now,
        type: TransactionType,
        category: Category? = nil
    ) {
        self.amount = amount
        self.note = note
        self.date = date
        self.type = type
        self.category = category
    }

    // MARK: - Display

    internal var formattedAmount: String {
        amount.formattedVND
    }

    internal var signedFormattedAmount: String {
        switch type {
        case .expense: "-\(formattedAmount)"
        case .income: "+\(formattedAmount)"
        }
    }

    @MainActor
    internal var displayTitle: String {
        note.isEmpty ? (category?.localizedName ?? String(localized: "Không rõ")) : note
    }

    #Index<Transaction>([\.date])
}
