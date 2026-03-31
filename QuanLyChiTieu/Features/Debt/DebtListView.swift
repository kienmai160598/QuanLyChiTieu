import SwiftUI
import SwiftData

internal struct DebtListView: View {
    @Query(sort: \Debt.startDate, order: .reverse)
    private var allDebts: [Debt]

    @Environment(\.modelContext) private var context
    @State private var showAddSheet = false
    @State private var debtToDelete: Debt?
    @State private var showDeleteConfirmation = false
    @State private var deleteError: String?

    private var lentDebts: [Debt] {
        allDebts.filter { $0.isLent && !$0.isSettled }
    }

    private var borrowedDebts: [Debt] {
        allDebts.filter { !$0.isLent && !$0.isSettled }
    }

    private var settledDebts: [Debt] {
        allDebts.filter { $0.isSettled }
    }

    private var totalLent: Decimal {
        lentDebts.reduce(0) { $0 + $1.remainingAmount }
    }

    private var totalBorrowed: Decimal {
        borrowedDebts.reduce(0) { $0 + $1.remainingAmount }
    }

    internal var body: some View {
        Group {
            if allDebts.isEmpty {
                emptyContent
            } else {
                listContent
            }
        }
        .appBackground()
        .navigationTitle(String(localized: "Qu\u{1EA3}n l\u{00FD} n\u{1EE3}"))
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .toolbar { addButton }
        .sheet(isPresented: $showAddSheet) {
            AddDebtSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(Spacing.cornerExtraExtraLarge)
                .presentationBackground(Color.surfaceContainerLowest)
        }
        .confirmationDialog(
            String(localized: "Xo\u{00E1} kho\u{1EA3}n n\u{1EE3}"),
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Xo\u{00E1}"), role: .destructive) {
                if let debt = debtToDelete {
                    deleteDebt(debt)
                }
            }
            Button(String(localized: "Hu\u{1EF7}"), role: .cancel) {
                debtToDelete = nil
            }
        } message: {
            Text(String(localized: "B\u{1EA1}n c\u{00F3} ch\u{1EAF}c mu\u{1ED1}n xo\u{00E1} kho\u{1EA3}n n\u{1EE3} n\u{00E0}y?"))
        }
        .alert(String(localized: "L\u{1ED7}i"), isPresented: Binding(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button(String(localized: "OK")) {}
        } message: {
            Text(deleteError ?? "")
        }
    }

    @ToolbarContentBuilder
    private var addButton: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button { showAddSheet = true } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel(String(localized: "Th\u{00EA}m kho\u{1EA3}n n\u{1EE3}"))
        }
    }
}

// MARK: - Empty State

private extension DebtListView {
    private var emptyContent: some View {
        ScrollView {
            EmptyStateCard(
                icon: "banknote.fill",
                title: String(localized: "Ch\u{01B0}a c\u{00F3} kho\u{1EA3}n n\u{1EE3}"),
                actionLabel: String(localized: "Th\u{00EA}m kho\u{1EA3}n n\u{1EE3}"),
                onAction: { showAddSheet = true }
            )
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.xxxl)
        }
    }
}

// MARK: - List Content

private extension DebtListView {
    private var listContent: some View {
        List {
            totalsSection
            if !lentDebts.isEmpty {
                lentSection
            }
            if !borrowedDebts.isEmpty {
                borrowedSection
            }
            if !settledDebts.isEmpty {
                settledSection
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Totals Section

private extension DebtListView {
    private var totalsSection: some View {
        Section {
            HStack(spacing: Spacing.md) {
                BudgetMetricPill(
                    icon: "arrow.up.right",
                    label: String(localized: "Cho vay"),
                    value: totalLent.formattedVND,
                    color: .appIncome
                )
                BudgetMetricPill(
                    icon: "arrow.down.left",
                    label: String(localized: "\u{0110}ang n\u{1EE3}"),
                    value: totalBorrowed.formattedVND,
                    color: .appError
                )
            }
        }
        .listRowInsets(EdgeInsets(
            top: Spacing.sm, leading: Spacing.lg,
            bottom: Spacing.sm, trailing: Spacing.lg
        ))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

// MARK: - Lent Section

private extension DebtListView {
    private var lentSection: some View {
        Section {
            debtRows(lentDebts)
        } header: {
            sectionHeader(
                String(localized: "Cho vay"),
                count: lentDebts.count
            )
        }
    }
}

// MARK: - Borrowed Section

private extension DebtListView {
    private var borrowedSection: some View {
        Section {
            debtRows(borrowedDebts)
        } header: {
            sectionHeader(
                String(localized: "\u{0110}ang n\u{1EE3}"),
                count: borrowedDebts.count
            )
        }
    }
}

// MARK: - Settled Section

private extension DebtListView {
    private var settledSection: some View {
        Section {
            debtRows(settledDebts)
        } header: {
            Text(String(localized: "\u{0110}\u{00E3} t\u{1EA5}t to\u{00E1}n"))
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurfaceVariant)
                .textCase(nil)
        }
    }
}

// MARK: - Shared Rows & Helpers

private extension DebtListView {
    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurfaceVariant)
            Spacer()
            Text(String(localized: "\(count) kho\u{1EA3}n"))
                .font(Typography.labelSmall)
                .foregroundStyle(Color.onSurfaceVariant)
        }
        .textCase(nil)
    }

    private func debtRows(_ debts: [Debt]) -> some View {
        ForEach(debts) { debt in
            NavigationLink(value: DebtRoute.detail(debt.persistentModelID)) {
                debtRow(debt)
            }
            .m3SectionRow()
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    debtToDelete = debt
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }

    private func debtRow(_ debt: Debt) -> some View {
        HStack(spacing: Spacing.md) {
            M3IconBadge(
                icon: debt.isLent ? "arrow.up.right" : "arrow.down.left",
                color: debt.isLent ? .appIncome : .appError
            )
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(debt.personName)
                    .font(Typography.bodyLarge)
                    .foregroundStyle(Color.onSurface)
                    .lineLimit(1)
                dueDateLabel(debt)
            }
            Spacer()
            Text(debt.formattedRemaining)
                .font(Typography.titleSmall)
                .foregroundStyle(debt.isLent ? Color.appIncome : Color.appError)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(debt.personName)
    }

    @ViewBuilder
    private func dueDateLabel(_ debt: Debt) -> some View {
        if debt.isOverdue {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(Typography.labelSmall)
                Text(String(localized: "Qu\u{00E1} h\u{1EA1}n"))
                    .font(Typography.labelSmall)
            }
            .foregroundStyle(Color.appError)
        } else if let dueDate = debt.dueDate {
            Text(dueDate.formatted(.dateTime.day().month(.abbreviated)))
                .font(Typography.bodySmall)
                .foregroundStyle(Color.onSurfaceVariant)
        }
    }
}

// MARK: - Actions

private extension DebtListView {
    private func deleteDebt(_ debt: Debt) {
        context.delete(debt)
        do {
            try context.save()
        } catch {
            deleteError = error.localizedDescription
        }
        debtToDelete = nil
    }
}

// MARK: - Preview

#Preview {
    NavigationStack { DebtListView() }
        .modelContainer(for: Debt.self, inMemory: true)
}
