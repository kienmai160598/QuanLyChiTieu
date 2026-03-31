import SwiftUI

// MARK: - Progress Status

internal enum ProgressStatus: Sendable {
    case onTrack
    case behind
    case atRisk
    case noData

    internal var color: Color {
        switch self {
        case .onTrack: .appIncome
        case .behind: .appWarning
        case .atRisk: .appError
        case .noData: .onSurfaceVariant
        }
    }

    internal var icon: String {
        switch self {
        case .onTrack: "checkmark.circle.fill"
        case .behind: "exclamationmark.circle.fill"
        case .atRisk: "xmark.circle.fill"
        case .noData: "questionmark.circle.fill"
        }
    }

    internal var label: String {
        switch self {
        case .onTrack: String(localized: "Đúng tiến độ")
        case .behind: String(localized: "Chậm tiến độ")
        case .atRisk: String(localized: "Có nguy cơ trễ hạn")
        case .noData: String(localized: "Chưa có dữ liệu")
        }
    }
}

// MARK: - Projected Completion Card

/// Displays savings projection metrics including estimated completion date,
/// required deposits, and progress status.
internal struct ProjectedCompletionCard: View {
    internal let goal: SavingsGoal

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    internal var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader
            statusIndicator
            statsGrid
        }
        .padding(Spacing.lg)
        .m3Card()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "Dự báo tiến độ"))
        .accessibilityValue(accessibilityText)
    }

    // MARK: - Header

    private var sectionHeader: some View {
        Label(String(localized: "Dự báo tiến độ"), systemImage: "chart.line.uptrend.xyaxis")
            .font(Typography.titleSmall)
            .foregroundStyle(Color.onSurface)
    }

    // MARK: - Status Indicator

    private var statusIndicator: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: progressStatus.icon)
                .font(Typography.bodyMedium)
                .foregroundStyle(progressStatus.color)

            Text(progressStatus.label)
                .font(Typography.labelMedium)
                .foregroundStyle(progressStatus.color)

            Spacer()
        }
        .padding(.vertical, Spacing.xs)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: Spacing.md),
                GridItem(.flexible(), spacing: Spacing.md)
            ],
            spacing: Spacing.md
        ) {
            statCell(
                label: String(localized: "Dự kiến hoàn thành"),
                value: projectedDateText
            )
            statCell(
                label: String(localized: "Tiết kiệm TB/tháng"),
                value: averageMonthlyText
            )
            if goal.deadline != nil {
                statCell(
                    label: String(localized: "Cần/ngày"),
                    value: dailyNeededText
                )
                statCell(
                    label: String(localized: "Cần/tháng"),
                    value: monthlyNeededText
                )
            }
        }
    }

    private func statCell(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(label)
                .font(Typography.labelSmall)
                .foregroundStyle(Color.onSurfaceVariant)
                .lineLimit(1)
            Text(value)
                .font(Typography.bodyMediumEmphasized)
                .monospacedDigit()
                .foregroundStyle(Color.onSurface)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.sm)
        .background(Color.onSurface.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerMedium))
    }

    // MARK: - Computed Properties

    private var progressStatus: ProgressStatus {
        guard !goal.isCompleted else { return .onTrack }

        // No deposit history to calculate projections
        guard goal.averageMonthlyDeposit > 0 else { return .noData }

        // No deadline - just check if making progress
        guard let deadline = goal.deadline else {
            return goal.averageMonthlyDeposit > 0 ? .onTrack : .noData
        }

        // Has deadline - compare projected vs deadline
        guard let projected = goal.projectedCompletionDate else { return .noData }

        let calendar = Calendar.current
        let daysToDeadline = calendar.dateComponents([.day], from: .now, to: deadline).day ?? 0
        let daysToProjected = calendar.dateComponents([.day], from: .now, to: projected).day ?? 0

        if daysToProjected <= daysToDeadline {
            return .onTrack
        } else if daysToProjected <= Int(Double(daysToDeadline) * 1.2) {
            return .behind
        } else {
            return .atRisk
        }
    }

    private var projectedDateText: String {
        guard !goal.isCompleted else {
            return String(localized: "Hoàn thành")
        }

        guard let date = goal.projectedCompletionDate else {
            return String(localized: "Không thể dự đoán")
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.string(from: date)
    }

    private var averageMonthlyText: String {
        let amount = goal.averageMonthlyDeposit
        guard amount > 0 else {
            return String(localized: "Chưa có")
        }
        return amount.formattedVND
    }

    private var dailyNeededText: String {
        guard let amount = goal.dailyDepositNeeded else {
            return String(localized: "—")
        }
        return amount.formattedVND
    }

    private var monthlyNeededText: String {
        guard let amount = goal.monthlyDepositNeeded else {
            return String(localized: "—")
        }
        return amount.formattedVND
    }

    private var accessibilityText: String {
        var text = progressStatus.label

        if let projected = goal.projectedCompletionDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = .none
            formatter.locale = Locale(identifier: "vi_VN")
            text += String(localized: ", dự kiến hoàn thành \(formatter.string(from: projected))")
        }

        if goal.averageMonthlyDeposit > 0 {
            text += String(localized: ", tiết kiệm trung bình \(goal.averageMonthlyDeposit.formattedVND) mỗi tháng")
        }

        return text
    }
}
