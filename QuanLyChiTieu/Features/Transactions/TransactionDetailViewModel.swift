import SwiftUI
import SwiftData

@MainActor @Observable
internal final class TransactionDetailViewModel {

    // MARK: - State

    internal private(set) var transaction: Transaction
    internal var isShowingDeleteAlert = false
    internal var isShowingEditSheet = false
    internal var errorMessage: String?

    // MARK: - Init

    internal init(transaction: Transaction) {
        self.transaction = transaction
    }

    // MARK: - Computed Properties

    internal var formattedAmount: String {
        transaction.signedFormattedAmount
    }

    internal var amountColor: Color {
        switch transaction.type {
        case .income: Color.appIncome
        case .expense: Color.appError
        }
    }

    internal var typeDisplayName: String {
        transaction.type.displayName
    }

    internal var typeIcon: String {
        transaction.type.icon
    }

    internal var formattedDate: String {
        transaction.date.fullLocalized
    }

    internal var formattedTime: String {
        transaction.date.formatted(.dateTime.hour().minute())
    }

    internal var categoryName: String {
        transaction.category?.localizedName ?? String(localized: "Không rõ")
    }

    internal var categoryIcon: String {
        transaction.category?.icon ?? "questionmark.circle"
    }

    internal var noteText: String {
        transaction.note.isEmpty ? String(localized: "Không có ghi chú") : transaction.note
    }

    internal var hasNote: Bool {
        !transaction.note.isEmpty
    }

    // MARK: - Actions

    internal func confirmDelete() {
        isShowingDeleteAlert = true
    }

    internal func showEditSheet() {
        isShowingEditSheet = true
    }

    internal func deleteTransaction(context: ModelContext) {
        context.delete(transaction)
        do {
            try context.save()
        } catch {
            errorMessage = TransactionError
                .deleteFailed(error.localizedDescription)
                .localizedDescription
        }
    }
}
