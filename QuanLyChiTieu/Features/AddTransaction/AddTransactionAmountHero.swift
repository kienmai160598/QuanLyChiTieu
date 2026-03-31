import SwiftUI

// MARK: - AddTransactionAmountHero

internal struct AddTransactionAmountHero: View {
    @Bindable internal var viewModel: AddTransactionViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var hasAmount: Bool { viewModel.parsedAmount > 0 }
    private var amountColor: Color { viewModel.selectedType == .expense ? .appError : .appIncome }

    internal var body: some View {
        amountRow
            .padding(.vertical, Spacing.xl)
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(String(localized: "So tien"))
            .accessibilityValue(String(localized: "\(viewModel.displayAmount) VND"))
    }
}

// MARK: - Amount Display

private extension AddTransactionAmountHero {
    private var amountRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
            Text(hasAmount ? viewModel.displayAmount : "0")
                .font(Typography.heroLarge)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .contentTransition(.numericText(value: Double(
                    truncating: viewModel.parsedAmount as NSDecimalNumber
                )))
            Text("₫")
                .font(Typography.headlineMedium)
        }
        .foregroundStyle(hasAmount ? amountColor : Color.onSurfaceVariant.opacity(0.4))
        .animation(reduceMotion ? .none : Motion.effectDefault, value: viewModel.rawAmountDigits)
        .animation(reduceMotion ? .none : Motion.spatialDefault, value: viewModel.selectedType)
    }
}
