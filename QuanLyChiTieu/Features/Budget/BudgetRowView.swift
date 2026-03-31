import SwiftUI

// MARK: - Budget Row (pure visual content)

/// Pure visual content — navigation, swipe actions, and context menus
/// are handled by the parent List in BudgetListView.
///
/// Layout: [M3IconBadge] [VStack: name + warning] [Spacer] [spent / limit] + CapsuleProgressBar
internal struct BudgetRowView: View {
    internal let budget: Budget
    internal let viewModel: BudgetListViewModel

    internal var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            rowHeader
            CapsuleProgressBar(
                progress: viewModel.progressFor(budget),
                tint: viewModel.progressColorFor(budget)
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
    }

    private var accessibilityLabel: String {
        String(localized: "\(budget.category?.localizedName ?? String(localized: "Tổng")) ngân sách")
    }

    private var accessibilityValue: String {
        let spent = BudgetListViewModel.formatVND(viewModel.spentFor(budget))
        let percent = Int(viewModel.progressFor(budget) * 100)
        return String(localized: "\(spent) trên \(budget.formattedLimit), \(percent) phần trăm")
    }

    private var rowHeader: some View {
        HStack(spacing: Spacing.md) {
            M3IconBadge(
                icon: budget.category?.icon ?? "banknote.fill",
                color: budget.category.map { Color(hex: $0.colorHex) } ?? .appPrimary
            )
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack(spacing: Spacing.xs) {
                    Text(budget.category?.localizedName ?? String(localized: "Tổng"))
                        .font(Typography.bodyLarge)
                        .foregroundStyle(Color.onSurface)
                    if budget.autoRollover {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Color.onSurfaceVariant)
                            .accessibilityLabel(String(localized: "Tự động chuyển"))
                    }
                }
                overBudgetWarning
            }
            Spacer()
            spentLabel
        }
    }

    @ViewBuilder
    private var overBudgetWarning: some View {
        if viewModel.progressFor(budget) >= 1.0 {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(Typography.labelSmall)
                Text(String(localized: "Vượt ngân sách"))
                    .font(Typography.labelSmall)
            }
            .foregroundStyle(Color.appError)
        }
    }

    private var spentLabel: some View {
        HStack(spacing: Spacing.xs) {
            Text(BudgetListViewModel.formatVND(viewModel.spentFor(budget)))
                .font(Typography.labelLarge)
                .foregroundStyle(Color.onSurface)
            Text("/ \(budget.formattedLimit)")
                .font(Typography.bodySmall)
                .foregroundStyle(Color.onSurfaceVariant)
        }
    }
}
