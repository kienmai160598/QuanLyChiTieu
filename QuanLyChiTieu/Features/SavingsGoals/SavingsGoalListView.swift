import SwiftUI
import SwiftData

internal struct SavingsGoalListView: View {
    @Query(sort: \SavingsGoal.createdAt, order: .reverse)
    private var goals: [SavingsGoal]

    @Environment(\.modelContext) private var context
    @State private var viewModel = SavingsGoalListViewModel()
    @State private var goalToDelete: SavingsGoal?
    @State private var showDeleteConfirmation = false

    private var displayedGoals: [SavingsGoal] {
        viewModel.filteredGoals(goals)
    }

    internal var body: some View {
        Group {
            if goals.isEmpty {
                emptyState
            } else {
                mainContent
            }
        }
        .appBackground()
        .navigationTitle(String(localized: "Tiết kiệm"))
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .searchable(text: $viewModel.searchText, prompt: String(localized: "Tìm kiếm mục tiêu"))
        .glassFABOverlay(icon: "plus", tint: .appIncome) {
            viewModel.isShowingAddSheet = true
        }
        .sheet(isPresented: $viewModel.isShowingAddSheet) {
            AddSavingsGoalSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(Spacing.cornerExtraExtraLarge)
                .presentationBackground(Color.surfaceContainerLowest)
        }
        .confirmationDialog(
            String(localized: "Xoá mục tiêu"),
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            deleteConfirmationButtons
        } message: {
            Text(String(localized: "Bạn có chắc muốn xoá mục tiêu này?"))
        }
        .alert(
            String(localized: "Lỗi"),
            isPresented: hasError,
            actions: { Button(String(localized: "OK")) { viewModel.clearError() } },
            message: { Text(viewModel.errorMessage ?? "") }
        )
    }

    private var hasError: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearError() } }
        )
    }

    @ViewBuilder
    private var deleteConfirmationButtons: some View {
        Button(String(localized: "Xoá"), role: .destructive) {
            if let goal = goalToDelete {
                viewModel.deleteSavingsGoal(goal, context: context)
            }
            goalToDelete = nil
        }
        Button(String(localized: "Huỷ"), role: .cancel) { goalToDelete = nil }
    }
}

// MARK: - Empty State

private extension SavingsGoalListView {
    var emptyState: some View {
        ScrollView {
            EmptyStateCard(
                icon: "target",
                title: String(localized: "Chưa có mục tiêu tiết kiệm"),
                actionLabel: String(localized: "Thêm mục tiêu"),
                onAction: { viewModel.isShowingAddSheet = true }
            )
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.xl)
        }
    }
}

// MARK: - Main Content

private extension SavingsGoalListView {
    var mainContent: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.lg) {
                heroCard
                filterChips
                goalCards
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.sm)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Hero Card

private extension SavingsGoalListView {
    var totalSavings: Decimal {
        goals.filter { !$0.isArchived }.reduce(Decimal(0)) { $0 + $1.currentAmount }
    }

    var totalTarget: Decimal {
        goals.filter { !$0.isArchived }.reduce(Decimal(0)) { $0 + $1.targetAmount }
    }

    var overallProgress: Double {
        guard totalTarget > 0 else { return 0 }
        return min((totalSavings as NSDecimalNumber).doubleValue
            / (totalTarget as NSDecimalNumber).doubleValue, 1)
    }

    var activeCount: Int {
        goals.filter { !$0.isCompleted && !$0.isArchived }.count
    }

    var completedCount: Int {
        goals.filter { $0.isCompleted && !$0.isArchived }.count
    }

    var heroCard: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.xs) {
                Text(String(localized: "Tổng tiết kiệm"))
                    .font(Typography.labelMedium)
                    .foregroundStyle(Color.inverseOnSurface)
                Text(totalSavings.formattedVND)
                    .font(Typography.heroLarge)
                    .monospacedDigit()
                    .tracking(-1.5)
                    .foregroundStyle(Color.inverseOnSurface)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }

            VStack(spacing: Spacing.sm) {
                CapsuleProgressBar(progress: overallProgress, tint: .appIncome, height: 6)
                HStack {
                    Text(String(localized: "\(activeCount) đang tiết kiệm"))
                        .font(Typography.labelSmall)
                    Spacer()
                    if completedCount > 0 {
                        Text(String(localized: "\(completedCount) hoàn thành"))
                            .font(Typography.labelSmall)
                    }
                }
                .foregroundStyle(Color.inverseOnSurface)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .m3HeroCard(background: .inverseSurface)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "Tổng tiết kiệm \(totalSavings.formattedVND)"))
    }
}

// MARK: - Filter Chips

private extension SavingsGoalListView {
    var filterChips: some View {
        GlassChipGroup(
            items: SavingsGoalListViewModel.filterChips,
            selectedID: $viewModel.selectedFilter
        )
    }
}

// MARK: - Goal Cards

private extension SavingsGoalListView {
    var goalCards: some View {
        ForEach(displayedGoals) { goal in
            NavigationLink(value: SavingsGoalRoute.detail(goal.persistentModelID)) {
                goalCard(goal)
            }
            .buttonStyle(.plain)
            .contextMenu { contextMenuItems(for: goal) }
        }
    }

    private func goalCard(_ goal: SavingsGoal) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            cardHeader(goal)
            amountRow(goal)
            CapsuleProgressBar(progress: goal.progress, tint: viewModel.progressColor(for: goal))
            cardFooter(goal)
        }
        .padding(Spacing.lg)
        .m3Card()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(goal.name), \(goal.formattedCurrent) / \(goal.formattedTarget)")
        .accessibilityValue(String(localized: "\(Int(goal.progress * 100)) phần trăm"))
    }

    private func cardHeader(_ goal: SavingsGoal) -> some View {
        HStack(spacing: Spacing.md) {
            M3IconBadge(icon: goal.icon, color: Color(hex: goal.colorHex))
            Text(goal.name)
                .font(Typography.titleSmallEmphasized)
                .foregroundStyle(Color.onSurface)
                .lineLimit(1)
            Spacer()
            if goal.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.appIncome)
            } else if goal.isArchived {
                Image(systemName: "archivebox.fill")
                    .foregroundStyle(Color.onSurfaceVariant)
            }
        }
    }

    private func amountRow(_ goal: SavingsGoal) -> some View {
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
                .foregroundStyle(viewModel.progressColor(for: goal))
                .contentTransition(.numericText())
        }
    }

    private func cardFooter(_ goal: SavingsGoal) -> some View {
        HStack {
            if goal.isCompleted {
                Text(String(localized: "Hoàn thành"))
                    .font(Typography.labelSmall)
                    .foregroundStyle(Color.appIncome)
            } else if let days = viewModel.daysRemaining(for: goal) {
                Text(days > 0
                    ? String(localized: "Còn \(days) ngày")
                    : String(localized: "Đã hết hạn"))
                    .font(Typography.labelSmall)
                    .foregroundStyle(days <= 7 ? Color.appError : Color.onSurfaceVariant)
            }
            Spacer()
            Text(goal.formattedRemaining)
                .font(Typography.labelSmall)
                .foregroundStyle(Color.onSurfaceVariant)
            + Text(String(localized: " còn thiếu"))
                .font(Typography.labelSmall)
                .foregroundStyle(Color.onSurfaceVariant)
        }
    }

    @ViewBuilder
    private func contextMenuItems(for goal: SavingsGoal) -> some View {
        if !goal.isArchived {
            Button {
                viewModel.archiveGoal(goal, context: context)
            } label: {
                Label(String(localized: "Lưu trữ"), systemImage: "archivebox")
            }
        }
        Button(role: .destructive) {
            goalToDelete = goal
            showDeleteConfirmation = true
        } label: {
            Label(String(localized: "Xoá"), systemImage: "trash")
        }
    }
}

#Preview {
    NavigationStack { SavingsGoalListView() }
        .modelContainer(for: SavingsGoal.self, inMemory: true)
}
