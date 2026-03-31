import SwiftUI
import SwiftData

// MARK: - Budget Detail View

internal struct BudgetDetailView: View {
    internal let budget: Budget

    @Query(sort: \Transaction.date, order: .reverse)
    private var allTransactions: [Transaction]

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showEditSheet: Bool = false
    @State private var showDeleteConfirmation: Bool = false

    private var categoryTransactions: [Transaction] {
        let monthKey = budget.monthYear
        return allTransactions.filter { tx in
            tx.type == .expense
                && tx.category?.persistentModelID == budget.category?.persistentModelID
                && tx.date.monthYearKey == monthKey
        }
    }

    private var spent: Decimal {
        categoryTransactions.reduce(0) { $0 + $1.amount }
    }

    private var progress: Double {
        guard budget.limitAmount > 0 else { return 0 }
        return min(NSDecimalNumber(decimal: spent / budget.limitAmount).doubleValue, 1.0)
    }

    internal var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                progressSection
                transactionsList
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
        }
        .appBackground()
        .navigationTitle(budget.category?.localizedName ?? String(localized: "Ngân sách"))
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .toolbar { toolbarButtons }
        .sheet(isPresented: $showEditSheet) {
            AddBudgetSheet(existingBudgets: [], editingBudget: budget)
        }
        .confirmationDialog(
            String(localized: "Xoá ngân sách"),
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Xoá"), role: .destructive) {
                context.delete(budget)
                try? context.save()
                dismiss()
            }
            Button(String(localized: "Huỷ"), role: .cancel) {}
        } message: {
            Text(String(localized: "Bạn có chắc muốn xoá ngân sách này?"))
        }
    }

    @ToolbarContentBuilder
    private var toolbarButtons: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button { showEditSheet = true } label: {
                Image(systemName: "pencil")
            }
            .accessibilityLabel(String(localized: "Sửa ngân sách"))
        }
        ToolbarItem(placement: .destructiveAction) {
            Button(role: .destructive) { showDeleteConfirmation = true } label: {
                Image(systemName: "trash")
            }
            .accessibilityLabel(String(localized: "Xoá ngân sách"))
        }
    }
}

// MARK: - Progress Section

private extension BudgetDetailView {
    var progressSection: some View {
        VStack(spacing: Spacing.lg) {
            progressRing
            metricPills
        }
        .padding(Spacing.xl)
        .m3Card(cornerRadius: Spacing.cornerMedium + Spacing.xs)
    }

    var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.outlineVariant.opacity(0.3), lineWidth: 10)
                .frame(width: 120, height: 120)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(progressColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
            VStack(spacing: Spacing.xs) {
                Text("\(Int(progress * 100))%")
                    .font(Typography.headlineSmall)
                    .foregroundStyle(Color.onSurface)
                    .contentTransition(.numericText())
                Text(String(localized: "đã chi"))
                    .font(Typography.labelSmall)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
        }
        .accessibilityLabel(String(localized: "Đã chi \(Int(progress * 100)) phần trăm ngân sách"))
    }

    var metricPills: some View {
        HStack(spacing: Spacing.md) {
            BudgetMetricPill(icon: "arrow.up.right", label: String(localized: "Đã chi"), value: spent.compactVND, color: .appError)
            BudgetMetricPill(icon: "banknote.fill", label: String(localized: "Hạn mức"), value: budget.formattedLimit, color: .appPrimary)
        }
    }

    var progressColor: Color {
        switch progress {
        case 0.9...: return Color.appError
        case 0.7...: return Color.appWarning
        default: return Color.appPrimary
        }
    }
}

// MARK: - Transactions List

private extension BudgetDetailView {
    var transactionsList: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            transactionsHeader
            if categoryTransactions.isEmpty {
                emptyState
            } else {
                transactionRows
            }
        }
    }

    var transactionsHeader: some View {
        SectionHeader("Giao dịch") {
            if !categoryTransactions.isEmpty {
                Text(String(localized: "\(categoryTransactions.count) giao dịch"))
                    .font(Typography.labelSmall)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
        }
        .padding(.horizontal, Spacing.xs)
    }

    var emptyState: some View {
        EmptyStateCard(
            icon: "tray.fill",
            title: String(localized: "Chưa có giao dịch trong danh mục này")
        )
    }

    var transactionRows: some View {
        TransactionGroupView(transactions: categoryTransactions)
    }
}
