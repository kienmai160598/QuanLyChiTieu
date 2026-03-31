import Foundation
import SwiftData

@Model
internal final class Category {
    internal static let defaultColorHex = "#D7A49A"

    internal var name: String
    internal var icon: String
    internal var colorHex: String
    internal var type: TransactionType

    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    internal var transactions: [Transaction]?

    @Relationship(deleteRule: .nullify, inverse: \Budget.category)
    internal var budgets: [Budget]?

    @Relationship(deleteRule: .nullify, inverse: \RecurringTransaction.category)
    internal var recurringTransactions: [RecurringTransaction]?

    internal init(
        name: String,
        icon: String,
        colorHex: String,
        type: TransactionType
    ) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.type = type
    }

    // MARK: - Localized Display Name

    @MainActor
    internal var localizedName: String {
        let language = LanguageManager.shared.currentLanguage
        guard language == "en" else { return name }
        return Self.vietnameseToEnglish[name] ?? name
    }

    private static let vietnameseToEnglish: [String: String] = [
        "Ăn uống": "Food & Drink",
        "Di chuyển": "Transport",
        "Mua sắm": "Shopping",
        "Giải trí": "Entertainment",
        "Hóa đơn": "Bills",
        "Sức khỏe": "Health",
        "Giáo dục": "Education",
        "Lương": "Salary",
        "Thưởng": "Bonus",
        "Đầu tư": "Investment",
        "Quà tặng": "Gifts",
        "Khác": "Other",
    ]
}

// MARK: - Default Categories

internal extension Category {
    static let defaultExpenseCategories: [(String, String, String)] = [
        ("Ăn uống", "fork.knife", "#D7A49A"),
        ("Di chuyển", "car.fill", "#A4B1BA"),
        ("Mua sắm", "bag.fill", "#B5B89A"),
        ("Giải trí", "gamecontroller.fill", "#E4C9B6"),
        ("Hóa đơn", "doc.text.fill", "#E1DAD3"),
        ("Sức khỏe", "heart.fill", "#D7A49A"),
        ("Giáo dục", "book.fill", "#A4B1BA"),
        ("Khác", "ellipsis.circle.fill", "#3D3633"),
    ]

    static let defaultIncomeCategories: [(String, String, String)] = [
        ("Lương", "banknote.fill", "#D7A49A"),
        ("Thưởng", "gift.fill", "#E4C9B6"),
        ("Đầu tư", "chart.line.uptrend.xyaxis", "#B5B89A"),
        ("Khác", "ellipsis.circle.fill", "#3D3633"),
    ]
}
