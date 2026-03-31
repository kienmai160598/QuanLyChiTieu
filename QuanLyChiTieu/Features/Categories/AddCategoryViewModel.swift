import Foundation
import SwiftData

@MainActor @Observable
internal final class AddCategoryViewModel {

    // MARK: - State

    internal var name = ""
    internal var selectedType: TransactionType = .expense
    internal var selectedIcon = ""
    internal var selectedColorHex = "#000000"
    internal var editingCategory: Category?
    internal var errorMessage: String?

    // MARK: - Computed

    internal var hasChanges: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            || !selectedIcon.isEmpty
            || editingCategory != nil
    }

    internal var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !selectedIcon.isEmpty
    }

    internal var isEditing: Bool {
        editingCategory != nil
    }

    // MARK: - Actions

    internal func loadForEdit(_ category: Category) {
        editingCategory = category
        name = category.name
        selectedType = category.type
        selectedIcon = category.icon
        selectedColorHex = category.colorHex
    }

    internal func save(context: ModelContext) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, !selectedIcon.isEmpty else {
            errorMessage = String(localized: "Vui lòng nhập tên và chọn biểu tượng")
            return false
        }

        let descriptor = FetchDescriptor<Category>()
        let allCategories = (try? context.fetch(descriptor)) ?? []
        let isDuplicate = allCategories.contains { cat in
            cat.name.lowercased() == trimmedName.lowercased()
                && cat.type == selectedType
                && cat.persistentModelID != editingCategory?.persistentModelID
        }
        if isDuplicate {
            errorMessage = String(localized: "Danh mục này đã tồn tại")
            return false
        }

        if let existing = editingCategory {
            existing.name = trimmedName
            existing.type = selectedType
            existing.icon = selectedIcon
            existing.colorHex = selectedColorHex
        } else {
            let category = Category(
                name: trimmedName,
                icon: selectedIcon,
                colorHex: selectedColorHex,
                type: selectedType
            )
            context.insert(category)
        }

        do {
            try context.save()
        } catch {
            errorMessage = String(localized: "Không thể lưu danh mục")
            return false
        }
        return true
    }
}
