import SwiftUI
import SwiftData

internal struct SavingsGoalDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    internal let goal: SavingsGoal
    @State private var viewModel = SavingsGoalDetailViewModel()
    @State private var showDeleteConfirmation = false
    @State private var showEditSheet = false

    internal var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.lg) {
                heroSection
                amountCard
                statsGrid
                actionButtons
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xxxl)
        }
        .appBackground()
        .navigationTitle(goal.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .toolbar { toolbarItems }
        .confirmationDialog(
            String(localized: "Xoá mục tiêu"),
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            deleteButtons
        } message: {
            Text(String(localized: "Bạn có chắc muốn xoá mục tiêu này?"))
        }
        .sheet(isPresented: $viewModel.isShowingAddFundsSheet) {
            AddFundsSheet(goal: goal, isPresented: $viewModel.isShowingAddFundsSheet, viewModel: viewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(Spacing.cornerExtraExtraLarge)
                .presentationBackground(Color.surfaceContainerLowest)
        }
        .sheet(isPresented: $viewModel.isShowingWithdrawSheet) {
            WithdrawFundsSheet(goal: goal, isPresented: $viewModel.isShowingWithdrawSheet, viewModel: viewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(Spacing.cornerExtraExtraLarge)
                .presentationBackground(Color.surfaceContainerLowest)
        }
        .sheet(isPresented: $showEditSheet) {
            EditSavingsGoalSheet(goal: goal)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(Spacing.cornerExtraExtraLarge)
                .presentationBackground(Color.surfaceContainerLowest)
        }
        .overlay { if viewModel.showCompletionCelebration { celebrationOverlay } }
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
    private var deleteButtons: some View {
        Button(String(localized: "Xoá"), role: .destructive) {
            viewModel.deleteSavingsGoal(goal, context: context)
            dismiss()
        }
        Button(String(localized: "Huỷ"), role: .cancel) {}
    }

    private var celebrationOverlay: some View {
        SuccessOverlay(
            message: String(localized: "Chúc mừng! Mục tiêu hoàn thành!"),
            accessibilityMessage: String(localized: "Chúc mừng, mục tiêu tiết kiệm đã hoàn thành")
        )
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button { showEditSheet = true } label: {
                Image(systemName: "pencil")
            }
            .accessibilityLabel(String(localized: "Sửa mục tiêu"))
        }
        ToolbarItem(placement: .secondaryAction) {
            Button(role: .destructive) { showDeleteConfirmation = true } label: {
                Label(String(localized: "Xoá mục tiêu"), systemImage: "trash")
            }
        }
    }
}

// MARK: - Hero Section

private extension SavingsGoalDetailView {
    private var heroSection: some View {
        VStack(spacing: Spacing.lg) {
            progressRing
            goalInfo
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .m3HeroCard()
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.outlineVariant.opacity(0.3), lineWidth: 14)
                .frame(width: 160, height: 160)
            Circle()
                .trim(from: 0, to: goal.progress)
                .stroke(
                    viewModel.progressColor(for: goal),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? .none : Motion.spatialDefault, value: goal.progress)
            VStack(spacing: Spacing.xs) {
                Text("\(Int(goal.progress * 100))%")
                    .font(Typography.heroMedium)
                    .monospacedDigit()
                    .foregroundStyle(Color.onSurface)
                    .contentTransition(.numericText())
                Text(String(localized: "Tiến độ"))
                    .font(Typography.labelSmall)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "Tiến độ mục tiêu"))
        .accessibilityValue(String(localized: "\(Int(goal.progress * 100)) phần trăm"))
    }

    private var goalInfo: some View {
        HStack(spacing: Spacing.md) {
            M3IconBadge(icon: goal.icon, color: Color(hex: goal.colorHex), size: IconSize.containerXXL)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(goal.name)
                    .font(Typography.titleMediumEmphasized)
                    .foregroundStyle(Color.onSurface)
                if goal.isCompleted {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill").font(Typography.labelSmall)
                        Text(String(localized: "Hoàn thành")).font(Typography.labelSmall)
                    }
                    .foregroundStyle(Color.appIncome)
                }
            }
            Spacer()
        }
    }
}

// MARK: - Amount Card

private extension SavingsGoalDetailView {
    private var amountCard: some View {
        VStack(spacing: Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text(goal.formattedCurrent)
                    .font(Typography.headlineMedium)
                    .monospacedDigit()
                    .foregroundStyle(Color.onSurface)
                Text("/ \(goal.formattedTarget)")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            CapsuleProgressBar(
                progress: goal.progress,
                tint: viewModel.progressColor(for: goal),
                height: 10
            )

            HStack {
                Text(String(localized: "Còn thiếu"))
                    .font(Typography.labelSmall)
                    .foregroundStyle(Color.onSurfaceVariant)
                Spacer()
                Text(goal.formattedRemaining)
                    .font(Typography.labelMedium)
                    .monospacedDigit()
                    .foregroundStyle(viewModel.progressColor(for: goal))
            }
        }
        .padding(Spacing.lg)
        .m3Card()
    }
}

// MARK: - Stats Grid

private extension SavingsGoalDetailView {
    private var statsGrid: some View {
        HStack(spacing: Spacing.md) {
            BudgetMetricPill(
                icon: "target",
                label: String(localized: "Mục tiêu"),
                value: goal.formattedTarget,
                color: .appPrimary
            )
            deadlinePill
        }
    }

    private var deadlinePill: some View {
        let days = viewModel.daysRemaining(for: goal)
        let text: String
        let color: Color
        if let days {
            text = days > 0
                ? String(localized: "\(days) ngày")
                : String(localized: "Đã hết hạn")
            color = days <= 7 ? .appError : .onSurface
        } else {
            text = String(localized: "Không giới hạn")
            color = .onSurfaceVariant
        }
        return BudgetMetricPill(
            icon: "calendar",
            label: String(localized: "Hạn chót"),
            value: text,
            color: color
        )
    }
}

// MARK: - Action Buttons

private extension SavingsGoalDetailView {
    private var actionButtons: some View {
        HStack(spacing: Spacing.md) {
            GlassSaveButton(
                label: String(localized: "Thêm tiền"),
                isEnabled: !goal.isCompleted,
                tintColor: .appIncome
            ) {
                viewModel.isShowingAddFundsSheet = true
            }
            GlassSaveButton(
                label: String(localized: "Rút tiền"),
                isEnabled: goal.currentAmount > 0,
                tintColor: .appWarning
            ) {
                viewModel.isShowingWithdrawSheet = true
            }
        }
    }
}
