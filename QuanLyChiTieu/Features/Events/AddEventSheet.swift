import SwiftUI
import SwiftData

internal struct AddEventSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = AddEventViewModel()
    @State private var showDiscardAlert = false
    @FocusState private var focusedField: EventField?

    internal var body: some View {
        NavigationStack {
            sheetContent
                .appBackground()
                .navigationTitle(String(localized: "Thêm sự kiện"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
                .toolbar { sheetToolbar }
                .discardGuard(hasChanges: viewModel.hasChanges, showAlert: $showDiscardAlert)
        }
    }

    @ToolbarContentBuilder
    private var sheetToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(String(localized: "Huỷ")) {
                if viewModel.hasChanges {
                    showDiscardAlert = true
                } else {
                    dismiss()
                }
            }
        }
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button(String(localized: "Xong")) { focusedField = nil }
        }
    }

    private var sheetContent: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                nameAndBudgetSection
                iconColorSection
                dateSection
                notesField
                errorBanner
                saveButton
            }
            .padding(Spacing.lg)
        }
    }
}

// MARK: - Name & Budget

private extension AddEventSheet {
    private var nameAndBudgetSection: some View {
        VStack(spacing: Spacing.lg) {
            nameField
            budgetField
        }
        .padding(Spacing.xl)
        .m3Card(cornerRadius: Spacing.cornerExtraLarge, background: .surfaceContainerHigh)
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(String(localized: "Tên sự kiện"))
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurfaceVariant)
            TextField(String(localized: "VD: Du lịch Đà Lạt"), text: $viewModel.name)
                .focused($focusedField, equals: .name)
        }
    }

    private var budgetField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(String(localized: "Ngân sách"))
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurfaceVariant)
            HStack(spacing: Spacing.sm) {
                TextField("0", text: $viewModel.budgetText)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .budget)
                    .font(Typography.headlineSmall)
                    .foregroundStyle(Color.onSurface)
                    .onChange(of: viewModel.budgetText) { viewModel.clearError() }
                Text("₫")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
        }
    }
}

// MARK: - Icon & Color

private extension AddEventSheet {
    private var iconColorSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            iconPicker
            colorPicker
        }
        .padding(Spacing.xl)
        .m3Card(cornerRadius: Spacing.cornerExtraLarge, background: .surfaceContainerHigh)
    }

    private var iconPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "Biểu tượng"))
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurfaceVariant)
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 6),
                spacing: Spacing.sm
            ) {
                ForEach(AddEventViewModel.iconOptions, id: \.self) { icon in
                    iconButton(icon)
                }
            }
        }
    }

    private func iconButton(_ icon: String) -> some View {
        let isSelected = viewModel.icon == icon
        return Button { viewModel.icon = icon } label: {
            Image(systemName: icon)
                .font(Typography.bodyLarge)
                .foregroundStyle(isSelected ? Color.appPrimary : Color.onSurfaceVariant)
                .frame(width: IconSize.containerLG, height: IconSize.containerLG)
                .background(isSelected ? Color.primaryContainer.opacity(0.3) : .clear)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerSmall))
        }
        .accessibilityLabel(icon)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "Màu sắc"))
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurfaceVariant)
            HStack(spacing: Spacing.md) {
                ForEach(AddEventViewModel.colorOptions, id: \.self) { hex in
                    colorButton(hex)
                }
            }
        }
    }

    private func colorButton(_ hex: String) -> some View {
        let isSelected = viewModel.colorHex == hex
        return Button { viewModel.colorHex = hex } label: {
            Circle()
                .fill(Color(hex: hex))
                .frame(width: IconSize.containerSM, height: IconSize.containerSM)
                .overlay {
                    if isSelected {
                        Circle()
                            .strokeBorder(Color.onSurface, lineWidth: 2)
                    }
                }
        }
        .accessibilityLabel(hex)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Date Section

private extension AddEventSheet {
    private var dateSection: some View {
        VStack(spacing: Spacing.md) {
            DatePicker(
                String(localized: "Ngày bắt đầu"),
                selection: $viewModel.startDate,
                displayedComponents: .date
            )
            DatePicker(
                String(localized: "Ngày kết thúc"),
                selection: $viewModel.endDate,
                displayedComponents: .date
            )
        }
        .padding(Spacing.xl)
        .m3Card(cornerRadius: Spacing.cornerExtraLarge, background: .surfaceContainerHigh)
    }
}

// MARK: - Notes, Error & Save

private extension AddEventSheet {
    private var notesField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(String(localized: "Ghi chú"))
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurfaceVariant)
            TextField(
                String(localized: "Ghi chú thêm..."),
                text: $viewModel.notes,
                axis: .vertical
            )
            .lineLimit(3...6)
            .focused($focusedField, equals: .notes)
        }
        .padding(Spacing.xl)
        .m3Card(cornerRadius: Spacing.cornerExtraLarge, background: .surfaceContainerHigh)
    }

    private var errorBanner: some View {
        ErrorBannerView(message: viewModel.errorMessage)
    }

    private var saveButton: some View {
        GlassSaveButton(
            label: String(localized: "Tạo sự kiện"),
            isEnabled: viewModel.canSave
        ) { save() }
    }

    private func save() {
        let success = viewModel.save(context: context)
        if success {
            HapticService.success()
            dismiss()
        }
    }
}

// MARK: - Focus Field

private enum EventField: Hashable {
    case name
    case budget
    case notes
}
