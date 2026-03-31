import SwiftUI

// MARK: - TransactionCategoryGrid (M3 Expressive)

/// Two-column horizontal pill layout for category selection.
/// M3E: shape contrast (selected = extraLarge, unselected = large),
/// emphasized typography, spring motion with bounce.
internal struct TransactionCategoryGrid: View {
    @Binding internal var selectedCategory: Category?
    internal let categories: [Category]
    internal var onAddCategory: (() -> Void)?
    internal var title: String = String(localized: "Danh muc")

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var appeared = false

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.sm),
        GridItem(.flexible(), spacing: Spacing.sm),
    ]

    internal var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader
            Group {
                if categories.isEmpty {
                    emptyState
                } else {
                    categoryGrid
                        .id(categories.count)
                }
            }
        }
        .animation(
            reduceMotion ? .none : Motion.spatialDefault,
            value: selectedCategory?.id
        )
        .onAppear { appeared = true }
    }
}

// MARK: - Section Header

private extension TransactionCategoryGrid {
    private var sectionHeader: some View {
        HStack(spacing: Spacing.xs) {
            Text(title)
                .font(Typography.titleSmallEmphasized)
                .foregroundStyle(Color.onSurfaceVariant)
            Text("*")
                .font(Typography.titleSmall)
                .foregroundStyle(Color.appError)
        }
        .padding(.horizontal, Spacing.xs)
    }
}

// MARK: - Grid Layout

private extension TransactionCategoryGrid {
    private var categoryGrid: some View {
        LazyVGrid(columns: columns, spacing: Spacing.sm) {
            ForEach(Array(categories.enumerated()), id: \.element.id) { index, cat in
                categoryPill(cat, index: index)
            }
            if onAddCategory != nil { addButton }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            if let onAddCategory {
                addCategoryPrompt(action: onAddCategory)
            } else {
                Image(systemName: "square.grid.2x2")
                    .font(.title2)
                    .foregroundStyle(Color.onSurfaceVariant)
                Text(String(localized: "Chua co danh muc"))
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
    }

    private var addButton: some View {
        Button {
            HapticService.lightImpact()
            onAddCategory?()
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: "plus")
                    .font(.system(size: IconSize.md, weight: .medium))
                    .frame(width: IconSize.containerLG, height: IconSize.containerLG)
                Text(String(localized: "Them"))
                    .font(Typography.bodyLarge)
                Spacer()
            }
            .foregroundStyle(Color.onSurfaceVariant)
            .padding(.horizontal, Spacing.md)
            .frame(height: 56)
            .m3Card(cornerRadius: Spacing.cornerExtraLarge, background: .surfaceContainerHigh)
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerLarge)
                    .strokeBorder(Color.outlineVariant.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "Them danh muc"))
    }

    private func addCategoryPrompt(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: Spacing.sm) {
                Image(systemName: "plus.circle")
                    .font(.title2)
                    .foregroundStyle(Color.onSurfaceVariant)
                Text(String(localized: "Them danh muc dau tien"))
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "Them danh muc"))
    }
}

// MARK: - Category Pill (M3 Expressive shape morphing)

private extension TransactionCategoryGrid {
    private func categoryPill(_ cat: Category, index: Int) -> some View {
        let isSelected = selectedCategory?.id == cat.id
        let selectedRadius = Spacing.cornerExtraLarge
        let unselectedRadius = Spacing.cornerLarge

        return Button {
            HapticService.lightImpact()
            selectedCategory = isSelected ? nil : cat
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: cat.icon)
                    .font(.system(size: IconSize.md, weight: .medium))
                    .frame(width: IconSize.containerLG, height: IconSize.containerLG)
                    .background(
                        isSelected
                            ? Color.onPrimary.opacity(0.2)
                            : Color.surfaceContainerHighest,
                        in: Circle()
                    )
                Text(cat.localizedName)
                    .font(isSelected ? Typography.bodyLargeEmphasized : Typography.bodyLarge)
                    .lineLimit(1)
                Spacer()
            }
            .foregroundStyle(isSelected ? Color.onPrimary : Color.onSurface)
            .padding(.horizontal, Spacing.md)
            .frame(height: 56)
            .background(isSelected ? Color.appPrimary : Color.surfaceContainerHigh)
            .clipShape(RoundedRectangle(
                cornerRadius: isSelected ? selectedRadius : unselectedRadius
            ))
        }
        .buttonStyle(.plain)
        .opacity(reduceMotion || appeared ? 1 : 0)
        .offset(y: reduceMotion || appeared ? 0 : 8)
        .animation(
            reduceMotion ? .none : Motion.spatialDefault,
            value: isSelected
        )
        .animation(
            reduceMotion ? .none : Motion.spatialSlow,
            value: appeared
        )
        .accessibilityLabel(cat.localizedName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
