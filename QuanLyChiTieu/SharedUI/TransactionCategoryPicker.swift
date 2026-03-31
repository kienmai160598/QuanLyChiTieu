import SwiftUI

// MARK: - TransactionCategoryPicker
//
// Shared category selector used by AddTransactionView and EditTransactionView.
// Shows a list of categories filtered to the active TransactionType with an
// empty-state row and an "Add" button in the section header.

internal struct TransactionCategoryPicker: View {

    // MARK: - Parameters

    @Binding private var selectedCategory: Category?
    private let categories: [Category]
    private let onAdd: () -> Void

    // MARK: - Init

    internal init(
        selectedCategory: Binding<Category?>,
        categories: [Category],
        onAdd: @escaping () -> Void
    ) {
        _selectedCategory = selectedCategory
        self.categories = categories
        self.onAdd = onAdd
    }

    // MARK: - Body

    internal var body: some View {
        Section {
            ForEach(categories) { category in
                categoryRow(category)
            }
            if categories.isEmpty {
                Text(String(localized: "Chưa có danh mục"))
                    .foregroundStyle(.secondary)
            }
        } header: {
            HStack {
                Text(String(localized: "Danh mục"))
                Spacer()
                Button(String(localized: "Thêm")) { onAdd() }
                    .font(.subheadline)
            }
        }
    }

    // MARK: - Private

    private func categoryRow(_ category: Category) -> some View {
        let isSelected = selectedCategory?.id == category.id
        return Button {
            withAnimation {
                selectedCategory = isSelected ? nil : category
            }
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: category.icon)
                    .foregroundStyle(Color(hex: category.colorHex))
                    .frame(width: 28)
                Text(category.localizedName)
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .fontWeight(.semibold)
                }
            }
        }
        .accessibilityLabel(category.localizedName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
