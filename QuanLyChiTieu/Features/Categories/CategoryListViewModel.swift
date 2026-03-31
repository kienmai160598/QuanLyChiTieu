import Foundation
import SwiftData

@MainActor @Observable
internal final class CategoryListViewModel {

    // MARK: - State

    internal var categoryToDelete: Category?
    internal var showDeleteConfirmation = false
    internal var showAddSheet = false
    internal var editingCategory: Category?
    internal var errorMessage: String?

    // MARK: - Computed

    internal var orphanedTransactionCount: Int {
        categoryToDelete?.transactions?.count ?? 0
    }

    internal var orphanedBudgetCount: Int {
        categoryToDelete?.budgets?.count ?? 0
    }

    internal var deleteWarningMessage: String {
        guard let category = categoryToDelete else {
            return String(localized: "Xoá danh mục này?")
        }
        let txCount = orphanedTransactionCount
        let budgetCount = orphanedBudgetCount
        if txCount > 0 || budgetCount > 0 {
            return String(localized: "Danh mục \"\(category.name)\" có \(txCount) giao dịch và \(budgetCount) ngân sách. Xoá sẽ chuyển chúng sang danh mục \"Khác\".")
        }
        return String(localized: "Bạn có chắc muốn xoá danh mục \"\(category.name)\"?")
    }

    // MARK: - Actions

    internal func confirmDelete(_ category: Category) {
        categoryToDelete = category
        showDeleteConfirmation = true
    }

    internal func deleteCategory(context: ModelContext) {
        guard let category = categoryToDelete else { return }
        do {
            let fallback = try findOrCreateFallback(
                for: category.type, context: context
            )
            reassignOrphans(from: category, to: fallback)
            context.delete(category)
            try context.save()
        } catch {
            errorMessage = String(localized: "Không thể xoá danh mục")
        }
        categoryToDelete = nil
    }

    internal func startEditing(_ category: Category) {
        editingCategory = category
        showAddSheet = true
    }

    internal func startAdding() {
        editingCategory = nil
        showAddSheet = true
    }

    // MARK: - Private Helpers

    private func findOrCreateFallback(
        for type: TransactionType,
        context: ModelContext
    ) throws -> Category {
        let targetName = "Khác"
        let targetType = type
        var descriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> {
                $0.name == targetName && $0.type == targetType
            }
        )
        descriptor.fetchLimit = 1
        let existing = try context.fetch(descriptor)
        if let found = existing.first { return found }
        let fallback = Category(
            name: "Khác",
            icon: "questionmark.circle.fill",
            colorHex: "#D7A49A",
            type: type
        )
        context.insert(fallback)
        return fallback
    }

    private func reassignOrphans(from source: Category, to target: Category) {
        for transaction in source.transactions ?? [] {
            transaction.category = target
        }
        for budget in source.budgets ?? [] {
            budget.category = target
        }
    }
}
