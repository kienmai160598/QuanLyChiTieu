import SwiftUI
import SwiftData

internal struct AddBudgetSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allCategories: [Category]

    internal let existingBudgets: [Budget]
    internal var editingBudget: Budget?
    internal var monthYear: String = Date().monthYearKey

    @State private var viewModel = AddBudgetViewModel()
    @State private var showDiscardAlert = false
    @FocusState private var isLimitFocused: Bool
    private var categories: [Category] { allCategories.filter { $0.type == .expense } }

    private var sheetTitle: String {
        viewModel.isEditing ? String(localized: "Sửa ngân sách") : String(localized: "Thêm ngân sách")
    }

    internal var body: some View {
        NavigationStack {
            sheetContent
                .appBackground()
                .navigationTitle(sheetTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
                .toolbar { sheetToolbar }
                .onAppear {
                    viewModel.monthYear = monthYear
                    loadEditingBudgetIfNeeded()
                }
                .discardGuard(hasChanges: viewModel.hasChanges, showAlert: $showDiscardAlert)
        }
    }

    private func loadEditingBudgetIfNeeded() {
        guard let budget = editingBudget else { return }
        viewModel.loadForEdit(budget)
    }

    private var sheetContent: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                if !viewModel.isEditing { budgetModePicker }
                amountSection
                if !viewModel.isEditing && viewModel.budgetMode == .category {
                    categorySection
                }
                autoRolloverToggle
                errorBanner
                saveButton
            }
            .padding(Spacing.lg)
        }
    }

    @ToolbarContentBuilder
    private var sheetToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(String(localized: "Huỷ")) {
                if viewModel.hasChanges { showDiscardAlert = true } else { dismiss() }
            }
        }
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button(String(localized: "Xong")) { isLimitFocused = false }
        }
    }
}

// MARK: - Mode Picker & Rollover Toggle
private extension AddBudgetSheet {
    var budgetModePicker: some View {
        Picker(String(localized: "Loại ngân sách"), selection: $viewModel.budgetMode) {
            ForEach(BudgetMode.allCases, id: \.self) { mode in
                Text(mode.label).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel(String(localized: "Loại ngân sách"))
    }

    var autoRolloverToggle: some View {
        Toggle(isOn: $viewModel.autoRollover) {
            Label(String(localized: "Tự động chuyển sang tháng sau"), systemImage: "arrow.triangle.2.circlepath")
                .font(Typography.bodyMedium)
                .foregroundStyle(Color.onSurface)
        }
        .tint(.appSecondary)
        .padding(.horizontal, Spacing.sm)
    }
}

// MARK: - Amount Input
private extension AddBudgetSheet {
    var amountSection: some View {
        VStack(spacing: Spacing.lg) {
            Text(String(localized: "Hạn mức chi tiêu"))
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurfaceVariant)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                TextField("0", text: $viewModel.limitText)
                    .keyboardType(.numberPad)
                    .focused($isLimitFocused)
                    .font(Typography.headlineLarge)
                    .foregroundStyle(Color.onSurface)
                    .multilineTextAlignment(.center)
                    .onChange(of: viewModel.limitText) { viewModel.clearError() }
                    .accessibilityLabel(String(localized: "Hạn mức chi tiêu"))
                Text("₫")
                    .font(Typography.headlineSmall)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
            .frame(maxWidth: .infinity)
            suggestedAmounts
        }
        .padding(Spacing.xl)
        .m3Card(cornerRadius: Spacing.cornerExtraLarge, background: .surfaceContainerHigh)
    }

    var suggestedAmounts: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(["500000", "1000000", "2000000"], id: \.self) { amount in
                suggestedAmountChip(amount)
            }
        }
    }

    func suggestedAmountChip(_ amount: String) -> some View {
        let label = Decimal(string: amount)?.formattedVND ?? amount
        return Button { viewModel.limitText = amount } label: {
            Text(label)
                .font(Typography.labelSmall)
                .foregroundStyle(Color.appSecondary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.primaryContainer.opacity(0.3))
                .clipShape(Capsule())
        }
        .accessibilityLabel(String(localized: "Đặt hạn mức \(label)"))
    }
}

// MARK: - Category Selection
private extension AddBudgetSheet {
    var categorySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "Danh mục"))
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurfaceVariant)
            VStack(spacing: 0) {
                ForEach(Array(categories.enumerated()), id: \.element.id) { index, cat in
                    categoryRow(cat)
                    if index < categories.count - 1 {
                        Divider()
                            .foregroundStyle(Color.outlineVariant)
                            .padding(.leading, 56)
                    }
                }
            }
            .m3Card(cornerRadius: Spacing.cornerExtraLarge)
        }
    }

    func categoryRow(_ cat: Category) -> some View {
        let isDisabled = existingBudgets.contains { $0.category?.persistentModelID == cat.persistentModelID }
        let isSelected = viewModel.selectedCategory?.id == cat.id
        return Button { viewModel.selectCategory(cat) } label: {
            HStack(spacing: Spacing.md) {
                M3IconBadge(icon: cat.icon, color: Color(hex: cat.colorHex))
                Text(cat.localizedName)
                    .font(Typography.bodyLarge)
                    .foregroundStyle(isDisabled ? Color.onSurfaceVariant : Color.onSurface)
                Spacer()
                categoryTrailing(cat, isDisabled: isDisabled)
            }
            .padding(.horizontal, Spacing.lg)
            .frame(minHeight: 56)
        }
        .disabled(isDisabled)
        .accessibilityLabel(cat.localizedName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    func categoryTrailing(_ cat: Category, isDisabled: Bool) -> some View {
        if isDisabled {
            Text(String(localized: "Đã có")).font(Typography.labelSmall).foregroundStyle(Color.onSurfaceVariant)
        } else if viewModel.selectedCategory?.id == cat.id {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.appPrimary).accessibilityHidden(true)
        }
    }
}

// MARK: - Error & Save
private extension AddBudgetSheet {
    var errorBanner: some View {
        ErrorBannerView(message: viewModel.errorMessage)
    }

    var saveButton: some View {
        let label = viewModel.isEditing
            ? String(localized: "Lưu ngân sách")
            : String(localized: "Tạo ngân sách")
        return GlassSaveButton(label: label, isEnabled: viewModel.canSave) { save() }
    }

    func save() {
        let success = viewModel.save(context: context, existingBudgets: existingBudgets)
        if success {
            HapticService.success()
            dismiss()
        }
    }
}
