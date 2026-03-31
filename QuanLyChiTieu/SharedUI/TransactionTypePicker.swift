import SwiftUI

// MARK: - TransactionTypePicker
//
// Shared transaction-type selector used by AddTransactionView and EditTransactionView.
// Renders two rows (expense / income) with a checkmark on the active selection.

internal struct TransactionTypePicker: View {

    // MARK: - Parameters

    @Binding private var selectedType: TransactionType

    // MARK: - Init

    internal init(selectedType: Binding<TransactionType>) {
        _selectedType = selectedType
    }

    // MARK: - Body

    internal var body: some View {
        Section {
            typeRow(
                type: .expense,
                icon: "arrow.down.circle",
                label: String(localized: "Chi tiêu")
            )
            typeRow(
                type: .income,
                icon: "arrow.up.circle",
                label: String(localized: "Thu nhập")
            )
        }
    }

    // MARK: - Private

    @ViewBuilder
    private func typeRow(type: TransactionType, icon: String, label: String) -> some View {
        Button {
            selectedType = type
        } label: {
            HStack {
                Image(systemName: icon)
                Text(label)
                Spacer()
                if selectedType == type {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                        .foregroundStyle(.tint)
                }
            }
        }
        .foregroundStyle(.primary)
    }
}
