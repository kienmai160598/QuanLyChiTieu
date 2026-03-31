import SwiftUI
import Charts

internal struct IncomeExpenseChart: View {
    internal let data: [IncomeExpenseItem]
    internal let formatVND: (Decimal) -> String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    internal var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader
            if hasData {
                chartContent
                savingsSummary
            } else {
                chartEmptyState
            }
        }
        .padding(Spacing.lg)
        .m3Card(cornerRadius: Spacing.cornerLarge)
    }

    // MARK: - Header

    private var sectionHeader: some View {
        HStack {
            Label("Thu nhập & Chi tiêu", systemImage: "chart.bar.fill")
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurface)
            Spacer()
            legendIndicators
        }
    }

    private var legendIndicators: some View {
        HStack(spacing: Spacing.md) {
            legendDot(color: .appIncome, label: "Thu")
            legendDot(color: .appError, label: "Chi")
        }
    }

    private func legendDot(
        color: Color, label: LocalizedStringKey
    ) -> some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)
            Text(label)
                .font(Typography.labelSmall)
                .foregroundStyle(Color.onSurfaceVariant)
        }
    }

    // MARK: - Chart

    private var chartContent: some View {
        Chart(activeData) { item in
            incomeMark(for: item)
            expenseMark(for: item)
        }
        .chartYAxis { yAxisMarks }
        .chartXAxis { xAxisMarks }
        .frame(height: 220)
        .animation(reduceMotion ? .none : Motion.spatialDefault, value: activeData.count)
        .accessibilityLabel(String(localized: "Biểu đồ thu nhập và chi tiêu"))
        .accessibilityValue(incomeExpenseSummary)
    }

    private func incomeMark(for item: IncomeExpenseItem) -> some ChartContent {
        BarMark(
            x: .value(String(localized: "Tháng"), item.monthLabel),
            y: .value(String(localized: "Số tiền"), doubleValue(item.income))
        )
        .foregroundStyle(Color.appIncome.gradient)
        .position(by: .value(String(localized: "Loại"), String(localized: "Thu nhập")))
        .cornerRadius(Spacing.cornerExtraSmall)
    }

    private func expenseMark(for item: IncomeExpenseItem) -> some ChartContent {
        BarMark(
            x: .value(String(localized: "Tháng"), item.monthLabel),
            y: .value(String(localized: "Số tiền"), doubleValue(item.expense))
        )
        .foregroundStyle(Color.appError.gradient)
        .position(by: .value(String(localized: "Loại"), String(localized: "Chi tiêu")))
        .cornerRadius(Spacing.cornerExtraSmall)
    }

    private var yAxisMarks: some AxisContent {
        AxisMarks(position: .leading) { value in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                .foregroundStyle(Color.outlineVariant.opacity(0.5))
            AxisValueLabel {
                if let number = value.as(Double.self) {
                    Text(Decimal(number).formattedVND)
                        .font(Typography.labelSmall)
                        .foregroundStyle(Color.onSurfaceVariant)
                }
            }
        }
    }

    private var xAxisMarks: some AxisContent {
        AxisMarks { _ in
            AxisValueLabel()
                .font(Typography.labelSmall)
                .foregroundStyle(Color.onSurfaceVariant)
        }
    }

    // MARK: - Savings Summary

    private var savingsSummary: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(recentMonthsWithData) { item in
                savingsRow(item)
            }
        }
    }

    private func savingsRow(
        _ item: IncomeExpenseItem
    ) -> some View {
        HStack {
            Text(item.monthLabel)
                .font(Typography.bodySmall)
                .foregroundStyle(Color.onSurfaceVariant)
                .frame(width: 50, alignment: .leading)

            Spacer()

            let savings = item.netSavings
            let isPositive = savings >= 0
            Text(isPositive ? "+\(formatVND(savings))" : formatVND(savings))
                .font(Typography.labelMedium)
                .monospacedDigit()
                .foregroundStyle(isPositive ? Color.appIncome : Color.appError)
                .contentTransition(.numericText())
        }
    }

    // MARK: - Empty

    private var chartEmptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "chart.bar.fill")
                .font(Typography.displayLarge)
                .foregroundStyle(Color.outlineVariant)
            Text(String(localized: "Chưa có dữ liệu thu chi"))
                .font(Typography.bodyMedium)
                .foregroundStyle(Color.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    // MARK: - Helpers

    private var hasData: Bool {
        data.contains { $0.income > 0 || $0.expense > 0 }
    }

    private var activeData: [IncomeExpenseItem] {
        data.filter { $0.income > 0 || $0.expense > 0 }
    }

    private var recentMonthsWithData: [IncomeExpenseItem] {
        Array(activeData.suffix(3))
    }

    private var incomeExpenseSummary: String {
        let totalIncome = activeData.reduce(Decimal(0)) { $0 + $1.income }
        let totalExpense = activeData.reduce(Decimal(0)) { $0 + $1.expense }
        let incomeText = formatVND(totalIncome)
        let expenseText = formatVND(totalExpense)
        return String(localized: "Thu nhập: \(incomeText), Chi tiêu: \(expenseText)")
    }

    private func doubleValue(_ decimal: Decimal) -> Double {
        NSDecimalNumber(decimal: decimal).doubleValue
    }
}
