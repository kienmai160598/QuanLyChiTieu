import SwiftUI
import SwiftData

internal struct BudgetListView: View {
    @Query private var allBudgets: [Budget]
    @Query(sort: \Transaction.date, order: .reverse)
    private var allTransactions: [Transaction]

    @Environment(\.modelContext) private var context
    @State private var viewModel = BudgetListViewModel()
    @State private var selectedMonthYear: String = Date().monthYearKey
    @State private var budgetToDelete: Budget?
    @State private var showDeleteConfirmation = false
    private var selectedBudgets: [Budget] { allBudgets.filter { $0.monthYear == selectedMonthYear } }
    private var categoryBudgets: [Budget] { selectedBudgets.filter { !$0.isOverallCap } }

    internal var body: some View {
        List {
            monthNavigationSection
            overallCapListSection
            if !categoryBudgets.isEmpty { overviewSection }
            budgetCategorySection
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .appBackground()
        .toolbar {
            addButton
            copyButton
        }
        .confirmationDialog(
            String(localized: "Xoá ngân sách"),
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            deleteDialogButtons
        } message: {
            Text(String(localized: "Bạn có chắc muốn xoá ngân sách này?"))
        }
        .sheet(isPresented: $viewModel.isShowingAddSheet) {
            AddBudgetSheet(existingBudgets: selectedBudgets, monthYear: selectedMonthYear)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(Spacing.cornerExtraExtraLarge)
                .presentationBackground(Color.surfaceContainerLowest)
        }
        .overlay(alignment: .bottom) { toastOverlay }
        .animation(Motion.effectDefault, value: viewModel.copySuccess)
        .animation(Motion.effectDefault, value: viewModel.rolloverSuccess)
        .alert(
            String(localized: "Lỗi"),
            isPresented: hasError,
            actions: { Button(String(localized: "OK")) { viewModel.errorMessage = nil } },
            message: { Text(viewModel.errorMessage ?? "") }
        )
        .onChange(of: allTransactions) { loadViewModel() }
        .onChange(of: allBudgets) { loadViewModel() }
        .onChange(of: selectedMonthYear) { onMonthChange() }
        .task { loadViewModel() }
    }

    private var hasError: Binding<Bool> {
        Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })
    }

    private func loadViewModel() {
        viewModel.loadData(
            budgets: selectedBudgets,
            transactions: allTransactions,
            monthYear: selectedMonthYear
        )
    }

    private func onMonthChange() {
        viewModel.autoRolloverIfNeeded(
            currentMonth: selectedMonthYear,
            currentBudgets: selectedBudgets,
            context: context
        )
        loadViewModel()
    }
}

// MARK: - Hero Row Styling

private extension View {
    func heroRowStyle() -> some View {
        self
            .listRowInsets(EdgeInsets(top: Spacing.sm, leading: Spacing.lg, bottom: Spacing.sm, trailing: Spacing.lg))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

// MARK: - Toolbar

private extension BudgetListView {
    @ToolbarContentBuilder
    var addButton: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button { viewModel.isShowingAddSheet = true } label: { Image(systemName: "plus") }
                .accessibilityLabel(String(localized: "Thêm ngân sách"))
        }
    }

    @ToolbarContentBuilder
    var copyButton: some ToolbarContent {
        ToolbarItem(placement: .secondaryAction) {
            Button {
                viewModel.copyBudgetsToNextMonth(
                    budgets: selectedBudgets, currentMonthYear: selectedMonthYear, context: context
                )
            } label: {
                Label(String(localized: "Sao chép sang tháng sau"), systemImage: "doc.on.doc")
            }
            .disabled(selectedBudgets.isEmpty)
        }
    }

    @ViewBuilder var deleteDialogButtons: some View {
        Button(String(localized: "Xoá"), role: .destructive) {
            if let budget = budgetToDelete { viewModel.deleteBudget(budget, context: context) }
            budgetToDelete = nil
        }
        Button(String(localized: "Huỷ"), role: .cancel) { budgetToDelete = nil }
    }
}

// MARK: - Month Navigation Section

private extension BudgetListView {
    var monthNavigationSection: some View {
        Section {
            HStack {
                monthNavButton(icon: "chevron.left", label: "Tháng trước") {
                    selectedMonthYear = BudgetListViewModel.previousMonthKey(from: selectedMonthYear)
                }
                Spacer()
                Text(BudgetListViewModel.displayLabel(for: selectedMonthYear))
                    .font(Typography.titleMedium)
                    .foregroundStyle(Color.onSurface)
                Spacer()
                monthNavButton(icon: "chevron.right", label: "Tháng sau") {
                    selectedMonthYear = BudgetListViewModel.nextMonthKey(from: selectedMonthYear)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .heroRowStyle()
    }

    func monthNavButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(Typography.bodyLarge).foregroundStyle(Color.onSurface)
        }
        .accessibilityLabel(String(localized: "\(label)"))
    }
}

// MARK: - Overall Cap & Overview Sections

private extension BudgetListView {
    @ViewBuilder
    var overallCapListSection: some View {
        Section {
            if viewModel.overallCapBudget != nil { overallCapCard } else { setCapButton }
        }
        .heroRowStyle()
    }

    var overallCapCard: some View {
        VStack(spacing: Spacing.xl) {
            SectionHeader("Hạn mức tháng").padding(.horizontal, Spacing.xs)
            BudgetProgressRing(
                progress: viewModel.overallCapProgress,
                tintColor: viewModel.overallCapProgressColor,
                label: String(localized: "Hạn mức tháng")
            )
            metricPillRow(
                spent: viewModel.formattedCapSpent,
                remaining: viewModel.formattedCapRemaining,
                isNegative: viewModel.capRemainingIsNegative
            )
        }
        .padding(Spacing.xl).frame(maxWidth: .infinity)
        .m3Card(cornerRadius: Spacing.cornerMedium + Spacing.xs)
    }

    var setCapButton: some View {
        Button { viewModel.isShowingAddSheet = true } label: {
            Label(String(localized: "Đặt hạn mức tháng"), systemImage: "plus.circle")
                .font(Typography.bodyMedium).foregroundStyle(Color.onSurfaceVariant)
                .frame(maxWidth: .infinity).padding(.vertical, Spacing.lg)
        }
    }

    var overviewSection: some View {
        Section {
            VStack(spacing: Spacing.xl) {
                BudgetProgressRing(
                    progress: viewModel.budgetProgress,
                    tintColor: viewModel.progressColor,
                    label: String(localized: "Tiến độ ngân sách")
                )
                metricPillRow(
                    spent: viewModel.formattedSpent,
                    remaining: viewModel.formattedRemaining,
                    isNegative: viewModel.remainingIsNegative
                )
            }
            .padding(Spacing.xl).frame(maxWidth: .infinity)
            .m3Card(cornerRadius: Spacing.cornerMedium + Spacing.xs)
        }
        .heroRowStyle()
    }

    func metricPillRow(spent: String, remaining: String, isNegative: Bool) -> some View {
        let remainColor = isNegative ? Color.appError : Color.appIncome
        return HStack(spacing: Spacing.md) {
            BudgetMetricPill(icon: "arrow.up.right", label: String(localized: "Đã chi"), value: spent, color: .appError)
            BudgetMetricPill(icon: "arrow.down.left", label: String(localized: "Còn lại"), value: remaining, color: remainColor)
        }
    }
}

// MARK: - Category Budgets Section

private extension BudgetListView {
    var budgetCategorySection: some View {
        Section {
            if categoryBudgets.isEmpty {
                EmptyStateCard(
                    icon: "chart.pie.fill",
                    title: String(localized: "Chưa có ngân sách"),
                    actionLabel: String(localized: "Thêm ngân sách"),
                    onAction: { viewModel.isShowingAddSheet = true }
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(categoryBudgets) { budget in
                    NavigationLink(value: BudgetRoute.detail(budget.persistentModelID)) {
                        BudgetRowView(budget: budget, viewModel: viewModel)
                    }
                    .m3SectionRow()
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            budgetToDelete = budget
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
        } header: {
            HStack {
                Text(String(localized: "Theo danh mục"))
                    .font(Typography.titleSmall)
                    .foregroundStyle(Color.onSurfaceVariant)
                    .textCase(nil)
                Spacer()
                if viewModel.totalBudget > 0 {
                    Text(viewModel.formattedTotal)
                        .font(Typography.labelSmall)
                        .foregroundStyle(Color.onSurfaceVariant)
                }
            }
        }
    }
}

// MARK: - Toast Overlay

private extension BudgetListView {
    @ViewBuilder var toastOverlay: some View {
        if viewModel.copySuccess {
            toastBanner(icon: "checkmark.circle.fill", text: String(localized: "Đã sao chép ngân sách sang tháng sau"))
                .onAppear { dismissToast(keyPath: \.copySuccess) }
        }
        if viewModel.rolloverSuccess {
            toastBanner(icon: "arrow.triangle.2.circlepath", text: String(localized: "Đã tự động chuyển ngân sách"))
                .onAppear { dismissToast(keyPath: \.rolloverSuccess) }
        }
    }

    func toastBanner(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon).foregroundStyle(Color.appIncome)
            Text(text).font(Typography.labelLarge).foregroundStyle(Color.onSurface)
        }
        .padding(.horizontal, Spacing.lg).padding(.vertical, Spacing.md).padding(.bottom, Spacing.xxxl)
        .background(Color.surfaceContainerHigh, in: .capsule)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    func dismissToast(keyPath: ReferenceWritableKeyPath<BudgetListViewModel, Bool>) {
        Task { try? await Task.sleep(for: .seconds(2)); withAnimation { viewModel[keyPath: keyPath] = false } }
    }
}

#Preview {
    NavigationStack { BudgetListView() }
        .modelContainer(for: [Transaction.self, Category.self, Budget.self], inMemory: true)
}
