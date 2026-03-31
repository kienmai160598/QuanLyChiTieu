import SwiftUI
import SwiftData

// MARK: - EditRecurringView

internal struct EditRecurringView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [Category]
    @State private var viewModel: EditRecurringViewModel
    @State private var showDiscardAlert = false

    internal init(recurring: RecurringTransaction) {
        _viewModel = State(
            initialValue: EditRecurringViewModel(recurring: recurring)
        )
    }

    private var filteredCategories: [Category] {
        categories.filter { $0.type == viewModel.selectedType }
    }

    internal var body: some View {
        Form {
            typePicker
            amountSection
            categorySection
            frequencySection
            dateSection
            noteSection
        }
        .navigationTitle(String(localized: "Sửa giao dịch định kỳ"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .toolbar { formToolbar }
        .overlay { successOverlay }
        .discardGuard(hasChanges: viewModel.hasChanges, showAlert: $showDiscardAlert)
        .onChange(of: viewModel.selectedType) {
            viewModel.clearCategoryOnTypeChange()
        }
        .alert(
            String(localized: "Lỗi"),
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button(String(localized: "OK")) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

// MARK: - Form Sections

private extension EditRecurringView {
    private var typePicker: some View {
        Picker(String(localized: "Loại"), selection: $viewModel.selectedType) {
            Text(String(localized: "Chi tiêu")).tag(TransactionType.expense)
            Text(String(localized: "Thu nhập")).tag(TransactionType.income)
        }
        .pickerStyle(.segmented)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
        .padding(.horizontal, Spacing.xs)
    }

    private var amountSection: some View {
        Section(String(localized: "Số tiền")) {
            HStack {
                TextField("0", text: $viewModel.amountText)
                    .keyboardType(.numberPad)
                    .font(Typography.headlineLarge)
                    .foregroundStyle(amountInputColor)

                Text("₫")
                    .font(Typography.titleLarge)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
        }
    }

    private var categorySection: some View {
        Section(String(localized: "Danh mục")) {
            categoryGrid
        }
    }

    private var categoryGrid: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 76), spacing: Spacing.md)
        ], spacing: Spacing.md) {
            ForEach(filteredCategories) { category in
                categoryButton(category)
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    private var frequencySection: some View {
        Section(String(localized: "Tần suất")) {
            Picker(
                String(localized: "Lặp lại"),
                selection: $viewModel.frequency
            ) {
                ForEach(RecurrenceFrequency.allCases, id: \.self) { freq in
                    Label(freq.displayName, systemImage: freq.icon)
                        .tag(freq)
                }
            }
        }
    }

    private var dateSection: some View {
        Section(String(localized: "Thời gian")) {
            DatePicker(
                String(localized: "Bắt đầu"),
                selection: $viewModel.startDate,
                displayedComponents: [.date]
            )
            Toggle(
                String(localized: "Có ngày kết thúc"),
                isOn: $viewModel.hasEndDate
            )
            if viewModel.hasEndDate {
                DatePicker(
                    String(localized: "Kết thúc"),
                    selection: $viewModel.endDate,
                    displayedComponents: [.date]
                )
            }
        }
    }

    private var noteSection: some View {
        Section(String(localized: "Ghi chú")) {
            TextField(
                String(localized: "Ghi chú (tuỳ chọn)"),
                text: $viewModel.note
            )
        }
    }

    private var amountInputColor: Color {
        viewModel.selectedType == .expense
            ? Color.appError : Color.appIncome
    }
}

// MARK: - Category Button

private extension EditRecurringView {
    private func categoryButton(
        _ category: Category
    ) -> some View {
        let isSelected = viewModel.selectedCategory?.id == category.id
        let catColor = Color(hex: category.colorHex)

        return Button {
            viewModel.selectedCategory = category
        } label: {
            VStack(spacing: Spacing.sm) {
                categoryIcon(
                    category,
                    isSelected: isSelected,
                    color: catColor
                )
                Text(category.localizedName)
                    .font(Typography.labelSmall)
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? catColor : Color.onSurface)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.localizedName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func categoryIcon(
        _ category: Category,
        isSelected: Bool,
        color: Color
    ) -> some View {
        Image(systemName: category.icon)
            .font(Typography.headlineSmall)
            .frame(width: IconSize.containerXL, height: IconSize.containerXL)
            .background(
                isSelected
                    ? color.opacity(0.2)
                    : Color.surfaceContainerHigh
            )
            .clipShape(Circle())
            .overlay {
                if isSelected {
                    Circle().stroke(color, lineWidth: 2)
                }
            }
    }
}

// MARK: - Toolbar & Overlay

private extension EditRecurringView {
    @ToolbarContentBuilder
    private var formToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(String(localized: "Huỷ")) {
                if viewModel.hasChanges {
                    showDiscardAlert = true
                } else {
                    dismiss()
                }
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button(String(localized: "Lưu")) { saveAndDismiss() }
                .fontWeight(.semibold)
                .disabled(!viewModel.canSave)
        }
    }

    private func saveAndDismiss() {
        viewModel.saveChanges(context: context)
        guard viewModel.showSuccess else { return }
        Task {
            try? await Task.sleep(for: .seconds(0.8))
            dismiss()
        }
    }

    @ViewBuilder
    private var successOverlay: some View {
        if viewModel.showSuccess {
            SuccessOverlay(
                message: String(localized: "Đã lưu!"),
                accessibilityMessage: String(localized: "Giao dịch định kỳ đã được lưu thành công")
            )
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EditRecurringView(
            recurring: RecurringTransaction(
                amount: 5_000_000,
                note: "Tiền nhà",
                type: .expense,
                frequency: .monthly
            )
        )
    }
    .modelContainer(
        for: [RecurringTransaction.self, Category.self],
        inMemory: true
    )
}
