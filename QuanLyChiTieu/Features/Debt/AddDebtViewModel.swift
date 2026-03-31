import Foundation
import SwiftData

@MainActor @Observable
internal final class AddDebtViewModel {

    // MARK: - State

    internal var title: String = ""
    internal var personName: String = ""
    internal var amountText: String = ""
    internal var interestRateText: String = ""
    internal var isLent: Bool = true
    internal var startDate: Date = .now
    internal var dueDate: Date = Calendar.current.date(
        byAdding: .month, value: 1, to: .now
    ) ?? .now
    internal var hasDueDate: Bool = true
    internal var notes: String = ""
    internal var errorMessage: String?

    // MARK: - Computed

    internal var parsedAmount: Decimal? {
        amountText.parsedVNDAmount
    }

    internal var parsedInterestRate: Decimal? {
        guard !interestRateText.isEmpty else { return nil }
        let cleaned = interestRateText.replacingOccurrences(of: ",", with: ".")
        return Decimal(string: cleaned)
    }

    internal var hasChanges: Bool {
        !title.isEmpty || !personName.isEmpty || !amountText.isEmpty
    }

    internal var canSave: Bool {
        !title.isEmpty && !personName.isEmpty && parsedAmount != nil
    }

    // MARK: - Actions

    internal func clearError() {
        errorMessage = nil
    }

    internal func save(context: ModelContext) -> Bool {
        guard let amount = validate() else { return false }
        return persistDebt(amount: amount, context: context)
    }

    private func validate() -> Decimal? {
        guard let amount = parsedAmount else {
            errorMessage = String(localized: "Số tiền phải lớn hơn 0")
            return nil
        }
        guard !title.isEmpty else {
            errorMessage = String(localized: "Vui lòng nhập tiêu đề")
            return nil
        }
        guard !personName.isEmpty else {
            errorMessage = String(localized: "Vui lòng nhập tên người")
            return nil
        }
        return amount
    }

    private func persistDebt(amount: Decimal, context: ModelContext) -> Bool {
        let debt = Debt(
            title: title,
            personName: personName,
            principalAmount: amount,
            remainingAmount: amount,
            interestRate: parsedInterestRate,
            isLent: isLent,
            startDate: startDate,
            dueDate: hasDueDate ? dueDate : nil,
            notes: notes
        )
        context.insert(debt)
        do {
            try context.save()
        } catch {
            errorMessage = String(localized: "Không thể lưu khoản nợ")
            return false
        }
        return true
    }
}
