import SwiftUI

// MARK: - Savings Goal Row

/// M3E: reusable card/row view for displaying a savings goal in lists.
/// Shows icon, name, progress bar, amounts, and deadline info.
internal struct SavingsGoalRow: View {
    internal let goal: SavingsGoal

    internal var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            cardHeader
            amountRow
            CapsuleProgressBar(
                progress: goal.progress,
                tint: SavingsGoalHelpers.progressColor(for: goal)
            )
            cardFooter
        }
        .padding(Spacing.lg)
        .m3Card()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(goal.name), \(goal.formattedCurrent) / \(goal.formattedTarget)")
        .accessibilityValue(String(localized: "\(Int(goal.progress * 100)) phần trăm"))
    }
}

// MARK: - Card Header

private extension SavingsGoalRow {
    private var cardHeader: some View {
        HStack(spacing: Spacing.md) {
            M3IconBadge(icon: goal.icon, color: Color(hex: goal.colorHex))
            Text(goal.name)
                .font(Typography.titleSmallEmphasized)
                .foregroundStyle(Color.onSurface)
                .lineLimit(1)
            Spacer()
            statusIcon
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        if goal.isCompleted {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.appIncome)
        } else if goal.isArchived {
            Image(systemName: "archivebox.fill")
                .foregroundStyle(Color.onSurfaceVariant)
        }
    }
}

// MARK: - Amount Row

private extension SavingsGoalRow {
    private var amountRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(goal.formattedCurrent)
                .font(Typography.headlineSmall)
                .monospacedDigit()
                .foregroundStyle(Color.onSurface)
            Text("/ \(goal.formattedTarget)")
                .font(Typography.bodySmall)
                .foregroundStyle(Color.onSurfaceVariant)
            Spacer()
            Text("\(Int(goal.progress * 100))%")
                .font(Typography.titleSmallEmphasized)
                .monospacedDigit()
                .foregroundStyle(SavingsGoalHelpers.progressColor(for: goal))
                .contentTransition(.numericText())
        }
    }
}

// MARK: - Card Footer

private extension SavingsGoalRow {
    private var cardFooter: some View {
        HStack {
            deadlineLabel
            Spacer()
            remainingLabel
        }
    }

    @ViewBuilder
    private var deadlineLabel: some View {
        if goal.isCompleted {
            Text(String(localized: "Hoàn thành"))
                .font(Typography.labelSmall)
                .foregroundStyle(Color.appIncome)
        } else if let days = SavingsGoalHelpers.daysRemaining(for: goal) {
            Text(days > 0
                ? String(localized: "Còn \(days) ngày")
                : String(localized: "Đã hết hạn"))
                .font(Typography.labelSmall)
                .foregroundStyle(days <= 7 ? Color.appError : Color.onSurfaceVariant)
        }
    }

    private var remainingLabel: some View {
        Text(goal.formattedRemaining)
            .font(Typography.labelSmall)
            .foregroundStyle(Color.onSurfaceVariant)
        + Text(String(localized: " còn thiếu"))
            .font(Typography.labelSmall)
            .foregroundStyle(Color.onSurfaceVariant)
    }
}

#Preview {
    let goal = SavingsGoal(
        name: "Mua iPhone",
        targetAmount: 25_000_000,
        currentAmount: 15_000_000,
        deadline: Calendar.current.date(byAdding: .day, value: 30, to: .now),
        icon: "iphone",
        colorHex: "#D7A49A"
    )

    SavingsGoalRow(goal: goal)
        .padding()
        .appBackground()
}
