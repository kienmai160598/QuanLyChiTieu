import SwiftUI
import SwiftData

internal struct AddSavingsGoalSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = AddSavingsGoalViewModel()
    @State private var showDiscardAlert = false
    @State private var showTemplatesSheet = false
    @FocusState private var isAmountFocused: Bool
    @FocusState private var isNameFocused: Bool

    internal var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xxl) {
                    templateButton
                    heroAmount
                    formFields
                    categoryPicker
                    customization
                    errorBanner
                    saveButton
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxxl)
            }
            .appBackground()
            .navigationTitle(String(localized: "Mục tiêu mới"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbar { toolbarItems }
            .discardGuard(hasChanges: viewModel.hasChanges, showAlert: $showDiscardAlert)
            .sheet(isPresented: $showTemplatesSheet) {
                SavingsGoalTemplatesSheet { template in
                    HapticService.mediumImpact()
                    withAnimation(Motion.spatialDefault) {
                        viewModel.loadFromTemplate(template)
                    }
                }
            }
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

    private var templateButton: some View {
        Button {
            HapticService.lightImpact()
            showTemplatesSheet = true
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: IconSize.md, weight: .medium))
                Text(String(localized: "Chọn từ mẫu"))
                    .font(Typography.labelLargeEmphasized)
            }
            .foregroundStyle(Color.onSurface)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .frame(maxWidth: .infinity)
            .background(Color.surfaceContainerHigh, in: Capsule())
            .overlay {
                Capsule().strokeBorder(Color.outlineVariant, lineWidth: 1)
            }
        }
        .buttonStyle(ExpressivePressStyle())
    }
}

// MARK: - Hero Amount

private extension AddSavingsGoalSheet {
    private var heroAmount: some View {
        VStack(spacing: Spacing.lg) {
            livePreview
            amountInput
            quickAmounts
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

    private static let presetAmounts: [(String, String)] = [
        ("5tr", "5000000"),
        ("10tr", "10000000"),
        ("20tr", "20000000"),
        ("50tr", "50000000"),
    ]

    private var quickAmounts: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(Self.presetAmounts, id: \.1) { label, value in
                quickChip(label: label, value: value)
            }
        }
    }

    private func quickChip(label: String, value: String) -> some View {
        let isSelected = viewModel.amountText == value
        return Button {
            HapticService.lightImpact()
            withAnimation(Motion.spatialFast) {
                viewModel.amountText = value
            }
        } label: {
            Text(label)
                .font(isSelected ? Typography.labelLargeEmphasized : Typography.labelLarge)
                .foregroundStyle(isSelected ? Color.onPrimary : Color.onSurface)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .frame(maxWidth: .infinity)
                .background(
                    isSelected ? Color.appPrimary : Color.surfaceContainerHigh,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Form Fields

private extension AddSavingsGoalSheet {
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
                String(localized: "Tên mục tiêu (VD: Mua iPhone)"),
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

// MARK: - Category Picker

private extension AddSavingsGoalSheet {
    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "Loại mục tiêu"))
                .font(Typography.labelMedium)
                .foregroundStyle(Color.onSurfaceVariant)
                .padding(.horizontal, Spacing.xs)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(SavingsCategory.allCases, id: \.rawValue) { category in
                        categoryChip(category)
                    }
                }
            }
        }
    }

    private func categoryChip(_ category: SavingsCategory) -> some View {
        let isSelected = viewModel.selectedCategory == category

        return Button {
            HapticService.lightImpact()
            withAnimation(Motion.spatialFast) {
                if viewModel.selectedCategory == category {
                    viewModel.selectedCategory = nil
                } else {
                    viewModel.selectedCategory = category
                }
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: category.icon)
                    .font(.system(size: IconSize.sm, weight: .medium))
                Text(category.displayName)
                    .font(isSelected ? Typography.labelMediumEmphasized : Typography.labelMedium)
            }
            .foregroundStyle(isSelected ? Color.onPrimary : Color.onSurface)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                isSelected
                    ? Color.appPrimary
                    : Color.surfaceContainerHigh,
                in: isSelected
                    ? AnyShape(Capsule())
                    : AnyShape(RoundedRectangle(cornerRadius: Spacing.cornerMedium))
            )
            .overlay {
                if !isSelected {
                    RoundedRectangle(cornerRadius: Spacing.cornerMedium)
                        .strokeBorder(Color.outlineVariant, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Icon & Color Customization

private extension AddSavingsGoalSheet {
    private var customization: some View {
        IconColorPicker(
            selectedIcon: $viewModel.selectedIcon,
            selectedColorHex: $viewModel.selectedColorHex
        )
    }
}

// MARK: - Error & Save

private extension AddSavingsGoalSheet {
    private var errorBanner: some View {
        ErrorBannerView(message: viewModel.errorMessage)
    }

    private var saveButton: some View {
        GlassSaveButton(
            label: String(localized: "Tạo mục tiêu"),
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
