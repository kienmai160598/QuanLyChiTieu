import SwiftUI
import SwiftData

internal struct AddSavingsGoalSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = AddSavingsGoalViewModel()
    @State private var showDiscardAlert = false
    @FocusState private var isAmountFocused: Bool
    @FocusState private var isNameFocused: Bool

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
            .navigationTitle(String(localized: "Mục tiêu mới"))
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

// MARK: - Icon & Color Customization

private extension AddSavingsGoalSheet {
    private static let availableIcons: [String] = [
        "fork.knife", "car.fill", "bag.fill", "heart.fill",
        "house.fill", "book.fill", "gamecontroller.fill", "gift.fill",
        "banknote.fill", "doc.text.fill", "cross.fill", "airplane",
        "tram.fill", "cart.fill", "graduationcap.fill", "paintbrush.fill",
        "wrench.fill", "music.note", "film.fill", "person.2.fill",
    ]

    private static let presetColors: [String] = [
        "#D7A49A", "#A4B1BA", "#B5B89A", "#E4C9B6",
        "#E1DAD3", "#C4877D", "#8A97A0", "#3D3633",
    ]

    private var customization: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            iconPicker
            Divider()
            colorPicker
        }
        .padding(Spacing.lg)
        .m3Card()
    }

    private var iconPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "Biểu tượng"))
                .font(Typography.labelMedium)
                .foregroundStyle(Color.onSurfaceVariant)
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 5),
                spacing: Spacing.sm
            ) {
                ForEach(Self.availableIcons, id: \.self) { icon in
                    iconCell(icon)
                }
            }
        }
    }

    private func iconCell(_ icon: String) -> some View {
        let isSelected = viewModel.selectedIcon == icon
        return Button {
            withAnimation(Motion.spatialFast) {
                viewModel.selectedIcon = icon
            }
        } label: {
            Image(systemName: icon)
                .font(.system(size: IconSize.md, weight: .medium))
                .foregroundStyle(isSelected ? Color.onPrimary : Color.onSurfaceVariant)
                .frame(width: 44, height: 44)
                .background(
                    isSelected ? Color.appPrimary : Color.surfaceContainerHigh,
                    in: RoundedRectangle(cornerRadius: isSelected ? Spacing.cornerMedium : Spacing.cornerSmall)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(icon)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "Màu sắc"))
                .font(Typography.labelMedium)
                .foregroundStyle(Color.onSurfaceVariant)
            HStack(spacing: Spacing.md) {
                ForEach(Self.presetColors, id: \.self) { hex in
                    colorCell(hex)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func colorCell(_ hex: String) -> some View {
        let isSelected = viewModel.selectedColorHex == hex
        return Button {
            withAnimation(Motion.spatialFast) {
                viewModel.selectedColorHex = hex
            }
        } label: {
            Circle()
                .fill(Color(hex: hex))
                .frame(width: 32, height: 32)
                .scaleEffect(isSelected ? 1.2 : 1.0)
                .overlay {
                    if isSelected {
                        Circle().strokeBorder(Color.onSurface, lineWidth: 2.5)
                            .frame(width: 32, height: 32)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(hex)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
