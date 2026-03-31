import SwiftUI

// MARK: - TransactionDateRangeFilter

/// Date range filter with an expandable picker and a summary chip.
/// When active, displays a chip showing the selected range with a clear button.
internal struct TransactionDateRangeFilter: View {
    @Binding internal var startDate: Date?
    @Binding internal var endDate: Date?

    @State private var isExpanded = false
    @State private var tempStart: Date = Calendar.current.startOfDay(for: .now)
    @State private var tempEnd: Date = .now

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    internal var body: some View {
        VStack(spacing: Spacing.sm) {
            headerRow
            if isExpanded {
                datePickerSection
            }
        }
        .padding(.horizontal, Spacing.lg)
        .animation(
            reduceMotion ? .none : Motion.effectDefault,
            value: isExpanded
        )
    }
}

// MARK: - Header Row

private extension TransactionDateRangeFilter {
    private var headerRow: some View {
        HStack(spacing: Spacing.sm) {
            toggleButton
            if hasActiveFilter {
                activeRangeChip
                clearButton
            }
        }
    }

    private var toggleButton: some View {
        Button {
            triggerHaptic()
            isExpanded.toggle()
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "calendar")
                    .font(Typography.bodySmall)
                    .fontWeight(.medium)
                Text(String(localized: "Lọc theo ngày"))
                    .font(Typography.bodySmall)
                    .fontWeight(.medium)
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption2)
            }
            .foregroundStyle(hasActiveFilter ? Color.onPrimary : .primary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .background(
            hasActiveFilter ? Color.appPrimary : Color.surfaceContainerHigh,
            in: .capsule
        )
    }
}

// MARK: - Active Range Chip

private extension TransactionDateRangeFilter {
    private var activeRangeChip: some View {
        Text(dateRangeLabel)
            .font(Typography.labelMedium)
            .foregroundStyle(Color.onSurfaceVariant)
            .lineLimit(1)
    }

    private var clearButton: some View {
        Button {
            triggerHaptic()
            clearFilter()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(Typography.bodySmall)
                .foregroundStyle(Color.onSurfaceVariant)
        }
        .accessibilityLabel(
            String(localized: "Xoá bộ lọc ngày")
        )
    }
}

// MARK: - Date Pickers

private extension TransactionDateRangeFilter {
    private var datePickerSection: some View {
        VStack(spacing: Spacing.md) {
            datePickerRow(
                label: String(localized: "Từ ngày"),
                date: $tempStart,
                range: ...tempEnd
            )
            datePickerRow(
                label: String(localized: "Đến ngày"),
                date: $tempEnd,
                range: tempStart...
            )
            applyButton
        }
        .padding(Spacing.md)
    }

    private func datePickerRow(
        label: String,
        date: Binding<Date>,
        range: PartialRangeThrough<Date>
    ) -> some View {
        DatePicker(
            label,
            selection: date,
            in: range,
            displayedComponents: .date
        )
        .font(Typography.bodyMedium)
    }

    private func datePickerRow(
        label: String,
        date: Binding<Date>,
        range: PartialRangeFrom<Date>
    ) -> some View {
        DatePicker(
            label,
            selection: date,
            in: range,
            displayedComponents: .date
        )
        .font(Typography.bodyMedium)
    }

    private var applyButton: some View {
        Button {
            triggerHaptic()
            applyFilter()
        } label: {
            Text(String(localized: "Áp dụng"))
                .font(Typography.labelLarge)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(ExpressivePressStyle())
    }
}

// MARK: - Logic

private extension TransactionDateRangeFilter {
    private var hasActiveFilter: Bool {
        startDate != nil || endDate != nil
    }

    private var dateRangeLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "vi")

        let start = startDate.map { formatter.string(from: $0) } ?? "..."
        let end = endDate.map { formatter.string(from: $0) } ?? "..."
        return "\(start) – \(end)"
    }

    private func applyFilter() {
        startDate = Calendar.current.startOfDay(for: tempStart)
        let endOfDay = Calendar.current.date(
            bySettingHour: 23, minute: 59, second: 59,
            of: tempEnd
        ) ?? tempEnd
        endDate = endOfDay
        isExpanded = false
    }

    private func clearFilter() {
        startDate = nil
        endDate = nil
        tempStart = Calendar.current.startOfDay(for: .now)
        tempEnd = .now
        isExpanded = false
    }

    private func triggerHaptic() {
        HapticService.lightImpact()
    }
}
