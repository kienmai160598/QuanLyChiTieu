import SwiftUI

// MARK: - TransactionAmountField
//
// Shared amount-entry row used by AddTransactionView and EditTransactionView.
// Accepts a binding to the raw digit string and renders a formatted TextField
// alongside the ₫ currency symbol.

internal struct TransactionAmountField: View {

    // MARK: - Parameters

    @Binding private var digits: String

    // MARK: - Init

    internal init(digits: Binding<String>) {
        _digits = digits
    }

    // MARK: - Private

    private var formattedBinding: Binding<String> {
        Binding(
            get: {
                guard let number = Int(digits), number > 0 else { return digits }
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.groupingSeparator = ","
                return formatter.string(from: NSNumber(value: number)) ?? digits
            },
            set: { newValue in
                digits = newValue.filter(\.isNumber)
            }
        )
    }

    // MARK: - Body

    internal var body: some View {
        Section {
            amountRow
        }
    }

    private var amountRow: some View {
        HStack(spacing: Spacing.xs) {
            TextField("0", text: formattedBinding)
                .keyboardType(.numberPad)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
            Text("₫")
                .font(.system(size: 28, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .listRowBackground(Color.clear)
    }
}
