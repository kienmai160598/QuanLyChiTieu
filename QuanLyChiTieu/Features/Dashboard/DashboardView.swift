import SwiftUI
import SwiftData
import Charts

// MARK: - Dashboard View

internal struct DashboardView: View {
    @ScaledMetric(relativeTo: .body) private var sectionGap: CGFloat = Spacing.xl
    @ScaledMetric(relativeTo: .body) private var contentMargin: CGFloat = Spacing.contentMargin
    @Query(sort: \Transaction.date, order: .reverse)
    private var allTransactions: [Transaction]

    @Query
    private var allBudgets: [Budget]

    @Query(filter: #Predicate<RecurringTransaction> { $0.isActive == true })
    private var activeRecurring: [RecurringTransaction]

    @Binding internal var showAddTransaction: Bool
    internal var zoomNamespace: Namespace.ID
    @State private var viewModel = DashboardViewModel()
    @State private var dataVersion = 0

    private var hasData: Bool {
        viewModel.totalIncome > 0 || viewModel.totalExpense > 0
    }

    internal var body: some View {
        Group {
            if hasData { scrollContent } else { emptyContent }
        }
        .navigationTitle(String(localized: "Tổng quan"))
        .toolbar { settingsToolbar }
        .background(Color.appSurface.ignoresSafeArea())
        .onChange(of: allTransactions) { dataVersion += 1 }
        .onChange(of: allBudgets) { dataVersion += 1 }
        .onChange(of: activeRecurring) { dataVersion += 1 }
        .onChange(of: viewModel.selectedMonth) { dataVersion += 1 }
        .onChange(of: viewModel.chartPeriod) { dataVersion += 1 }
        .task(id: dataVersion) { reloadData() }
    }

    private func reloadData() {
        viewModel.loadData(
            transactions: allTransactions,
            budgets: allBudgets,
            recurring: activeRecurring
        )
    }
}

// MARK: - Scroll Content

private extension DashboardView {
    var scrollContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: sectionGap) {
                balanceHero
                    .sectionEntrance()
                safeDailyBadge
                    .staggeredEntrance(index: 0)
                recentSection
                    .staggeredEntrance(index: 1)
            }
            .scenePadding(.horizontal)
            .padding(.top, Spacing.sm)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Month Selector

private extension DashboardView {
    var monthSelector: some View {
        HStack {
            Button { viewModel.goToPreviousMonth() } label: {
                M3IconButton(icon: "chevron.left", style: .filled, size: 36)
            }
            Spacer()
            Text(viewModel.currentMonthYearName)
                .font(Typography.titleMediumEmphasized)
                .foregroundStyle(Color.onSurface)
                .contentTransition(.numericText())
            Spacer()
            Button { viewModel.goToNextMonth() } label: {
                M3IconButton(icon: "chevron.right", style: .filled, size: 36)
            }
            .disabled(!viewModel.canGoToNextMonth)
            .opacity(viewModel.canGoToNextMonth ? 1 : 0.4)
        }
    }
}

// MARK: - Stacked Bar Chart

private extension DashboardView {
    var balanceHero: some View {
        VStack(spacing: Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(String(localized: "Số dư hiện tại"))
                        .font(.caption)
                        .foregroundStyle(Color.onSurfaceVariant)
                    Text(viewModel.formattedBalance)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.onSurface)
                        .contentTransition(.numericText())
                }
                Spacer()
                periodPicker
            }
            stackedBarChart
            chartLegend
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .m3Card(cornerRadius: Spacing.cornerHero, background: .surfaceContainerLowest)
    }

    private var periodPicker: some View {
        Menu {
            ForEach(ChartPeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.snappy) { viewModel.chartPeriod = period }
                } label: {
                    Label(
                        period.localizedName,
                        systemImage: viewModel.chartPeriod == period ? "checkmark" : ""
                    )
                }
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Text(viewModel.chartPeriod.localizedName)
                    .font(.subheadline.weight(.medium))
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .glassEffect(.regular.interactive(), in: .capsule)
        }
    }

    private var stackedBarChart: some View {
        let bars = viewModel.chartBars
        let visibleCount = min(bars.count, 5)
        return Chart(bars) { bar in
            BarMark(
                x: .value(String(localized: "Thời gian"), bar.label),
                y: .value(String(localized: "Số tiền"), bar.income)
            )
            .foregroundStyle(Color.appIncome)
            .cornerRadius(Spacing.cornerExtraSmall)
            BarMark(
                x: .value(String(localized: "Thời gian"), bar.label),
                y: .value(String(localized: "Số tiền"), bar.expense)
            )
            .foregroundStyle(Color.appError)
            .cornerRadius(Spacing.cornerExtraSmall)
        }
        .chartScrollableAxes(bars.count > 5 ? .horizontal : [])
        .chartXVisibleDomain(length: visibleCount)
        .chartScrollPosition(initialX: bars.last?.label ?? "")
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(.caption2)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.outlineVariant.opacity(0.5))
                AxisValueLabel()
                    .font(.caption2)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
        }
        .frame(height: 180)
    }

    private var chartLegend: some View {
        HStack(spacing: Spacing.sm) {
            metricPill(
                label: String(localized: "Thu nhập"),
                value: viewModel.formattedIncome,
                color: Color.appIncome
            )
            metricPill(
                label: String(localized: "Chi tiêu"),
                value: viewModel.formattedExpense,
                color: Color.appError
            )
        }
    }

    private func metricPill(label: String, value: String, color: Color) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.onSurfaceVariant)
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: Spacing.cornerMedium, style: .continuous))
    }
}

// MARK: - Safe Daily Badge

private extension DashboardView {
    private var safeDailyIcon: String {
        let amount = viewModel.safeDailyAmount
        if amount <= 0 {
            return "exclamationmark.circle.fill"
        } else if amount < 100_000 {
            return "exclamationmark.triangle.fill"
        } else {
            return "checkmark.circle.fill"
        }
    }

    private var safeDailyColor: Color {
        let amount = viewModel.safeDailyAmount
        if amount <= 0 {
            return Color.appError
        } else if amount < 100_000 {
            return Color.appWarning
        } else {
            return Color.appIncome
        }
    }

    var safeDailyBadge: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: safeDailyIcon)
                .font(.system(size: 24))
                .foregroundStyle(safeDailyColor)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(String(localized: "Mức chi an toàn hôm nay"))
                    .font(Typography.bodySmall)
                    .foregroundStyle(Color.onSurfaceVariant)
                Text(viewModel.formattedSafeDailyAmount)
                    .font(Typography.titleMediumEmphasized)
                    .foregroundStyle(safeDailyColor)
                    .contentTransition(.numericText())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .m3Card(cornerRadius: Spacing.cornerHero, background: .surfaceContainerLowest)
    }
}

// MARK: - Recent Transactions

private extension DashboardView {
    var recentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text(String(localized: "Giao dịch"))
                    .font(Typography.titleSmallEmphasized)
                    .foregroundStyle(Color.onSurface)
                Spacer()
                NavigationLink(value: DashboardRoute.allTransactions) {
                    Text(String(localized: "Xem tất cả"))
                        .font(.subheadline)
                        .foregroundStyle(.tint)
                }
            }
            if viewModel.recentTransactions.isEmpty {
                emptyTransactionsHint
            } else {
                TransactionGroupView(
                    transactions: Array(viewModel.recentTransactions.prefix(5)),
                    zoomNamespace: zoomNamespace
                )
            }
        }
    }

    @ToolbarContentBuilder
    private var settingsToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            NavigationLink(value: DashboardRoute.settings) {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel(String(localized: "Cài đặt"))
        }
    }

    var emptyTransactionsHint: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "tray")
                .font(Typography.bodyLarge)
                .foregroundStyle(Color.onSurfaceVariant)
            Text(String(localized: "Chưa có giao dịch nào"))
                .font(Typography.bodyMedium)
                .foregroundStyle(Color.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .m3Card(cornerRadius: Spacing.cornerHero, background: .surfaceContainerHigh)
    }
}

// MARK: - Empty State

private extension DashboardView {
    var emptyContent: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: "chart.pie")
                .font(.system(size: 72))
                .foregroundStyle(Color.appPrimary.opacity(0.4))

            VStack(spacing: Spacing.sm) {
                Text(String(localized: "Chào mừng!"))
                    .font(Typography.headlineSmallEmphasized)
                    .foregroundStyle(Color.onSurface)
                Text(String(localized: "Bắt đầu theo dõi chi tiêu bằng cách thêm giao dịch đầu tiên"))
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Color.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            Button {
                showAddTransaction = true
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "plus")
                    Text(String(localized: "Thêm giao dịch"))
                }
                .font(Typography.labelLargeEmphasized)
                .foregroundStyle(Color.onPrimary)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(Color.appPrimary, in: Capsule())
            }
            .buttonStyle(ExpressivePressStyle())
            .padding(.horizontal, Spacing.xl)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

private struct DashboardPreview: View {
    @Namespace private var ns
    var body: some View {
        NavigationStack {
            DashboardView(showAddTransaction: .constant(false), zoomNamespace: ns)
        }
    }
}

#Preview {
    DashboardPreview()
        .modelContainer(
            for: [Transaction.self, Category.self, Budget.self, RecurringTransaction.self, SavingsGoal.self],
            inMemory: true
        )
}
