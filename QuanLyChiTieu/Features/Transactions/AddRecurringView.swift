import SwiftUI
import SwiftData

// MARK: - AddRecurringView

internal struct AddRecurringView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [Category]

    @State private var viewModel = AddRecurringViewModel()
    @State private var errorMessage: String?
    @State private var showDiscardAlert = false

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
        .navigationTitle(String(localized: "Thêm định kỳ"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .toolbar { formToolbar }
        .onChange(of: viewModel.selectedType) {
            viewModel.clearCategoryOnTypeChange()
        }
        .discardGuard(hasChanges: viewModel.hasChanges, showAlert: $showDiscardAlert)
        .alert(
            String(localized: "Lỗi"),
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
}

// MARK: - Form Sections

private extension AddRecurringView {
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
                    .foregroundStyle(
                        viewModel.selectedType == .expense
                            ? Color.appError : Color.appIncome
                    )

                Text("₫")
                    .font(Typography.titleLarge)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
        }
    }

    private var categorySection: some View {
        Section(String(localized: "Danh mục")) {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 76), spacing: Spacing.md)
            ], spacing: Spacing.md) {
                ForEach(filteredCategories) { cat in
                    categoryButton(cat)
                }
            }
            .padding(.vertical, Spacing.xs)
        }
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
}

// MARK: - Category Button

private extension AddRecurringView {
    private func categoryButton(
        _ cat: Category
    ) -> some View {
        let isSelected = viewModel.selectedCategory?.id == cat.id
        let catColor = Color(hex: cat.colorHex)

        return Button {
            viewModel.selectedCategory = cat
        } label: {
            VStack(spacing: Spacing.sm) {
                Image(systemName: cat.icon)
                    .font(.title3)
                    .frame(width: IconSize.containerXL, height: IconSize.containerXL)
                    .background(
                        isSelected
                            ? catColor.opacity(0.2)
                            : Color.surfaceContainerHigh
                    )
                    .clipShape(Circle())
                    .overlay {
                        if isSelected {
                            Circle().stroke(catColor, lineWidth: 2)
                        }
                    }
                Text(cat.localizedName)
                    .font(Typography.labelSmall)
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? catColor : Color.onSurface)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(cat.localizedName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Toolbar & Save

private extension AddRecurringView {
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
            Button(String(localized: "Lưu")) { save() }
                .fontWeight(.semibold)
                .disabled(!viewModel.canSave)
        }
    }

    private func save() {
        do {
            try viewModel.save(context: context)
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        HapticService.success()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AddRecurringView()
    }
    .modelContainer(
        for: [RecurringTransaction.self, Category.self],
        inMemory: true
    )
}
