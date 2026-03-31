import SwiftUI
import SwiftData

// MARK: - RecurringTransactionView

internal struct RecurringTransactionView: View {
    @Query(sort: \RecurringTransaction.startDate, order: .reverse)
    private var recurringItems: [RecurringTransaction]

    @Environment(\.modelContext) private var context
    @State private var showAddSheet = false
    @State private var recurringToDelete: RecurringTransaction?
    @State private var recurringToEdit: RecurringTransaction?
    @State private var errorMessage: String?

    internal var body: some View {
        Group {
            if recurringItems.isEmpty {
                emptyContent
            } else {
                listContent
            }
        }
        .appBackground()
        .navigationTitle(String(localized: "Giao dịch định kỳ"))
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .toolbar { addToolbar }
        .sheet(isPresented: $showAddSheet) {
            NavigationStack { AddRecurringView() }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(Spacing.cornerExtraExtraLarge)
                .presentationBackground(Color.surfaceContainerLowest)
        }
        .confirmationDialog(
            String(localized: "Xoá giao dịch định kỳ"),
            isPresented: deleteDialogBinding,
            titleVisibility: .visible
        ) { deleteDialogButtons } message: {
            Text(String(localized: "Bạn có chắc muốn xoá giao dịch định kỳ này?"))
        }
        .sheet(item: $recurringToEdit) { recurring in
            NavigationStack { EditRecurringView(recurring: recurring) }
                .presentationDetents([.large])
        }
        .alert(String(localized: "Lỗi"), isPresented: errorAlertBinding) {
            Button(String(localized: "OK")) { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }

    private var activeItems: [RecurringTransaction] {
        recurringItems.filter(\.isActive)
    }

    private var inactiveItems: [RecurringTransaction] {
        recurringItems.filter { !$0.isActive }
    }
}

// MARK: - Content

private extension RecurringTransactionView {
    var emptyContent: some View {
        ScrollView {
            EmptyStateCard(
                icon: "arrow.triangle.2.circlepath",
                title: String(localized: "Chưa có giao dịch định kỳ"),
                subtitle: String(localized: "Thêm giao dịch lặp lại như tiền nhà, lương, hóa đơn hàng tháng"),
                actionLabel: String(localized: "Thêm định kỳ"),
                onAction: { showAddSheet = true }
            )
            .padding(.horizontal, Spacing.lg)
            .padding(.top, 40)
        }
    }

    var listContent: some View {
        List {
            activeSection
            inactiveSection
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Sections

private extension RecurringTransactionView {
    @ViewBuilder
    var activeSection: some View {
        if !activeItems.isEmpty {
            Section {
                ForEach(activeItems) { item in
                    recurringRow(item)
                        .m3SectionRow()
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                recurringToDelete = item
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button { recurringToEdit = item } label: {
                                Image(systemName: "pencil")
                            }
                            .tint(Color.appSecondary)
                        }
                }
            } header: {
                Text(String(localized: "Đang hoạt động"))
                    .font(Typography.titleSmall)
                    .foregroundStyle(Color.onSurfaceVariant)
                    .textCase(nil)
            }
        }
    }

    @ViewBuilder
    var inactiveSection: some View {
        if !inactiveItems.isEmpty {
            Section {
                ForEach(inactiveItems) { item in
                    recurringRow(item)
                        .m3SectionRow()
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                recurringToDelete = item
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button { recurringToEdit = item } label: {
                                Image(systemName: "pencil")
                            }
                            .tint(Color.appSecondary)
                        }
                }
            } header: {
                Text(String(localized: "Đã tắt"))
                    .font(Typography.titleSmall)
                    .foregroundStyle(Color.onSurfaceVariant)
                    .textCase(nil)
            }
        }
    }
}

// MARK: - Row

private extension RecurringTransactionView {
    private func recurringRow(_ item: RecurringTransaction) -> some View {
        Button { recurringToEdit = item } label: {
            HStack(spacing: Spacing.md) {
                M3IconBadge(
                    icon: item.category?.icon ?? "questionmark.circle.fill",
                    color: Color(hex: item.category?.colorHex ?? Category.defaultColorHex),
                    size: 36
                )
                itemDetails(item)
                Spacer(minLength: Spacing.xs)
                amountAndToggle(item)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(itemTitle(item)), \(item.frequency.displayName), \(item.formattedAmount)"
        )
    }

    private func itemDetails(_ item: RecurringTransaction) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(itemTitle(item))
                .font(Typography.bodyLarge)
                .foregroundStyle(Color.onSurface)
                .lineLimit(1)
            HStack(spacing: Spacing.xs) {
                Image(systemName: item.frequency.icon)
                    .font(Typography.labelSmall)
                Text(item.frequency.displayName)
                    .font(Typography.bodySmall)
            }
            .foregroundStyle(Color.onSurfaceVariant)
        }
    }

    private func itemTitle(_ item: RecurringTransaction) -> String {
        item.note.isEmpty
            ? (item.category?.localizedName ?? String(localized: "Không rõ"))
            : item.note
    }

    private func amountAndToggle(_ item: RecurringTransaction) -> some View {
        VStack(alignment: .trailing, spacing: Spacing.xs) {
            Text(item.formattedAmount)
                .font(Typography.titleSmall)
                .foregroundStyle(
                    item.type == .income ? Color.appIncome : Color.appError
                )
            Toggle(String(localized: "Kích hoạt"), isOn: Binding(
                get: { item.isActive },
                set: { newValue in
                    item.isActive = newValue
                    try? context.save()
                }
            ))
            .labelsHidden()
            .scaleEffect(0.8)
            .accessibilityLabel(String(localized: "Kích hoạt giao dịch định kỳ"))
        }
    }
}

// MARK: - Actions & Dialogs

private extension RecurringTransactionView {
    var deleteDialogBinding: Binding<Bool> {
        Binding(
            get: { recurringToDelete != nil },
            set: { if !$0 { recurringToDelete = nil } }
        )
    }

    var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    @ViewBuilder
    var deleteDialogButtons: some View {
        Button(String(localized: "Xoá"), role: .destructive) {
            if let recurring = recurringToDelete {
                deleteRecurring(recurring)
            }
            recurringToDelete = nil
        }
        Button(String(localized: "Huỷ"), role: .cancel) {
            recurringToDelete = nil
        }
    }

    private func deleteRecurring(_ recurring: RecurringTransaction) {
        do {
            context.delete(recurring)
            try context.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @ToolbarContentBuilder
    var addToolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button { showAddSheet = true } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel(String(localized: "Thêm giao dịch định kỳ"))
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RecurringTransactionView()
    }
    .modelContainer(
        for: [RecurringTransaction.self, Category.self, Transaction.self],
        inMemory: true
    )
}
