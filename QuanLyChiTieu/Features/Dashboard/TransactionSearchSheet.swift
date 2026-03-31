import SwiftUI

// MARK: - Transaction Search Sheet

internal struct TransactionSearchSheet: View {
    internal let transactions: [Transaction]
    internal var zoomNamespace: Namespace.ID?

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var results: [Transaction] {
        guard !searchText.isEmpty else { return [] }
        return transactions.filter { tx in
            tx.note.localizedCaseInsensitiveContains(searchText)
                || tx.category?.localizedName.localizedCaseInsensitiveContains(searchText) == true
                || tx.category?.name.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    internal var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    ContentUnavailableView(
                        String(localized: "Tìm kiếm giao dịch"),
                        systemImage: "magnifyingglass",
                        description: Text(String(localized: "Nhập tên, ghi chú hoặc danh mục"))
                    )
                } else if results.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ScrollView {
                        TransactionGroupView(
                            transactions: results,
                            zoomNamespace: zoomNamespace
                        )
                        .scenePadding(.horizontal)
                        .padding(.vertical, Spacing.sm)
                    }
                }
            }
            .navigationTitle(String(localized: "Tìm kiếm"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: String(localized: "Ghi chú, danh mục..."))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Đóng")) { dismiss() }
                }
            }
        }
    }
}
