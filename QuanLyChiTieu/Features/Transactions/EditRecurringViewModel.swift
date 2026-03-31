import Foundation
import SwiftData

// MARK: - Edit Recurring ViewModel

@MainActor @Observable
internal final class EditRecurringViewModel {

    // MARK: - Editable Fields

    internal var selectedType: TransactionType
    internal var selectedCategory: Category?
    internal var amountText: String
    internal var note: String
    internal var frequency: RecurrenceFrequency
    internal var startDate: Date
    internal var hasEndDate: Bool
    internal var endDate: Date
    internal var showSuccess = false
    internal var errorMessage: String?

    // MARK: - Private

    private let recurring: RecurringTransaction

    // MARK: - Init

    internal init(recurring: RecurringTransaction) {
        self.recurring = recurring
        self.selectedType = recurring.type
        self.selectedCategory = recurring.category
        self.amountText = NSDecimalNumber(
            decimal: recurring.amount
        ).stringValue
        self.note = recurring.note
        self.frequency = recurring.frequency
        self.startDate = recurring.startDate
        self.hasEndDate = recurring.endDate != nil
        self.endDate = recurring.endDate ?? .now
    }

    // MARK: - Validation

    internal var parsedAmount: Decimal? {
        amountText.parsedVNDAmount
    }

    internal var canSave: Bool {
        guard let amount = parsedAmount, amount > 0 else {
            return false
        }
        return selectedCategory != nil
    }

    internal var hasChanges: Bool {
        guard let amount = parsedAmount else { return false }
        let endDateChanged = hasEndDate
            ? endDate != recurring.endDate
            : recurring.endDate != nil
        return amount != recurring.amount
            || selectedType != recurring.type
            || note != recurring.note
            || selectedCategory?.id != recurring.category?.id
            || frequency != recurring.frequency
            || startDate != recurring.startDate
            || endDateChanged
    }

    // MARK: - Actions

    internal func clearCategoryOnTypeChange() {
        selectedCategory = nil
    }

    internal func saveChanges(context: ModelContext) {
        guard let amount = parsedAmount, amount > 0 else { return }

        if hasEndDate && endDate < startDate {
            errorMessage = TransactionError.invalidDateRange.localizedDescription
            return
        }

        recurring.amount = amount
        recurring.type = selectedType
        recurring.note = note
        recurring.category = selectedCategory
        recurring.frequency = frequency
        recurring.startDate = startDate
        recurring.endDate = hasEndDate ? endDate : nil

        do {
            try context.save()
            HapticService.success()
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
