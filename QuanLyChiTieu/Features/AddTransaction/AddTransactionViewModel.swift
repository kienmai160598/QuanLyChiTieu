import SwiftUI
import SwiftData
import UIKit

// MARK: - Add Transaction ViewModel

@MainActor @Observable
internal final class AddTransactionViewModel {

    // MARK: - Quick Amount Presets

    internal static let quickAmounts: [Int] = [50_000, 100_000, 200_000, 500_000]

    // MARK: - Form State

    internal var rawAmountDigits: String = ""
    internal var selectedType: TransactionType = .expense
    internal var selectedCategory: Category?
    internal var note: String = ""
    internal var date: Date = .now
    internal private(set) var showingSuccess: Bool = false
    internal private(set) var shouldDismiss: Bool = false
    internal private(set) var isSaving: Bool = false
    internal var saveError: String?

    // MARK: - Private State

    private var dismissTask: Task<Void, Never>?

    // MARK: - Computed Properties

    internal var hasChanges: Bool {
        !rawAmountDigits.isEmpty || selectedCategory != nil || !note.isEmpty
    }

    internal var isValid: Bool {
        parsedAmount > 0 && selectedCategory != nil
    }

    internal var displayAmount: String {
        guard parsedAmount > 0 else { return "0" }
        return parsedAmount.fullFormattedVND
    }

    internal var parsedAmount: Decimal {
        Decimal(string: rawAmountDigits) ?? 0
    }

    // MARK: - Quick Amount

    internal func setQuickAmount(_ amount: Int) {
        rawAmountDigits = String(amount)
    }

    // MARK: - Digit Input

    internal func appendDigit(_ digit: String) {
        guard rawAmountDigits.count < 12 else { return }
        if rawAmountDigits == "0" && digit == "0" { return }
        if rawAmountDigits == "0" && digit != "0" {
            rawAmountDigits = digit
            return
        }
        rawAmountDigits += digit
    }

    internal func deleteLastDigit() {
        guard !rawAmountDigits.isEmpty else { return }
        rawAmountDigits.removeLast()
    }

    // MARK: - Actions

    internal func saveTransaction(context: ModelContext) {
        guard !isSaving else { return }
        guard parsedAmount > 0 else {
            saveError = TransactionError.invalidAmount.localizedDescription
            return
        }
        guard selectedCategory != nil else {
            saveError = TransactionError.categoryRequired.localizedDescription
            return
        }

        isSaving = true
        let transaction = Transaction(
            amount: parsedAmount,
            note: note,
            date: date,
            type: selectedType,
            category: selectedCategory
        )
        context.insert(transaction)
        do {
            try context.save()
            triggerSuccessHaptic()
            showSuccess()
            scheduleDismiss()
        } catch {
            context.delete(transaction)
            isSaving = false
            saveError = TransactionError
                .saveFailed(error.localizedDescription)
                .localizedDescription
        }
    }

    internal func clearCategoryOnTypeChange() {
        selectedCategory = nil
    }

    internal func cancelDismiss() {
        dismissTask?.cancel()
        dismissTask = nil
    }

    // MARK: - Private Methods

    private func showSuccess() {
        if UIAccessibility.isReduceMotionEnabled {
            showingSuccess = true
        } else {
            withAnimation(Motion.spatialDefault) {
                showingSuccess = true
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
                // Task was cancelled (e.g. user dismissed manually); no action needed.
            }
        }
    }

    private func triggerSuccessHaptic() {
        HapticService.success()
    }
}
