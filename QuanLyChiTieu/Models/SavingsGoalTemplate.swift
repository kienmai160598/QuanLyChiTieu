import Foundation

// MARK: - SavingsGoalTemplate

internal struct SavingsGoalTemplate: Sendable, Identifiable {
    internal let id: String
    internal let name: String
    internal let suggestedAmount: Decimal
    internal let suggestedDeadlineMonths: Int?
    internal let icon: String
    internal let colorHex: String
    internal let category: SavingsCategory

    internal init(
        id: String,
        name: String,
        suggestedAmount: Decimal,
        suggestedDeadlineMonths: Int? = nil,
        icon: String,
        colorHex: String,
        category: SavingsCategory
    ) {
        self.id = id
        self.name = name
        self.suggestedAmount = suggestedAmount
        self.suggestedDeadlineMonths = suggestedDeadlineMonths
        self.icon = icon
        self.colorHex = colorHex
        self.category = category
    }

    // MARK: - Computed

    internal var formattedSuggestedAmount: String {
        suggestedAmount.formattedVND
    }

    internal var deadlineDescription: String? {
        guard let months = suggestedDeadlineMonths else { return nil }
        if months == 1 {
            return String(localized: "1 tháng")
        }
        return String(localized: "\(months) tháng")
    }
}

// MARK: - Predefined Templates

internal extension SavingsGoalTemplate {
    static let all: [SavingsGoalTemplate] = [
        emergencyFund,
        vacation,
        newPhone,
        homeDownPayment,
        education
    ]

    static let emergencyFund = SavingsGoalTemplate(
        id: "emergency_fund",
        name: String(localized: "Quỹ khẩn cấp"),
        suggestedAmount: 50_000_000,
        suggestedDeadlineMonths: 6,
        icon: "cross.case.fill",
        colorHex: "#E57373",
        category: .emergency
    )

    static let vacation = SavingsGoalTemplate(
        id: "vacation",
        name: String(localized: "Kỳ nghỉ"),
        suggestedAmount: 15_000_000,
        suggestedDeadlineMonths: 12,
        icon: "airplane",
        colorHex: "#64B5F6",
        category: .travel
    )

    static let newPhone = SavingsGoalTemplate(
        id: "new_phone",
        name: String(localized: "Điện thoại mới"),
        suggestedAmount: 20_000_000,
        suggestedDeadlineMonths: 6,
        icon: "iphone",
        colorHex: "#81C784",
        category: .shortTerm
    )

    static let homeDownPayment = SavingsGoalTemplate(
        id: "home_down_payment",
        name: String(localized: "Tiền đặt cọc nhà"),
        suggestedAmount: 500_000_000,
        suggestedDeadlineMonths: 60,
        icon: "house.fill",
        colorHex: "#FFB74D",
        category: .longTerm
    )

    static let education = SavingsGoalTemplate(
        id: "education",
        name: String(localized: "Học phí"),
        suggestedAmount: 100_000_000,
        suggestedDeadlineMonths: 24,
        icon: "graduationcap.fill",
        colorHex: "#BA68C8",
        category: .education
    )
}
