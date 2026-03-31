import SwiftUI
import Charts

internal struct MonthlyTrendChart: View {
    internal let data: [MonthlyTrendItem]
    internal let dailyData: [DailyTrendItem]
    internal let isWeekPeriod: Bool
    internal let formatVND: (Decimal) -> String

    @State private var selectedItem: MonthlyTrendItem?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    internal var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader
            if isWeekPeriod {
                dailyChartSection
            } else if hasMonthlyData {
                monthlyChartSection
                currentMonthSummary
            } else {
                chartEmptyState
            }
        }
        .padding(Spacing.lg)
        .m3Card(cornerRadius: Spacing.cornerLarge)
    }

    // MARK: - Header

    private var sectionHeader: some View {
        Label(
            isWeekPeriod ? String(localized: "Chi tiêu theo ngày") : String(localized: "Xu hướng chi tiêu"),
            systemImage: "chart.line.uptrend.xyaxis.circle.fill"
        )
        .font(Typography.titleSmall)
        .foregroundStyle(Color.onSurface)
    }

    // MARK: - Daily Bar Chart (Week)

    private var dailyChartSection: some View {
        Group {
            if hasDailyData {
                dailyBarChart
                todaySummary
            } else {
                chartEmptyState
            }
        }
    }

    private var dailyBarChart: some View {
        Chart(dailyData) { item in
            BarMark(
                x: .value(String(localized: "Ngày"), item.dayLabel),
                y: .value(String(localized: "Số tiền"), doubleValue(item.amount))
            )
            .foregroundStyle(item.isToday ? Color.appPrimary.gradient : Color.appPrimary.opacity(0.5).gradient)
            .cornerRadius(Spacing.cornerExtraSmall)
            .annotation(position: .top, spacing: Spacing.xs) {
                if item.isToday, item.amount > 0 {
                    amountAnnotation(item.amount)
                }
            }
        }
        .chartYAxis { yAxisContent }
        .chartXAxis { xAxisContent }
        .frame(height: 220)
        .animation(reduceMotion ? .none : Motion.spatialDefault, value: dailyData.count)
        .accessibilityLabel(String(localized: "Biểu đồ chi tiêu theo ngày"))
    }

    private var todaySummary: some View {
        Group {
            if let today = dailyData.first(where: { $0.isToday }) {
                HStack {
                    Text(String(localized: "Hôm nay:"))
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Color.onSurfaceVariant)
                    Spacer()
                    Text(formatVND(today.amount))
                        .font(Typography.titleSmall)
                        .monospacedDigit()
                        .foregroundStyle(Color.appSecondary)
                        .contentTransition(.numericText())
                }
            }
        }
    }

    // MARK: - Monthly Chart

    private var monthlyChartSection: some View {
        Chart(data) { item in
            AreaMark(x: .value(String(localized: "Tháng"), item.monthLabel), y: .value(String(localized: "Số tiền"), doubleValue(item.amount)))
                .foregroundStyle(areaGradient)
                .interpolationMethod(.catmullRom)
            LineMark(x: .value(String(localized: "Tháng"), item.monthLabel), y: .value(String(localized: "Số tiền"), doubleValue(item.amount)))
                .foregroundStyle(Color.appPrimary)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
            pointMarkForItem(item)
        }
        .chartYAxis { yAxisContent }
        .chartXAxis { xAxisContent }
        .chartOverlay { proxy in chartOverlayGesture(proxy: proxy) }
        .frame(height: 220)
        .animation(reduceMotion ? .none : Motion.spatialDefault, value: data.count)
        .accessibilityLabel(String(localized: "Biểu đồ xu hướng chi tiêu hàng tháng"))
        .accessibilityValue(trendChartSummary)
    }

    @ChartContentBuilder
    private func pointMarkForItem(_ item: MonthlyTrendItem) -> some ChartContent {
        let isHighlighted = item.isCurrentMonth || selectedItem?.id == item.id
        if isHighlighted, item.amount > 0 {
            PointMark(x: .value(String(localized: "Tháng"), item.monthLabel), y: .value(String(localized: "Số tiền"), doubleValue(item.amount)))
                .foregroundStyle(Color.appPrimary)
                .symbolSize(60)
                .annotation(position: .top, spacing: Spacing.xs) { amountAnnotation(item.amount) }
        }
    }

    // MARK: - Shared Axis

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
        AxisMarks { _ in
            AxisValueLabel()
                .font(Typography.labelSmall)
                .foregroundStyle(Color.onSurfaceVariant)
        }
    }

    // MARK: - Touch Overlay

    private func chartOverlayGesture(proxy: ChartProxy) -> some View {
        GeometryReader { geo in
            Rectangle().fill(.clear).contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { handleDrag($0, proxy: proxy, geo: geo) }
                        .onEnded { _ in selectedItem = nil }
                )
        }
    }

    private func handleDrag(_ value: DragGesture.Value, proxy: ChartProxy, geo: GeometryProxy) {
        guard let plotFrame = proxy.plotFrame else { return }
        let origin = geo[plotFrame].origin
        let location = CGPoint(x: value.location.x - origin.x, y: value.location.y - origin.y)
        if let label: String = proxy.value(atX: location.x) {
            selectedItem = data.first { $0.monthLabel == label }
        }
    }

    // MARK: - Annotation

    private func amountAnnotation(_ amount: Decimal) -> some View {
        Text(formatVND(amount))
            .font(Typography.labelSmall)
            .monospacedDigit()
            .fontWeight(.bold)
            .foregroundStyle(Color.appSecondary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(Color.primaryContainer.opacity(0.4), in: RoundedRectangle(cornerRadius: Spacing.cornerExtraSmall))
    }

    // MARK: - Summary

    private var currentMonthSummary: some View {
        Group {
            if let current = data.first(where: { $0.isCurrentMonth }) {
                HStack {
                    Text(String(localized: "Tháng này:"))
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Color.onSurfaceVariant)
                    Spacer()
                    Text(formatVND(current.amount))
                        .font(Typography.titleSmall)
                        .monospacedDigit()
                        .foregroundStyle(Color.appSecondary)
                        .contentTransition(.numericText())
                }
            }
        }
    }

    // MARK: - Empty

    private var chartEmptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                .font(Typography.displayLarge)
                .foregroundStyle(Color.outlineVariant)
            Text(String(localized: "Chưa có dữ liệu xu hướng"))
                .font(Typography.bodyMedium)
                .foregroundStyle(Color.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    // MARK: - Helpers

    private var hasMonthlyData: Bool { data.contains { $0.amount > 0 } }
    private var hasDailyData: Bool { dailyData.contains { $0.amount > 0 } }

    private var areaGradient: LinearGradient {
        LinearGradient(
            colors: [Color.appPrimary.opacity(0.3), Color.appPrimary.opacity(0.05)],
            startPoint: .top, endPoint: .bottom
        )
    }

    private var trendChartSummary: String {
        guard let current = data.first(where: { $0.isCurrentMonth }) else {
            return String(localized: "Không có dữ liệu")
        }
        return String(localized: "Tháng này: \(formatVND(current.amount))")
    }

    private func doubleValue(_ decimal: Decimal) -> Double {
        NSDecimalNumber(decimal: decimal).doubleValue
    }
}
