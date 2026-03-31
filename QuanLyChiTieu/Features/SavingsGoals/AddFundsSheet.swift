import SwiftUI
import SwiftData

internal struct AddFundsSheet: View {
    @Environment(\.modelContext) private var context

    internal let goal: SavingsGoal
    @Binding internal var isPresented: Bool
    @Bindable internal var viewModel: SavingsGoalDetailViewModel
    @FocusState private var isAmountFocused: Bool

    internal var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                remainingCard
                amountInput
                saveButton
            }
            .padding(Spacing.lg)
            .appBackground()
            .navigationTitle(String(localized: "Thêm tiền"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbar { toolbarContent }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(String(localized: "Huỷ")) {
                viewModel.addFundsText = ""
                isPresented = false
            }
        }
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button(String(localized: "Xong")) { isAmountFocused = false }
        }
    }

    private var remainingCard: some View {
        VStack(spacing: Spacing.sm) {
            Text(String(localized: "Còn thiếu"))
                .font(Typography.labelMedium)
                .foregroundStyle(Color.onSurfaceVariant)
            Text(goal.formattedRemaining)
                .font(Typography.headlineMedium)
                .foregroundStyle(Color.appIncome)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .m3Card(cornerRadius: Spacing.cornerExtraLarge, background: .surfaceContainerLow)
    }

    private var amountInput: some View {
        VStack(spacing: Spacing.lg) {
            Text(String(localized: "Số tiền thêm"))
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurfaceVariant)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                TextField("0", text: $viewModel.addFundsText)
                    .keyboardType(.numberPad)
                    .focused($isAmountFocused)
                    .font(Typography.headlineLarge)
                    .foregroundStyle(Color.onSurface)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel(String(localized: "Số tiền thêm"))
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
            label: String(localized: "Thêm tiền"),
            isEnabled: viewModel.parsedFundsAmount != nil && !viewModel.isSaving,
            tintColor: .appIncome
        ) { save() }
    }

    private func save() {
        let success = viewModel.addFunds(to: goal, context: context)
        if success {
            HapticService.success()
            isPresented = false
        }
    }
}
