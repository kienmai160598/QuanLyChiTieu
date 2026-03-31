import SwiftUI
import Charts

// MARK: - Chart Data Point

internal struct SavingsBalancePoint: Identifiable, Sendable {
    internal let id = UUID()
    internal let date: Date
    internal let balance: Decimal

    internal var doubleBalance: Double {
        NSDecimalNumber(decimal: balance).doubleValue
    }
}

// MARK: - Savings History Chart

internal struct SavingsHistoryChart: View {
    internal let transactions: [SavingsTransaction]
    internal let goalColorHex: String?
    internal let initialBalance: Decimal
    internal var showHeader: Bool
    internal var showCard: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animationProgress: CGFloat = 0

    internal init(
        transactions: [SavingsTransaction],
        goalColorHex: String? = nil,
        initialBalance: Decimal = 0,
        showHeader: Bool = true,
        showCard: Bool = true
    ) {
        self.transactions = transactions
        self.goalColorHex = goalColorHex
        self.initialBalance = initialBalance
        self.showHeader = showHeader
        self.showCard = showCard
    }

    internal var body: some View {
        contentView
            .onAppear { animateChart() }
    }

    @ViewBuilder
    private var contentView: some View {
        let content = VStack(alignment: .leading, spacing: Spacing.md) {
            if showHeader {
                sectionHeader
            }
            if hasData {
                chartContent
            } else {
                emptyState
            }
        }

        if showCard {
            content
                .padding(Spacing.lg)
                .m3Card(cornerRadius: Spacing.cornerLarge)
        } else {
            content
        }
    }

    // MARK: - Header

    private var sectionHeader: some View {
        Label(
            String(localized: "Lịch sử số dư"),
            systemImage: "chart.xyaxis.line"
        )
        .font(Typography.titleSmall)
        .foregroundStyle(Color.onSurface)
    }

    // MARK: - Chart

    private var chartContent: some View {
        Chart(dataPoints) { point in
            AreaMark(
                x: .value(String(localized: "Ngày"), point.date),
                y: .value(String(localized: "Số dư"), point.doubleBalance * animationProgress)
            )
            .foregroundStyle(areaGradient)
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value(String(localized: "Ngày"), point.date),
                y: .value(String(localized: "Số dư"), point.doubleBalance * animationProgress)
            )
            .foregroundStyle(chartColor)
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 2.5))
        }
        .chartYAxis { yAxisContent }
        .chartXAxis { xAxisContent }
        .frame(height: 200)
        .accessibilityLabel(String(localized: "Biểu đồ lịch sử số dư tiết kiệm"))
        .accessibilityValue(chartAccessibilityValue)
    }

    private var yAxisContent: some AxisContent {
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

    private var xAxisContent: some AxisContent {
        AxisMarks(values: .automatic(desiredCount: 4)) { value in
            AxisValueLabel {
                if let date = value.as(Date.self) {
                    Text(formatAxisDate(date))
                        .font(Typography.labelSmall)
                        .foregroundStyle(Color.onSurfaceVariant)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "chart.xyaxis.line")
                .font(Typography.displayLarge)
                .foregroundStyle(Color.outlineVariant)
            Text(String(localized: "Chưa có lịch sử giao dịch"))
                .font(Typography.bodyMedium)
                .foregroundStyle(Color.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    // MARK: - Data Processing

    private var dataPoints: [SavingsBalancePoint] {
        let sortedTransactions = transactions.sorted { $0.date < $1.date }
        guard !sortedTransactions.isEmpty else { return [] }

        var points: [SavingsBalancePoint] = []
        var runningBalance = initialBalance

        // Add initial point if we have an initial balance
        if let firstTransaction = sortedTransactions.first {
            let startDate = Calendar.current.date(
                byAdding: .day,
                value: -1,
                to: firstTransaction.date
            ) ?? firstTransaction.date
            points.append(SavingsBalancePoint(date: startDate, balance: runningBalance))
        }

        // Build balance history from transactions
        for transaction in sortedTransactions {
            runningBalance += transaction.amount
            points.append(SavingsBalancePoint(date: transaction.date, balance: runningBalance))
        }

        return points
    }

    private var hasData: Bool {
        !transactions.isEmpty
    }

    // MARK: - Styling

    private var chartColor: Color {
        if let hex = goalColorHex {
            return Color(hex: hex)
        }
        return Color.appPrimary
    }

    private var areaGradient: LinearGradient {
        LinearGradient(
            colors: [chartColor.opacity(0.3), chartColor.opacity(0.05)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Animation

    private func animateChart() {
        guard !reduceMotion else {
            animationProgress = 1
            return
        }
        withAnimation(Motion.effectDefault) {
            animationProgress = 1
        }
    }

    // MARK: - Formatting

    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.string(from: date)
    }

    private var chartAccessibilityValue: String {
        guard let lastPoint = dataPoints.last else {
            return String(localized: "Không có dữ liệu")
        }
        return String(localized: "Số dư hiện tại: \(lastPoint.balance.formattedVND)")
    }
}

// MARK: - Preview

#if DEBUG
#Preview("With Data") {
    let mockTransactions = [
        SavingsTransaction(amount: 1_000_000, date: Date().addingTimeInterval(-86400 * 30)),
        SavingsTransaction(amount: 500_000, date: Date().addingTimeInterval(-86400 * 20)),
        SavingsTransaction(amount: -200_000, date: Date().addingTimeInterval(-86400 * 15)),
        SavingsTransaction(amount: 1_500_000, date: Date().addingTimeInterval(-86400 * 7)),
        SavingsTransaction(amount: 800_000, date: Date())
    ]
    return SavingsHistoryChart(
        transactions: mockTransactions,
        goalColorHex: "#C15F3C"
    )
    .padding()
}

#Preview("Empty State") {
    SavingsHistoryChart(transactions: [])
        .padding()
}
#endif
