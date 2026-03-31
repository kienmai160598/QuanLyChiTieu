import SwiftUI
import SwiftData

// MARK: - TransactionCategoryChips

/// Horizontal chip row for filtering transactions by category.
/// Uses Liquid Glass styling consistent with TransactionFilterChips.
internal struct TransactionCategoryChips: View {
    @Query private var categories: [Category]

    @Binding internal var selectedCategory: Category?

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    internal var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                allChip
                ForEach(sortedCategories) { category in
                    categoryChip(category)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.xs)
        }
        .animation(
            reduceMotion ? .none : Motion.spatialDefault,
            value: selectedCategory?.persistentModelID
        )
    }
}

// MARK: - Chip Builders

private extension TransactionCategoryChips {
    private var sortedCategories: [Category] {
        categories.sorted { $0.name < $1.name }
    }

    private var allChip: some View {
        let isSelected = selectedCategory == nil
        return Button {
            triggerHaptic()
            selectedCategory = nil
        } label: {
            chipContent(
                label: String(localized: "Tất cả"),
                icon: "square.grid.2x2.fill",
                isSelected: isSelected
            )
        }
        .accessibilityLabel(String(localized: "Tất cả"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .background(
            isSelected ? Color.appPrimary : Color.surfaceContainerHigh,
            in: .capsule
        )
    }

    private func categoryChip(_ category: Category) -> some View {
        let isSelected = selectedCategory?.persistentModelID == category.persistentModelID
        return Button {
            triggerHaptic()
            selectedCategory = isSelected ? nil : category
        } label: {
            chipContent(
                label: category.localizedName,
                icon: category.icon,
                isSelected: isSelected
            )
        }
        .accessibilityLabel(category.localizedName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .background(
            isSelected ? Color.appPrimary : Color.surfaceContainerHigh,
            in: .capsule
        )
    }

    private func chipContent(
        label: String,
        icon: String,
        isSelected: Bool
    ) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(Typography.bodySmall)
                .fontWeight(.medium)
            Text(label)
                .font(Typography.bodySmall)
                .fontWeight(.medium)
        }
        .foregroundStyle(isSelected ? Color.onPrimary : .primary)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    private func triggerHaptic() {
        HapticService.lightImpact()
    }
}
