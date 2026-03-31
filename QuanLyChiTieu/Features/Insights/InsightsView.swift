import SwiftUI
import SwiftData
import Charts

internal struct InsightsView: View {
    @Query(sort: \Transaction.date, order: .reverse)
    private var allTransactions: [Transaction]

    @Query private var budgets: [Budget]

    @State private var viewModel = InsightsViewModel()

    internal var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                periodChips
                if allTransactions.isEmpty {
                    emptyState
                } else {
                    chartsContent
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xl)
        }
        .navigationTitle(String(localized: "Phân tích"))
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .appBackground()
    }

    // MARK: - Period Chips

    private var periodChips: some View {
        GlassChipGroup(
            items: periodChipItems,
            selectedID: Binding(
                get: { viewModel.selectedPeriod.rawValue },
                set: { newID in
                    if let period = TimePeriod(rawValue: newID ?? TimePeriod.month.rawValue) {
                        viewModel.selectedPeriod = period
                    }
                }
            )
        )
        .padding(.horizontal, -Spacing.lg)
    }

    private var periodChipItems: [ChipItem] {
        TimePeriod.allCases.map { period in
            ChipItem(id: period.rawValue, label: period.displayName)
        }
    }

    private var chartsContent: some View {
        VStack(spacing: Spacing.xl) {
            VStack(spacing: Spacing.xl) {
                savingsRateCard
                categoryChart
                trendChart
                incomeExpenseChart
                incomeCategoryChart
            }
            budgetSection
        }
    }

    private var savingsRateCard: some View {
        SavingsRateCard(
            data: viewModel.savingsRateData(from: allTransactions),
            formatVND: viewModel.formatVND
        )
    }

    private var categoryChart: some View {
        SpendingByCategoryChart(
            data: viewModel.categoryBreakdown(from: allTransactions),
            formatVND: viewModel.formatVND
        )
    }

    private var trendChart: some View {
        MonthlyTrendChart(
            data: viewModel.monthlyTrend(from: allTransactions),
            dailyData: viewModel.dailyTrend(from: allTransactions),
            isWeekPeriod: viewModel.selectedPeriod == .week,
            formatVND: viewModel.formatVND
        )
    }

    private var incomeExpenseChart: some View {
        IncomeExpenseChart(
            data: viewModel.incomeVsExpense(from: allTransactions),
            formatVND: viewModel.formatVND
        )
    }

    private var incomeCategoryChart: some View {
        IncomeCategoryChart(
            data: viewModel.incomeCategoryBreakdown(from: allTransactions),
            formatVND: viewModel.formatVND
        )
    }

    private var budgetSection: some View {
        Group {
            if !budgets.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(String(localized: "Tiến độ ngân sách"))
                            .font(Typography.titleSmall)
                            .foregroundStyle(Color.onSurface)
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.lg)
                    budgetCards
                }
            }
        }
    }

    private var budgetCards: some View {
        ForEach(budgets) { budget in
            BudgetUtilizationCard(
                budget: budget,
                spent: viewModel.budgetSpent(
                    for: budget,
                    transactions: allTransactions
                ),
                formatVND: viewModel.formatVND
            )
        }
    }

    private var emptyState: some View {
        EmptyStateCard(
            icon: "chart.bar.xaxis",
            title: String(localized: "Chưa có dữ liệu"),
            subtitle: String(localized: "Hãy thêm giao dịch để xem báo cáo chi tiêu")
        )
        .padding(.top, 40)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        InsightsView()
    }
    .modelContainer(
        for: [Transaction.self, Category.self, Budget.self],
        inMemory: true
    )
}
