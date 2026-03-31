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
    @State private var showRecurringDepositSheet = false
    @State private var isHistoryExpanded = false

    internal var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.lg) {
                heroSection
                amountCard
                statsGrid
                projectedCompletionSection
                recurringDepositSection
                historySection
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
        .sheet(isPresented: $showRecurringDepositSheet) {
            RecurringDepositSheet(goal: goal, existingDeposit: goal.recurringDeposit)
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

// MARK: - Projected Completion Section

private extension SavingsGoalDetailView {
    @ViewBuilder
    private var projectedCompletionSection: some View {
        let hasHistory = !(goal.history?.isEmpty ?? true)
        let hasDeadline = goal.deadline != nil

        if hasHistory || hasDeadline {
            ProjectedCompletionCard(goal: goal)
        }
    }
}

// MARK: - Recurring Deposit Section

private extension SavingsGoalDetailView {
    private var recurringDepositSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if let deposit = goal.recurringDeposit, deposit.isActive {
                recurringDepositCard(deposit)
            } else {
                setupRecurringDepositCTA
            }
        }
    }

    private func recurringDepositCard(_ deposit: RecurringSavingsDeposit) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Label(
                    String(localized: "Nạp tiền tự động"),
                    systemImage: "arrow.clockwise.circle.fill"
                )
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurface)

                Spacer()

                HStack(spacing: Spacing.sm) {
                    M3IconButton(icon: "pencil", style: .filled) {
                        showRecurringDepositSheet = true
                    }
                    .accessibilityLabel(String(localized: "Sửa nạp tiền tự động"))

                    M3IconButton(icon: "trash", style: .filled) {
                        deleteRecurringDeposit(deposit)
                    }
                    .accessibilityLabel(String(localized: "Xoá nạp tiền tự động"))
                }
            }

            VStack(spacing: Spacing.sm) {
                depositInfoRow(
                    icon: "banknote",
                    label: String(localized: "Số tiền"),
                    value: deposit.formattedAmount
                )
                depositInfoRow(
                    icon: "repeat",
                    label: String(localized: "Tần suất"),
                    value: deposit.frequency.displayName
                )
                depositInfoRow(
                    icon: "calendar",
                    label: String(localized: "Lần tiếp theo"),
                    value: nextDepositDateText(for: deposit)
                )
            }
        }
        .padding(Spacing.lg)
        .m3Card()
    }

    private func depositInfoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(Typography.bodyMedium)
                .foregroundStyle(Color.onSurfaceVariant)
                .frame(width: 24)
            Text(label)
                .font(Typography.bodyMedium)
                .foregroundStyle(Color.onSurfaceVariant)
            Spacer()
            Text(value)
                .font(Typography.bodyMediumEmphasized)
                .foregroundStyle(Color.onSurface)
        }
    }

    private func nextDepositDateText(for deposit: RecurringSavingsDeposit) -> String {
        let nextDate = calculateNextDepositDate(for: deposit)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.string(from: nextDate)
    }

    private func calculateNextDepositDate(for deposit: RecurringSavingsDeposit) -> Date {
        let calendar = Calendar.current
        let baseDate = deposit.lastDepositDate ?? deposit.startDate

        switch deposit.frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: baseDate) ?? baseDate
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: baseDate) ?? baseDate
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: baseDate) ?? baseDate
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: baseDate) ?? baseDate
        }
    }

    private func deleteRecurringDeposit(_ deposit: RecurringSavingsDeposit) {
        HapticService.lightImpact()
        withAnimation(Motion.spatialDefault) {
            deposit.isActive = false
            goal.recurringDeposit = nil
            context.delete(deposit)
        }
    }

    private var setupRecurringDepositCTA: some View {
        Button {
            HapticService.lightImpact()
            showRecurringDepositSheet = true
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: "arrow.clockwise.circle")
                    .font(Typography.titleMedium)
                    .foregroundStyle(Color.onSurfaceVariant)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(String(localized: "Thiết lập nạp tiền tự động"))
                        .font(Typography.bodyMediumEmphasized)
                        .foregroundStyle(Color.onSurface)
                    Text(String(localized: "Tiết kiệm đều đặn, đạt mục tiêu nhanh hơn"))
                        .font(Typography.labelSmall)
                        .foregroundStyle(Color.onSurfaceVariant)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
            .padding(Spacing.lg)
            .m3Card()
        }
        .buttonStyle(ExpressivePressStyle())
        .accessibilityHint(String(localized: "Mở thiết lập nạp tiền tự động"))
    }
}

// MARK: - History Section

private extension SavingsGoalDetailView {
    private var historySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            historySectionHeader
            if isHistoryExpanded {
                historyContent
            }
        }
        .padding(Spacing.lg)
        .m3Card()
        .animation(reduceMotion ? .none : Motion.spatialDefault, value: isHistoryExpanded)
    }

    private var historySectionHeader: some View {
        Button {
            HapticService.lightImpact()
            withAnimation(reduceMotion ? .none : Motion.spatialDefault) {
                isHistoryExpanded.toggle()
            }
        } label: {
            HStack {
                Label(
                    String(localized: "Lịch sử giao dịch"),
                    systemImage: "clock.arrow.circlepath"
                )
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurface)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Color.onSurfaceVariant)
                    .rotationEffect(.degrees(isHistoryExpanded ? 90 : 0))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "Lịch sử giao dịch"))
        .accessibilityHint(isHistoryExpanded
            ? String(localized: "Nhấn để thu gọn")
            : String(localized: "Nhấn để mở rộng"))
    }

    @ViewBuilder
    private var historyContent: some View {
        let transactions = goal.history ?? []

        if transactions.isEmpty {
            historyEmptyState
        } else {
            VStack(spacing: Spacing.lg) {
                SavingsHistoryChart(
                    transactions: transactions,
                    goalColorHex: goal.colorHex,
                    initialBalance: 0
                )

                SavingsHistoryList(
                    transactions: transactions,
                    limit: 10,
                    showHeader: false,
                    onViewAll: {
                        // TODO: Navigate to full history view
                    }
                )
            }
        }
    }

    private var historyEmptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "tray")
                .font(Typography.displaySmall)
                .foregroundStyle(Color.outlineVariant)
            Text(String(localized: "Chưa có giao dịch"))
                .font(Typography.bodyMedium)
                .foregroundStyle(Color.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
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
