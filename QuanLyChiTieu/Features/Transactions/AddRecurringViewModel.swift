import Foundation
import SwiftData

// MARK: - Add Recurring ViewModel

@MainActor @Observable
internal final class AddRecurringViewModel {

    // MARK: - Form State

    internal var selectedType: TransactionType = .expense
    internal var selectedCategory: Category?
    internal var amountText: String = ""
    internal var note: String = ""
    internal var frequency: RecurrenceFrequency = .monthly
    internal var startDate: Date = .now
    internal var hasEndDate: Bool = false
    internal var endDate: Date = .now

    // MARK: - Error State

    internal var errorMessage: String?

    // MARK: - Computed Properties

    internal var parsedAmount: Decimal? {
        amountText.parsedVNDAmount
    }

    internal var hasChanges: Bool {
        !amountText.isEmpty || selectedCategory != nil || !note.isEmpty
    }

    internal var canSave: Bool {
        guard let amount = parsedAmount, amount > 0 else { return false }
        return selectedCategory != nil
    }

    // MARK: - Actions

    internal func clearCategoryOnTypeChange() {
        selectedCategory = nil
    }

    internal func save(context: ModelContext) throws {
        guard let amount = parsedAmount, amount > 0 else { return }

        if hasEndDate && endDate < startDate {
            let dateError = TransactionError.invalidDateRange
            errorMessage = dateError.localizedDescription
            throw dateError
        }

        let recurring = RecurringTransaction(
            amount: amount,
            note: note,
            type: selectedType,
            category: selectedCategory,
            frequency: frequency,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            isActive: true
        )
        context.insert(recurring)

        do {
            try context.save()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
}
