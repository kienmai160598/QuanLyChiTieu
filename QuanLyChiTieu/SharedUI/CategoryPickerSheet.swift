import SwiftUI

// MARK: - CategoryPickerSheet
//
// Full-screen category selection sheet with 2-column tinted pill grid.
// Design reference: soft pastel-tinted pills with icon + name.

internal struct CategoryPickerSheet: View {
    @Binding internal var selectedCategory: Category?
    internal let categories: [Category]
    internal let onAdd: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.sm),
        GridItem(.flexible(), spacing: Spacing.sm),
    ]

    internal var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if categories.isEmpty {
                        emptyState
                    } else {
                        categoryGrid
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxxl)
            }
            .appBackground()
            .navigationTitle(String(localized: "Chọn danh mục"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbar { toolbarItems }
            .onAppear { appeared = true }
        }
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
            }
            .accessibilityLabel(String(localized: "Đóng"))
        }
        ToolbarItem(placement: .primaryAction) {
            Button { onAdd() } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel(String(localized: "Thêm danh mục"))
        }
    }
}

// MARK: - Grid

private extension CategoryPickerSheet {
    private var categoryGrid: some View {
        LazyVGrid(columns: columns, spacing: Spacing.sm) {
            ForEach(Array(categories.enumerated()), id: \.element.id) { index, cat in
                categoryPill(cat, index: index)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "square.grid.2x2")
                .font(.title2)
                .foregroundStyle(Color.onSurfaceVariant)
            Text(String(localized: "Chưa có danh mục"))
                .font(Typography.bodyMedium)
                .foregroundStyle(Color.onSurfaceVariant)
            Button {
                onAdd()
            } label: {
                Text(String(localized: "Thêm danh mục"))
                    .font(Typography.labelLargeEmphasized)
                    .foregroundStyle(Color.onPrimary)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(Color.appPrimary, in: Capsule())
            }
            .buttonStyle(ExpressivePressStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxxl)
    }
}

// MARK: - Category Pill

private extension CategoryPickerSheet {
    private func categoryPill(_ cat: Category, index: Int) -> some View {
        let isSelected = selectedCategory?.id == cat.id
        let catColor = Color(hex: cat.colorHex)

        return Button {
            HapticService.lightImpact()
            withAnimation(Motion.spatialFast) {
                selectedCategory = cat
            }
            dismissAfterSelection()
        } label: {
            HStack(spacing: Spacing.md) {
                iconCircle(cat: cat, isSelected: isSelected, catColor: catColor)
                Text(cat.localizedName)
                    .font(isSelected ? Typography.bodyLargeEmphasized : Typography.bodyLarge)
                    .foregroundStyle(isSelected ? Color.onPrimary : Color.onSurface)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .frame(height: 56)
            .background(pillBackground(isSelected: isSelected, catColor: catColor))
            .clipShape(RoundedRectangle(
                cornerRadius: isSelected ? Spacing.cornerExtraLarge : Spacing.cornerLarge
            ))
        }
        .buttonStyle(.plain)
        .opacity(reduceMotion || appeared ? 1 : 0)
        .offset(y: reduceMotion || appeared ? 0 : 6)
        .animation(
            reduceMotion ? .none : Motion.spatialSlow.delay(Double(index) * 0.03),
            value: appeared
        )
        .animation(reduceMotion ? .none : Motion.spatialDefault, value: isSelected)
        .accessibilityLabel(cat.localizedName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func iconCircle(cat: Category, isSelected: Bool, catColor: Color) -> some View {
        Image(systemName: cat.icon)
            .font(.system(size: IconSize.md, weight: .medium))
            .foregroundStyle(isSelected ? Color.onPrimary : catColor)
            .frame(width: IconSize.containerLG, height: IconSize.containerLG)
            .background(
                isSelected ? Color.onPrimary.opacity(0.2) : catColor.opacity(0.12),
                in: Circle()
            )
    }

    private func pillBackground(isSelected: Bool, catColor: Color) -> some ShapeStyle {
        isSelected ? AnyShapeStyle(Color.appPrimary) : AnyShapeStyle(catColor.opacity(0.08))
    }

    private func dismissAfterSelection() {
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            dismiss()
        }
    }
}
