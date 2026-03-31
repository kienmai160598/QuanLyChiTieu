import SwiftUI
import SwiftData

internal struct WithdrawFundsSheet: View {
    @Environment(\.modelContext) private var context

    internal let goal: SavingsGoal
    @Binding internal var isPresented: Bool
    @Bindable internal var viewModel: SavingsGoalDetailViewModel
    @FocusState private var isAmountFocused: Bool

    internal var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                currentBalanceCard
                amountInput
                saveButton
            }
            .padding(Spacing.lg)
            .appBackground()
            .navigationTitle(String(localized: "Rút tiền"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbar { toolbarContent }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(String(localized: "Huỷ")) {
                viewModel.withdrawFundsText = ""
                isPresented = false
            }
        }
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button(String(localized: "Xong")) { isAmountFocused = false }
        }
    }

    private var currentBalanceCard: some View {
        VStack(spacing: Spacing.sm) {
            Text(String(localized: "Số dư hiện tại"))
                .font(Typography.labelMedium)
                .foregroundStyle(Color.onSurfaceVariant)
            Text(goal.formattedCurrent)
                .font(Typography.headlineMedium)
                .foregroundStyle(Color.appIncome)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .m3Card(cornerRadius: Spacing.cornerExtraLarge, background: .surfaceContainerLow)
    }

    private var amountInput: some View {
        VStack(spacing: Spacing.lg) {
            Text(String(localized: "Số tiền rút"))
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurfaceVariant)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                TextField("0", text: $viewModel.withdrawFundsText)
                    .keyboardType(.numberPad)
                    .focused($isAmountFocused)
                    .font(Typography.headlineLarge)
                    .foregroundStyle(Color.onSurface)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel(String(localized: "Số tiền rút"))
                Text("\u{20AB}")
                    .font(Typography.headlineSmall)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(Spacing.xl)
        .m3Card(cornerRadius: Spacing.cornerExtraLarge, background: .surfaceContainerHigh)
    }

    private var saveButton: some View {
        GlassSaveButton(
            label: String(localized: "Rút tiền"),
            isEnabled: viewModel.parsedWithdrawAmount != nil && !viewModel.isSaving,
            tintColor: .appWarning
        ) { save() }
    }

    private func save() {
        let success = viewModel.withdrawFunds(from: goal, context: context)
        if success {
            HapticService.mediumImpact()
            isPresented = false
        }
    }
}
