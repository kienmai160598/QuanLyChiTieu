import SwiftUI
import SwiftData

internal struct CategoryListView: View {
    @Query(sort: \Category.name) private var allCategories: [Category]
    @Environment(\.modelContext) private var context
    @State private var viewModel = CategoryListViewModel()

    private var expenseCategories: [Category] {
        allCategories.filter { $0.type == .expense }
    }

    private var incomeCategories: [Category] {
        allCategories.filter { $0.type == .income }
    }

    internal var body: some View {
        Group {
            if allCategories.isEmpty {
                emptyContent
            } else {
                listContent
            }
        }
        .appBackground()
        .navigationTitle(String(localized: "Danh m\u{1EE5}c"))
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .toolbar { addButton }
        .sheet(isPresented: $viewModel.showAddSheet) {
            AddCategorySheet(editingCategory: viewModel.editingCategory)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(Spacing.cornerExtraExtraLarge)
                .presentationBackground(Color.surfaceContainerLowest)
        }
        .alert(
            String(localized: "Xo\u{00E1} danh m\u{1EE5}c?"),
            isPresented: $viewModel.showDeleteConfirmation
        ) {
            Button(String(localized: "Hu\u{1EF7}"), role: .cancel) {}
            Button(String(localized: "Xo\u{00E1}"), role: .destructive) {
                viewModel.deleteCategory(context: context)
            }
        } message: {
            Text(viewModel.deleteWarningMessage)
        }
        .alert(String(localized: "L\u{1ED7}i"), isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button(String(localized: "OK")) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    @ToolbarContentBuilder
    private var addButton: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                viewModel.startAdding()
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel(String(localized: "Th\u{00EA}m danh m\u{1EE5}c"))
        }
    }
}

// MARK: - Empty State

private extension CategoryListView {
    private var emptyContent: some View {
        ScrollView {
            EmptyStateCard(
                icon: "tag.fill",
                title: String(localized: "Ch\u{01B0}a c\u{00F3} danh m\u{1EE5}c"),
                actionLabel: String(localized: "Th\u{00EA}m danh m\u{1EE5}c"),
                onAction: { viewModel.startAdding() }
            )
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.xxxl)
        }
    }
}

// MARK: - List Content

private extension CategoryListView {
    private var listContent: some View {
        List {
            if !expenseCategories.isEmpty {
                expenseSection
            }
            if !incomeCategories.isEmpty {
                incomeSection
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Expense Section

private extension CategoryListView {
    private var expenseSection: some View {
        Section {
            ForEach(expenseCategories) { category in
                Button { viewModel.startEditing(category) } label: {
                    categoryRow(category)
                }
                .buttonStyle(.plain)
                .m3SectionRow()
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        viewModel.confirmDelete(category)
                    } label: {
                        Image(systemName: "trash")
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button { viewModel.startEditing(category) } label: {
                        Image(systemName: "pencil")
                    }
                    .tint(Color.appSecondary)
                }
            }
        } header: {
            Text(String(localized: "Chi ti\u{00EA}u"))
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurfaceVariant)
                .textCase(nil)
        }
    }
}

// MARK: - Income Section

private extension CategoryListView {
    private var incomeSection: some View {
        Section {
            ForEach(incomeCategories) { category in
                Button { viewModel.startEditing(category) } label: {
                    categoryRow(category)
                }
                .buttonStyle(.plain)
                .m3SectionRow()
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        viewModel.confirmDelete(category)
                    } label: {
                        Image(systemName: "trash")
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button { viewModel.startEditing(category) } label: {
                        Image(systemName: "pencil")
                    }
                    .tint(Color.appSecondary)
                }
            }
        } header: {
            Text(String(localized: "Thu nh\u{1EAD}p"))
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurfaceVariant)
                .textCase(nil)
        }
    }
}

// MARK: - Category Row

private extension CategoryListView {
    private func categoryRow(_ category: Category) -> some View {
        HStack(spacing: Spacing.md) {
            M3IconBadge(
                icon: category.icon,
                color: Color(hex: category.colorHex)
            )
            Text(category.localizedName)
                .font(Typography.bodyLarge)
                .foregroundStyle(Color.onSurface)
            Spacer()
            Image(systemName: "chevron.right")
                .font(Typography.labelSmall)
                .foregroundStyle(Color.onSurfaceVariant)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(category.localizedName)
        .accessibilityHint(String(localized: "Nh\u{1EA5}n \u{0111}\u{1EC3} s\u{1EED}a"))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CategoryListView()
    }
    .modelContainer(
        for: [Transaction.self, Category.self, Budget.self],
        inMemory: true
    )
}
