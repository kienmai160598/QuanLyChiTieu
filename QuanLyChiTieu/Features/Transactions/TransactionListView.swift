import SwiftUI
import SwiftData

// MARK: - TransactionListView

internal struct TransactionListView: View {
    @Query(sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]

    @Environment(\.modelContext) private var context
    @State private var filterType: TransactionType?
    @State private var searchText = ""
    @State private var displayLimit = 50
    @State private var deleteError: String?

    internal var body: some View {
        Group {
            if transactions.isEmpty {
                emptyContent
            } else {
                listContent
            }
        }
        .appBackground()
        .toolbar { filterToolbar }
        .alert(String(localized: "Lỗi"), isPresented: Binding(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button(String(localized: "OK")) {}
        } message: {
            Text(deleteError ?? "")
        }
        .onChange(of: searchText) { _, _ in displayLimit = 50 }
        .onChange(of: filterType) { _, _ in displayLimit = 50 }
    }
}

// MARK: - List Content

private extension TransactionListView {
    private var listContent: some View {
        List {
            summarySection
            if filtered.isEmpty {
                filterEmptySection
            } else {
                transactionSections
                loadMoreSection
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .searchable(
            text: $searchText,
            prompt: String(localized: "Tìm kiếm giao dịch")
        )
        .animation(Motion.effectDefault, value: filterType)
    }

    private var emptyContent: some View {
        ScrollView {
            TransactionEmptyState()
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.xxxl)
        }
    }
}

// MARK: - Summary Section

private extension TransactionListView {
    private var summarySection: some View {
        Section {
            TransactionSummaryCards(transactions: filtered)
        }
        .listRowInsets(EdgeInsets(
            top: Spacing.sm, leading: Spacing.lg,
            bottom: Spacing.sm, trailing: Spacing.lg
        ))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

// MARK: - Transaction Sections

private extension TransactionListView {
    private var transactionSections: some View {
        ForEach(grouped, id: \.id) { group in
            Section {
                ForEach(group.transactions) { tx in
                    NavigationLink(value: TransactionRoute.detail(tx.persistentModelID)) {
                        TransactionRowView(transaction: tx)
                    }
                    .m3SectionRow()
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteTransaction(tx)
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        NavigationLink(value: TransactionRoute.edit(tx.persistentModelID)) {
                            Image(systemName: "pencil")
                        }
                        .tint(Color.appSecondary)
                    }
                }
            } header: {
                Text(group.label)
                    .font(Typography.titleSmall)
                    .foregroundStyle(Color.onSurfaceVariant)
                    .textCase(nil)
            }
        }
    }
}

// MARK: - Filter Empty

private extension TransactionListView {
    @ViewBuilder
    private var filterEmptySection: some View {
        Section {
            if !searchText.isEmpty {
                EmptyStateCard(
                    icon: "magnifyingglass",
                    title: String(localized: "Không tìm thấy"),
                    subtitle: String(localized: "Không có giao dịch phù hợp với từ khoá tìm kiếm")
                )
            } else {
                TransactionFilterEmptyState()
            }
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

// MARK: - Load More

private extension TransactionListView {
    @ViewBuilder
    private var loadMoreSection: some View {
        if filtered.count > displayLimit {
            Section {
                Button {
                    displayLimit += 50
                } label: {
                    Text(String(localized: "Tải thêm giao dịch"))
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Color.appSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .listRowBackground(Color.clear)
        }
    }
}

// MARK: - Filter Toolbar

private extension TransactionListView {
    @ToolbarContentBuilder
    private var filterToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    filterType = nil
                } label: {
                    Label(
                        String(localized: "Tất cả"),
                        systemImage: filterType == nil ? "checkmark" : ""
                    )
                }
                Button {
                    filterType = .expense
                } label: {
                    Label(
                        String(localized: "Chi tiêu"),
                        systemImage: filterType == .expense ? "checkmark" : ""
                    )
                }
                Button {
                    filterType = .income
                } label: {
                    Label(
                        String(localized: "Thu nhập"),
                        systemImage: filterType == .income ? "checkmark" : ""
                    )
                }
            } label: {
                Image(systemName: filterType == nil
                    ? "line.3.horizontal.decrease.circle"
                    : "line.3.horizontal.decrease.circle.fill")
            }
            .accessibilityLabel(String(localized: "Lọc giao dịch"))
        }
    }
}

// MARK: - Actions

private extension TransactionListView {
    private func deleteTransaction(_ tx: Transaction) {
        context.delete(tx)
        do {
            try context.save()
        } catch {
            deleteError = error.localizedDescription
        }
    }
}

// MARK: - Data

private extension TransactionListView {
    private var filtered: [Transaction] {
        var result = transactions
        if let filterType {
            result = result.filter { $0.type == filterType }
        }
        if !searchText.isEmpty {
            result = result.filter { matchesSearch($0) }
        }
        return result
    }

    private func matchesSearch(_ transaction: Transaction) -> Bool {
        let term = searchText
        if transaction.note.localizedCaseInsensitiveContains(term) { return true }
        if let name = transaction.category?.name, name.localizedCaseInsensitiveContains(term) { return true }
        if let localized = transaction.category?.localizedName, localized.localizedCaseInsensitiveContains(term) { return true }
        return false
    }

    private var paginated: [Transaction] {
        Array(filtered.prefix(displayLimit))
    }

    private var grouped: [TransactionDateGroup] {
        TransactionDateGroup.group(paginated)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TransactionListView()
    }
    .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
}
