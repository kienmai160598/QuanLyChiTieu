import SwiftUI
import SwiftData
import UIKit

@MainActor @Observable
internal final class EditTransactionViewModel {

    // MARK: - Editable Fields

    internal var type: TransactionType
    internal var amountText: String
    internal var note: String
    internal var selectedCategory: Category?
    internal var date: Date
    internal private(set) var showSuccess = false
    internal private(set) var shouldDismiss: Bool = false
    internal private(set) var isSaving: Bool = false
    internal var errorMessage: String?

    // MARK: - Private

    private let transaction: Transaction
    private var dismissTask: Task<Void, Never>?

    // MARK: - Init

    internal init(transaction: Transaction) {
        self.transaction = transaction
        self.type = transaction.type
        self.amountText = NSDecimalNumber(decimal: transaction.amount).intValue.description
        self.note = transaction.note
        self.selectedCategory = transaction.category
        self.date = transaction.date
    }

    // MARK: - Validation

    internal var isValid: Bool {
        guard let amount = parsedAmount, amount > 0 else { return false }
        return selectedCategory != nil
    }

    internal var parsedAmount: Decimal? {
        amountText.parsedVNDAmount
    }

    internal var hasChanges: Bool {
        guard let amount = parsedAmount else { return false }
        return amount != transaction.amount
            || type != transaction.type
            || note != transaction.note
            || selectedCategory?.id != transaction.category?.id
            || date != transaction.date
    }

    // MARK: - Digit Input

    internal func appendDigit(_ digit: String) {
        guard amountText.count < 12 else { return }
        if amountText == "0" && digit == "0" { return }
        if amountText == "0" && digit != "0" { amountText = digit; return }
        amountText += digit
    }

    internal func deleteLastDigit() {
        guard !amountText.isEmpty else { return }
        amountText.removeLast()
    }

    // MARK: - Actions

    internal func clearCategoryOnTypeChange() {
        selectedCategory = nil
    }

    internal func cancelDismiss() {
        dismissTask?.cancel()
        dismissTask = nil
    }

    internal func saveChanges(context: ModelContext) {
        guard !isSaving else { return }

        do {
            try validateFields()
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        guard let amount = parsedAmount else { return }

        isSaving = true

        let originalAmount = transaction.amount
        let originalType = transaction.type
        let originalNote = transaction.note
        let originalCategory = transaction.category
        let originalDate = transaction.date

        transaction.amount = amount
        transaction.type = type
        transaction.note = note
        transaction.category = selectedCategory
        transaction.date = date

        do {
            try context.save()
            triggerSuccessHaptic()
            showSuccessState()
            scheduleDismiss()
        } catch {
            transaction.amount = originalAmount
            transaction.type = originalType
            transaction.note = originalNote
            transaction.category = originalCategory
            transaction.date = originalDate
            isSaving = false
            errorMessage = TransactionError
                .saveFailed(error.localizedDescription)
                .localizedDescription
        }
    }

    // MARK: - Private Methods

    private func showSuccessState() {
        if UIAccessibility.isReduceMotionEnabled {
            showSuccess = true
        } else {
            withAnimation(Motion.spatialDefault) {
                showSuccess = true
            }
        }
    }

    private func scheduleDismiss() {
        dismissTask?.cancel()
        dismissTask = Task {
            do {
                try await Task.sleep(for: .seconds(1.2))
                shouldDismiss = true
            } catch {
                // Task was cancelled; no action needed.
            }
        }
    }

    private func triggerSuccessHaptic() {
        HapticService.success()
    }

    private func validateFields() throws {
        guard let amount = parsedAmount, amount > 0 else {
            throw TransactionError.invalidAmount
        }
        guard selectedCategory != nil else {
            throw TransactionError.categoryRequired
        }
    }
}
