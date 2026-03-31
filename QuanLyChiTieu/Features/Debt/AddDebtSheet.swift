import SwiftUI
import SwiftData

internal struct AddDebtSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = AddDebtViewModel()
    @State private var showDiscardAlert = false
    @FocusState private var focusedField: DebtField?

    internal var body: some View {
        NavigationStack {
            sheetContent
                .appBackground()
                .navigationTitle(String(localized: "Thêm khoản nợ"))
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
                debtTypeToggle
                formFields
                dateSection
                notesField
                errorBanner
                saveButton
            }
            .padding(Spacing.lg)
        }
    }
}

// MARK: - Debt Type Toggle

private extension AddDebtSheet {
    private var debtTypeToggle: some View {
        Picker(String(localized: "Loại"), selection: $viewModel.isLent) {
            Text(String(localized: "Cho vay")).tag(true)
            Text(String(localized: "Đi vay")).tag(false)
        }
        .pickerStyle(.segmented)
        .accessibilityLabel(String(localized: "Loại khoản nợ"))
    }
}

// MARK: - Form Fields

private extension AddDebtSheet {
    private var formFields: some View {
        VStack(spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(String(localized: "Tiêu đề"))
                    .font(Typography.titleSmall)
                    .foregroundStyle(Color.onSurfaceVariant)
                TextField(String(localized: "VD: Vay mua xe"), text: $viewModel.title)
                    .focused($focusedField, equals: .title)
                    .textContentType(.name)
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(String(localized: "Tên người"))
                    .font(Typography.titleSmall)
                    .foregroundStyle(Color.onSurfaceVariant)
                TextField(String(localized: "VD: Nguyễn Văn A"), text: $viewModel.personName)
                    .focused($focusedField, equals: .personName)
                    .textContentType(.name)
            }
            amountField
            interestRateField
        }
        .padding(Spacing.xl)
        .m3Card(cornerRadius: Spacing.cornerExtraLarge, background: .surfaceContainerHigh)
    }

    private var amountField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(String(localized: "Số tiền"))
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurfaceVariant)
            HStack(spacing: Spacing.sm) {
                TextField("0", text: $viewModel.amountText)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .amount)
                    .font(Typography.headlineSmall)
                    .foregroundStyle(Color.onSurface)
                    .onChange(of: viewModel.amountText) {
                        viewModel.clearError()
                    }
                Text("₫")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
        }
    }

    private var interestRateField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(String(localized: "Lãi suất (tuỳ chọn)"))
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurfaceVariant)
            HStack(spacing: Spacing.sm) {
                TextField("0", text: $viewModel.interestRateText)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .interestRate)
                    .font(Typography.bodyLarge)
                    .foregroundStyle(Color.onSurface)
                Text("%")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
        }
    }
}

// MARK: - Date & Notes

private extension AddDebtSheet {
    private var dateSection: some View {
        VStack(spacing: Spacing.md) {
            DatePicker(
                String(localized: "Ngày bắt đầu"),
                selection: $viewModel.startDate,
                displayedComponents: .date
            )
            Toggle(
                String(localized: "Có hạn trả"),
                isOn: $viewModel.hasDueDate
            )
            if viewModel.hasDueDate {
                DatePicker(
                    String(localized: "Hạn trả"),
                    selection: $viewModel.dueDate,
                    displayedComponents: .date
                )
            }
        }
        .padding(Spacing.xl)
        .m3Card(cornerRadius: Spacing.cornerExtraLarge, background: .surfaceContainerHigh)
    }

    private var notesField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(String(localized: "Ghi chú"))
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurfaceVariant)
            TextField(String(localized: "Ghi chú thêm..."), text: $viewModel.notes, axis: .vertical)
                .lineLimit(3...6)
                .focused($focusedField, equals: .notes)
        }
        .padding(Spacing.xl)
        .m3Card(cornerRadius: Spacing.cornerExtraLarge, background: .surfaceContainerHigh)
    }
}

// MARK: - Error & Save

private extension AddDebtSheet {
    private var errorBanner: some View {
        ErrorBannerView(message: viewModel.errorMessage)
    }

    private var saveButton: some View {
        GlassSaveButton(
            label: String(localized: "Lưu khoản nợ"),
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

private enum DebtField: Hashable {
    case title
    case personName
    case amount
    case interestRate
    case notes
}
