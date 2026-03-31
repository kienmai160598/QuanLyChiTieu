import SwiftUI

// MARK: - TransactionDetailsFields
//
// Shared details section used by AddTransactionView and EditTransactionView.
// Renders a note TextField and a DatePicker.

internal struct TransactionDetailsFields: View {

    // MARK: - Parameters

    @Binding private var note: String
    @Binding private var date: Date

    // MARK: - Init

    internal init(
        note: Binding<String>,
        date: Binding<Date>
    ) {
        _note = note
        _date = date
    }

    // MARK: - Body

    internal var body: some View {
        Section {
            TextField(String(localized: "Ghi chú"), text: $note)
                .onChange(of: note) { _, newValue in
                    if newValue.count > 200 { note = String(newValue.prefix(200)) }
                }
            DatePicker(
                String(localized: "Ngày"),
                selection: $date,
                displayedComponents: .date
            )
        }
    }
}
