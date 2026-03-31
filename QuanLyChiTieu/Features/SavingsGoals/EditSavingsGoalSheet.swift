import SwiftUI
import SwiftData

internal struct EditSavingsGoalSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: EditSavingsGoalViewModel
    @State private var showDiscardAlert = false
    @FocusState private var isAmountFocused: Bool
    @FocusState private var isNameFocused: Bool

    internal init(goal: SavingsGoal) {
        _viewModel = State(initialValue: EditSavingsGoalViewModel(goal: goal))
    }

    internal var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xxl) {
                    heroAmount
                    formFields
                    customization
                    errorBanner
                    saveButton
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxxl)
            }
            .appBackground()
            .navigationTitle(String(localized: "Sửa mục tiêu"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbar { toolbarItems }
            .discardGuard(hasChanges: viewModel.hasChanges, showAlert: $showDiscardAlert)
        }
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(String(localized: "Huỷ")) {
                if viewModel.hasChanges { showDiscardAlert = true } else { dismiss() }
            }
        }
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button(String(localized: "Xong")) {
                isAmountFocused = false
                isNameFocused = false
            }
        }
    }
}

// MARK: - Hero Amount

private extension EditSavingsGoalSheet {
    private var heroAmount: some View {
        VStack(spacing: Spacing.lg) {
            livePreview
            amountInput
        }
        .padding(Spacing.xl)
        .m3HeroCard()
    }

    private var livePreview: some View {
        VStack(spacing: Spacing.sm) {
            M3IconBadge(
                icon: viewModel.selectedIcon,
                color: Color(hex: viewModel.selectedColorHex),
                size: IconSize.containerXXL
            )
            if !viewModel.name.trimmingCharacters(in: .whitespaces).isEmpty {
                Text(viewModel.name)
                    .font(Typography.titleSmallEmphasized)
                    .foregroundStyle(Color.onSurface)
                    .lineLimit(1)
            }
        }
    }

    private var amountInput: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
            TextField("0", text: $viewModel.amountText)
                .keyboardType(.numberPad)
                .focused($isAmountFocused)
                .font(Typography.heroLarge)
                .monospacedDigit()
                .foregroundStyle(Color.onSurface)
                .multilineTextAlignment(.center)
                .onChange(of: viewModel.amountText) { viewModel.clearError() }
                .accessibilityLabel(String(localized: "Số tiền mục tiêu"))
            Text("₫")
                .font(Typography.headlineSmall)
                .foregroundStyle(Color.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Form Fields

private extension EditSavingsGoalSheet {
    private var formFields: some View {
        VStack(spacing: Spacing.md) {
            nameField
            deadlineField
        }
    }

    private var nameField: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "pencil")
                .font(.system(size: IconSize.md, weight: .medium))
                .foregroundStyle(Color.onSurfaceVariant)
                .frame(width: 24)
            TextField(
                String(localized: "Tên mục tiêu"),
                text: $viewModel.name
            )
            .font(Typography.bodyLarge)
            .focused($isNameFocused)
        }
        .padding(Spacing.lg)
        .m3Card()
    }

    private var deadlineField: some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "calendar")
                    .font(.system(size: IconSize.md, weight: .medium))
                    .foregroundStyle(Color.onSurfaceVariant)
                    .frame(width: 24)
                Text(String(localized: "Hạn chót"))
                    .font(Typography.bodyLarge)
                    .foregroundStyle(Color.onSurface)
                Spacer()
                Toggle("", isOn: $viewModel.hasDeadline)
                    .labelsHidden()
                    .tint(Color.appIncome)
            }
            .padding(Spacing.lg)

            if viewModel.hasDeadline {
                Divider().padding(.horizontal, Spacing.lg)
                DatePicker(
                    String(localized: "Chọn ngày"),
                    selection: $viewModel.deadline,
                    in: Date.now...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.md)
            }
        }
        .m3Card()
        .animation(Motion.spatialDefault, value: viewModel.hasDeadline)
    }
}

// MARK: - Customization

private extension EditSavingsGoalSheet {
    private var customization: some View {
        IconColorPicker(
            selectedIcon: $viewModel.selectedIcon,
            selectedColorHex: $viewModel.selectedColorHex
        )
    }
}

// MARK: - Error & Save

private extension EditSavingsGoalSheet {
    private var errorBanner: some View {
        ErrorBannerView(message: viewModel.errorMessage)
    }

    private var saveButton: some View {
        GlassSaveButton(
            label: String(localized: "Lưu thay đổi"),
            isEnabled: viewModel.canSave
        ) {
            let success = viewModel.save(context: context)
            if success {
                HapticService.success()
                dismiss()
            }
        }
    }
}
