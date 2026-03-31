import SwiftUI
import SwiftData

// MARK: - EditTransactionView

internal struct EditTransactionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [Category]
    @State private var viewModel: EditTransactionViewModel
    @State private var showDiscardAlert = false
    @State private var showAddCategory = false
    @State private var showCategoryPicker = false
    @FocusState private var isAmountFocused: Bool

    internal init(transaction: Transaction) {
        _viewModel = State(initialValue: EditTransactionViewModel(transaction: transaction))
    }

    private var filteredCategories: [Category] {
        categories.filter { $0.type == viewModel.type }
    }

    private var amountColor: Color {
        let amount = viewModel.parsedAmount ?? 0
        return amount > 0
            ? (viewModel.type == .expense ? .appError : .appIncome)
            : Color.onSurfaceVariant
    }

    private var formattedAmount: Binding<String> {
        Binding(
            get: {
                guard let num = Int(viewModel.amountText), num > 0 else {
                    return viewModel.amountText
                }
                let fmt = NumberFormatter()
                fmt.numberStyle = .decimal
                fmt.groupingSeparator = ","
                return fmt.string(from: NSNumber(value: num)) ?? viewModel.amountText
            },
            set: { viewModel.amountText = $0.filter(\.isNumber) }
        )
    }

    internal var body: some View {
        GlassEffectContainer {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    heroAmount
                    typePicker
                    categoryCard
                    detailsCard
                    saveButton
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxxl)
            }
        }
        .appBackground()
        .navigationTitle(String(localized: "Sửa giao dịch"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarItems }
        .overlay { if viewModel.showSuccess { successOverlay } }
        .onChange(of: viewModel.type) { viewModel.clearCategoryOnTypeChange() }
        .onChange(of: viewModel.shouldDismiss) { _, val in if val { dismiss() } }
        .discardGuard(hasChanges: viewModel.hasChanges, showAlert: $showDiscardAlert)
        .alert(
            String(localized: "Lỗi"),
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            if let error = viewModel.errorMessage { Text(error) }
        }
        .sheet(isPresented: $showCategoryPicker) {
            CategoryPickerSheet(
                selectedCategory: $viewModel.selectedCategory,
                categories: filteredCategories,
                onAdd: {
                    showCategoryPicker = false
                    showAddCategory = true
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(Spacing.cornerExtraExtraLarge)
            .presentationBackground(Color.surfaceContainerLowest)
        }
        .sheet(isPresented: $showAddCategory) {
            AddCategorySheet(
                editingCategory: nil,
                preselectedType: viewModel.type
            )
        }
    }
}

// MARK: - Hero Amount

private extension EditTransactionView {
    private var heroAmount: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
            TextField("0", text: formattedAmount)
                .keyboardType(.numberPad)
                .focused($isAmountFocused)
                .font(Typography.heroLarge)
                .monospacedDigit()
                .foregroundStyle(amountColor)
                .multilineTextAlignment(.center)
                .accessibilityLabel(String(localized: "Số tiền"))
            Text("₫")
                .font(Typography.headlineSmall)
                .foregroundStyle(Color.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .glassEffect(in: RoundedRectangle(cornerRadius: Spacing.cornerExtraExtraLarge))
        .animation(Motion.effectDefault, value: viewModel.type)
    }
}

// MARK: - Type Picker

private extension EditTransactionView {
    private var typePicker: some View {
        HStack(spacing: Spacing.xs) {
            typeChip(.expense, icon: "arrow.down.circle.fill", label: String(localized: "Chi tiêu"))
            typeChip(.income, icon: "arrow.up.circle.fill", label: String(localized: "Thu nhập"))
        }
        .padding(Spacing.xs)
        .glassEffect(in: RoundedRectangle(cornerRadius: Spacing.cornerExtraLarge))
    }

    private func typeChip(
        _ type: TransactionType, icon: String, label: String
    ) -> some View {
        let isSelected = viewModel.type == type
        let tint: Color = type == .expense ? .appError : .appIncome
        return Button {
            withAnimation(Motion.spatialFast) { viewModel.type = type }
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: IconSize.md, weight: .medium))
                Text(label)
                    .font(isSelected ? Typography.labelLargeEmphasized : Typography.labelLarge)
            }
            .foregroundStyle(isSelected ? Color.white : Color.onSurfaceVariant)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(isSelected ? tint : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Card

private extension EditTransactionView {
    private var categoryCard: some View {
        Button { showCategoryPicker = true } label: {
            HStack(spacing: Spacing.md) {
                if let cat = viewModel.selectedCategory {
                    Image(systemName: cat.icon)
                        .font(.system(size: IconSize.md, weight: .medium))
                        .foregroundStyle(Color(hex: cat.colorHex))
                        .frame(width: 28)
                    Text(cat.localizedName)
                        .font(Typography.bodyLarge)
                        .foregroundStyle(Color.onSurface)
                } else {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: IconSize.md, weight: .medium))
                        .foregroundStyle(Color.onSurfaceVariant)
                        .frame(width: 28)
                    Text(String(localized: "Chọn danh mục"))
                        .font(Typography.bodyLarge)
                        .foregroundStyle(Color.onSurfaceVariant)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
            .padding(Spacing.lg)
        }
        .buttonStyle(.plain)
        .glassEffect(in: RoundedRectangle(cornerRadius: Spacing.cornerExtraLarge))
    }
}

// MARK: - Details Card

private extension EditTransactionView {
    private var detailsCard: some View {
        VStack(spacing: 0) {
            noteRow
            Divider().padding(.horizontal, Spacing.lg)
            dateRow
        }
        .glassEffect(in: RoundedRectangle(cornerRadius: Spacing.cornerExtraLarge))
    }

    private var noteRow: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "pencil")
                .font(.system(size: IconSize.md, weight: .medium))
                .foregroundStyle(Color.onSurfaceVariant)
                .frame(width: 24)
            TextField(String(localized: "Ghi chú"), text: $viewModel.note)
                .font(Typography.bodyLarge)
                .onChange(of: viewModel.note) { _, newValue in
                    if newValue.count > 200 { viewModel.note = String(newValue.prefix(200)) }
                }
        }
        .padding(Spacing.lg)
    }

    private var dateRow: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "calendar")
                .font(.system(size: IconSize.md, weight: .medium))
                .foregroundStyle(Color.onSurfaceVariant)
                .frame(width: 24)
            DatePicker(
                String(localized: "Ngày"),
                selection: $viewModel.date,
                displayedComponents: .date
            )
            .font(Typography.bodyLarge)
        }
        .padding(Spacing.lg)
    }
}

// MARK: - Save & Toolbar

private extension EditTransactionView {
    private var saveButton: some View {
        GlassSaveButton(
            label: String(localized: "Lưu thay đổi"),
            isEnabled: viewModel.isValid && !viewModel.isSaving && viewModel.hasChanges
        ) {
            viewModel.saveChanges(context: context)
        }
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(String(localized: "Huỷ")) {
                viewModel.cancelDismiss()
                if viewModel.hasChanges { showDiscardAlert = true } else { dismiss() }
            }
        }
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button(String(localized: "Xong")) { isAmountFocused = false }
        }
    }

    private var successOverlay: some View {
        SuccessOverlay(
            message: String(localized: "Đã lưu!"),
            accessibilityMessage: String(localized: "Giao dịch đã được lưu thành công")
        )
    }
}

#Preview {
    NavigationStack {
        EditTransactionView(
            transaction: Transaction(amount: 250_000, note: "Ăn trưa", date: .now, type: .expense)
        )
    }
    .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
}
