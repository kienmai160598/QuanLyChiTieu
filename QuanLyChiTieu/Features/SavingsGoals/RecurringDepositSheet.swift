import SwiftUI
import SwiftData

// MARK: - RecurringDepositSheet

internal struct RecurringDepositSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    internal let goal: SavingsGoal
    internal let existingDeposit: RecurringSavingsDeposit?

    @State private var viewModel: RecurringDepositViewModel

    @FocusState private var isAmountFocused: Bool

    internal init(goal: SavingsGoal, existingDeposit: RecurringSavingsDeposit? = nil) {
        self.goal = goal
        self.existingDeposit = existingDeposit
        _viewModel = State(initialValue: RecurringDepositViewModel(existingDeposit: existingDeposit))
    }

    internal var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xxl) {
                    amountSection
                    frequencySection
                    datesSection
                    errorBanner
                    saveButton
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxxl)
            }
            .appBackground()
            .navigationTitle(String(localized: "Nạp tiền tự động"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbar { toolbarItems }
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(Spacing.cornerExtraExtraLarge)
        .presentationBackground(Color.surfaceContainerLowest)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(String(localized: "Huỷ")) {
                dismiss()
            }
        }
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button(String(localized: "Xong")) {
                isAmountFocused = false
            }
        }
    }
}

// MARK: - Amount Section

private extension RecurringDepositSheet {
    private var amountSection: some View {
        VStack(spacing: Spacing.lg) {
            amountInput
            quickAmounts
        }
        .padding(Spacing.xl)
        .m3Card(cornerRadius: Spacing.cornerExtraLarge, background: .surfaceContainerHigh)
    }

    private var amountInput: some View {
        VStack(spacing: Spacing.sm) {
            Text(String(localized: "Số tiền"))
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurfaceVariant)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                TextField("0", text: $viewModel.amountText)
                    .keyboardType(.numberPad)
                    .focused($isAmountFocused)
                    .font(Typography.headlineLarge)
                    .monospacedDigit()
                    .foregroundStyle(Color.onSurface)
                    .multilineTextAlignment(.center)
                    .onChange(of: viewModel.amountText) { viewModel.clearError() }
                    .accessibilityLabel(String(localized: "Số tiền nạp tự động"))
                Text("\u{20AB}")
                    .font(Typography.headlineSmall)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private static let presetAmounts: [(String, String)] = [
        ("100K", "100000"),
        ("500K", "500000"),
        ("1tr", "1000000"),
        ("2tr", "2000000"),
        ("5tr", "5000000"),
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
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.sm)
                .frame(maxWidth: .infinity)
                .background(
                    isSelected ? Color.appPrimary : Color.surfaceContainerLow,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Frequency Section

private extension RecurringDepositSheet {
    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(String(localized: "Tần suất"))
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurfaceVariant)

            HStack(spacing: Spacing.sm) {
                ForEach(RecurrenceFrequency.allCases, id: \.self) { frequency in
                    frequencyChip(frequency)
                }
            }
        }
        .padding(Spacing.lg)
        .m3Card()
    }

    private func frequencyChip(_ frequency: RecurrenceFrequency) -> some View {
        let isSelected = viewModel.selectedFrequency == frequency
        return Button {
            HapticService.lightImpact()
            withAnimation(Motion.spatialFast) {
                viewModel.selectedFrequency = frequency
            }
        } label: {
            Text(frequency.displayName)
                .font(isSelected ? Typography.labelMediumEmphasized : Typography.labelMedium)
                .foregroundStyle(isSelected ? Color.onPrimary : Color.onSurface)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .frame(maxWidth: .infinity)
                .background(
                    isSelected ? Color.appPrimary : Color.surfaceContainerHigh,
                    in: isSelected ? AnyShape(Capsule()) : AnyShape(RoundedRectangle(cornerRadius: Spacing.cornerMedium))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Dates Section

private extension RecurringDepositSheet {
    private var datesSection: some View {
        VStack(spacing: 0) {
            startDateRow
            Divider().padding(.horizontal, Spacing.lg)
            endDateToggleRow
            if viewModel.hasEndDate {
                Divider().padding(.horizontal, Spacing.lg)
                endDatePicker
            }
        }
        .m3Card()
        .animation(Motion.spatialDefault, value: viewModel.hasEndDate)
    }

    private var startDateRow: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "calendar")
                .font(.system(size: IconSize.md, weight: .medium))
                .foregroundStyle(Color.onSurfaceVariant)
                .frame(width: 24)
            Text(String(localized: "Ngày bắt đầu"))
                .font(Typography.bodyLarge)
                .foregroundStyle(Color.onSurface)
            Spacer()
            DatePicker(
                "",
                selection: $viewModel.startDate,
                in: Date.now...,
                displayedComponents: .date
            )
            .labelsHidden()
            .tint(Color.appPrimary)
        }
        .padding(Spacing.lg)
    }

    private var endDateToggleRow: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: IconSize.md, weight: .medium))
                .foregroundStyle(Color.onSurfaceVariant)
                .frame(width: 24)
            Text(String(localized: "Ngày kết thúc"))
                .font(Typography.bodyLarge)
                .foregroundStyle(Color.onSurface)
            Spacer()
            Toggle("", isOn: $viewModel.hasEndDate)
                .labelsHidden()
                .tint(Color.appIncome)
        }
        .padding(Spacing.lg)
    }

    private var endDatePicker: some View {
        DatePicker(
            String(localized: "Chọn ngày kết thúc"),
            selection: $viewModel.endDate,
            in: viewModel.startDate...,
            displayedComponents: .date
        )
        .datePickerStyle(.graphical)
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.md)
    }
}

// MARK: - Error & Save

private extension RecurringDepositSheet {
    private var errorBanner: some View {
        ErrorBannerView(message: viewModel.errorMessage)
    }

    private var saveButton: some View {
        GlassSaveButton(
            label: existingDeposit == nil
                ? String(localized: "Tạo nạp tiền tự động")
                : String(localized: "Cập nhật"),
            isEnabled: viewModel.canSave,
            tintColor: .appIncome
        ) {
            let success = viewModel.save(goal: goal, existingDeposit: existingDeposit, context: context)
            if success {
                HapticService.success()
                dismiss()
            }
        }
    }
}

// MARK: - ViewModel

@MainActor @Observable
internal final class RecurringDepositViewModel {

    // MARK: - State

    internal var amountText: String = ""
    internal var selectedFrequency: RecurrenceFrequency = .monthly
    internal var startDate: Date = .now
    internal var hasEndDate: Bool = false
    internal var endDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: .now) ?? .now
    internal var errorMessage: String?

    // MARK: - Init

    internal init(existingDeposit: RecurringSavingsDeposit? = nil) {
        if let deposit = existingDeposit {
            amountText = "\(deposit.amount)"
            selectedFrequency = deposit.frequency
            startDate = deposit.startDate
            hasEndDate = deposit.endDate != nil
            endDate = deposit.endDate ?? Calendar.current.date(byAdding: .year, value: 1, to: .now) ?? .now
        }
    }

    // MARK: - Computed

    internal var parsedAmount: Decimal? {
        amountText.parsedVNDAmount
    }

    internal var canSave: Bool {
        parsedAmount != nil
    }

    // MARK: - Actions

    internal func clearError() {
        errorMessage = nil
    }

    internal func save(
        goal: SavingsGoal,
        existingDeposit: RecurringSavingsDeposit?,
        context: ModelContext
    ) -> Bool {
        guard let amount = parsedAmount else {
            errorMessage = String(localized: "Số tiền phải lớn hơn 0")
            return false
        }

        let effectiveEndDate: Date? = hasEndDate ? endDate : nil

        if let existing = existingDeposit {
            existing.amount = amount
            existing.frequency = selectedFrequency
            existing.startDate = startDate
            existing.endDate = effectiveEndDate
            existing.isActive = true
        } else {
            let newDeposit = RecurringSavingsDeposit(
                amount: amount,
                frequency: selectedFrequency,
                startDate: startDate,
                endDate: effectiveEndDate,
                isActive: true,
                goal: goal
            )
            context.insert(newDeposit)
            goal.recurringDeposit = newDeposit
        }

        do {
            try context.save()
            return true
        } catch {
            errorMessage = String(localized: "Không thể lưu cài đặt")
            return false
        }
    }
}

#Preview("Create Mode") {
    RecurringDepositSheet(
        goal: SavingsGoal(
            name: "Mua iPhone",
            targetAmount: 30_000_000,
            icon: "iphone",
            colorHex: "#C15F3C"
        )
    )
}

#Preview("Edit Mode") {
    let goal = SavingsGoal(
        name: "Du lịch",
        targetAmount: 50_000_000,
        icon: "airplane",
        colorHex: "#5A8A5A"
    )
    let deposit = RecurringSavingsDeposit(
        amount: 2_000_000,
        frequency: .monthly,
        startDate: .now,
        goal: goal
    )
    return RecurringDepositSheet(goal: goal, existingDeposit: deposit)
}
