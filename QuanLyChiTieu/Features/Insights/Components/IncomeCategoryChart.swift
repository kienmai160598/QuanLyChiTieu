import SwiftUI
import Charts

internal struct IncomeCategoryChart: View {
    internal let data: [CategoryBreakdownItem]
    internal let formatVND: (Decimal) -> String

    @State private var selectedCategory: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    internal var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader
            if data.isEmpty {
                chartEmptyState
            } else {
                chartWithLegend
            }
        }
        .padding(Spacing.lg)
        .m3Card(cornerRadius: Spacing.cornerLarge)
    }

    // MARK: - Header

    private var sectionHeader: some View {
        Label(String(localized: "Thu nhập theo danh mục"), systemImage: "chart.pie.fill")
            .font(Typography.titleSmall)
            .foregroundStyle(Color.onSurface)
    }

    // MARK: - Chart + Legend

    private var chartWithLegend: some View {
        VStack(spacing: Spacing.lg) {
            donutChart
            legendList
        }
    }

    private var donutChart: some View {
        Chart(data) { item in
            SectorMark(
                angle: .value("Số tiền", doubleValue(item.amount)),
                innerRadius: .ratio(0.6),
                angularInset: 1.5
            )
            .foregroundStyle(Color(hex: item.colorHex))
            .opacity(sectorOpacity(for: item))
            .annotation(position: .overlay) {
                if isSelected(item) { selectedAnnotation(item) }
            }
        }
        .chartAngleSelection(value: $selectedCategory)
        .frame(height: 200)
        .animation(reduceMotion ? .none : Motion.effectDefault, value: selectedCategory)
        .accessibilityLabel(String(localized: "Biểu đồ thu nhập theo danh mục"))
        .accessibilityValue(chartSummary)
    }

    private func selectedAnnotation(_ item: CategoryBreakdownItem) -> some View {
        VStack(spacing: 2) {
            Text(percentageText(item.percentage))
                .font(Typography.labelSmall)
                .fontWeight(.bold)
            Text(formatVND(item.amount))
                .font(Typography.labelSmall)
                .monospacedDigit()
        }
        .foregroundStyle(Color.onPrimary)
    }

    // MARK: - Legend

    private var legendList: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(data) { item in legendRow(item) }
        }
    }

    private func legendRow(_ item: CategoryBreakdownItem) -> some View {
        HStack(spacing: Spacing.sm) {
            legendIcon(item)
            Text(item.categoryName)
                .font(Typography.bodyMedium)
                .foregroundStyle(Color.onSurface)
            Spacer()
            legendValues(item)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.categoryName)")
        .accessibilityValue("\(percentageText(item.percentage)), \(formatVND(item.amount))")
        .accessibilityAddTraits(.isButton)
        .onTapGesture { toggleSelection(item) }
    }

    private func legendIcon(_ item: CategoryBreakdownItem) -> some View {
        HStack(spacing: Spacing.sm) {
            Circle().fill(Color(hex: item.colorHex)).frame(width: 10, height: 10)
            Image(systemName: item.icon)
                .font(Typography.labelMedium)
                .foregroundStyle(Color(hex: item.colorHex))
                .frame(width: 20)
        }
    }

    private func legendValues(_ item: CategoryBreakdownItem) -> some View {
        HStack(spacing: Spacing.sm) {
            Text(percentageText(item.percentage))
                .font(Typography.labelSmall)
                .foregroundStyle(Color.onSurfaceVariant)
            Text(formatVND(item.amount))
                .font(Typography.labelMedium)
                .monospacedDigit()
                .foregroundStyle(Color.onSurface)
                .frame(minWidth: 80, alignment: .trailing)
        }
    }

    // MARK: - Empty

    private var chartEmptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "chart.pie.fill")
                .font(Typography.displayLarge)
                .foregroundStyle(Color.outlineVariant)
            Text(String(localized: "Chưa có dữ liệu thu nhập"))
                .font(Typography.bodyMedium)
                .foregroundStyle(Color.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
    }

    // MARK: - Helpers

    private func sectorOpacity(for item: CategoryBreakdownItem) -> Double {
        guard let selected = selectedCategory else { return 1.0 }
        return item.id == selected ? 1.0 : 0.5
    }

    private func isSelected(_ item: CategoryBreakdownItem) -> Bool {
        selectedCategory == item.id
    }

    private func toggleSelection(_ item: CategoryBreakdownItem) {
        if reduceMotion {
            selectedCategory = selectedCategory == item.id ? nil : item.id
        } else {
            withAnimation(Motion.effectDefault) {
                selectedCategory = selectedCategory == item.id ? nil : item.id
            }
        }
    }

    private func percentageText(_ value: Double) -> String {
        String(format: "%.1f%%", value)
    }

    private func doubleValue(_ decimal: Decimal) -> Double {
        NSDecimalNumber(decimal: decimal).doubleValue
    }

    private var chartSummary: String {
        data.prefix(3)
            .map { "\($0.categoryName) \(percentageText($0.percentage))" }
            .joined(separator: ", ")
    }
}
