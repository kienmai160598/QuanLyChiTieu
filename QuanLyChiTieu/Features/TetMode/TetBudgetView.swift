import SwiftUI
import SwiftData

internal struct TetBudgetView: View {
    @Query(sort: \Transaction.date, order: .reverse)
    private var allTransactions: [Transaction]

    @State private var viewModel = TetBudgetViewModel()

    internal var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                festiveHeader
                VStack(spacing: Spacing.xl) {
                    summaryCard
                    categorySection
                }
                dateRangeSection
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
        }
        .appBackground()
        .navigationTitle(String(localized: "Tết Nguyên Đán"))
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .task { viewModel.loadData(transactions: allTransactions) }
        .onChange(of: allTransactions) {
            viewModel.loadData(transactions: allTransactions)
        }
    }
}

// MARK: - Festive Header

private extension TetBudgetView {
    private var festiveHeader: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.appPrimary)
                Text(String(localized: "Tết Nguyên Đán 2027"))
                    .font(Typography.headlineMedium)
                    .foregroundStyle(Color.appPrimary)
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.appPrimary)
            }
            HStack(spacing: Spacing.sm) {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(Color.appSecondary)
                Text(String(localized: "Chúc Mừng Năm Mới"))
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Color.onSurfaceVariant)
                Image(systemName: "leaf.fill")
                    .foregroundStyle(Color.appSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
    }
}

// MARK: - Summary Card

private extension TetBudgetView {
    private var summaryCard: some View {
        VStack(spacing: Spacing.lg) {
            summaryMetrics
            savingsTargetField
        }
        .padding(Spacing.xl)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerMedium))
        .padding(Spacing.xs)
        .m3Card(cornerRadius: Spacing.cornerMedium + Spacing.xs)
    }

    private var summaryMetrics: some View {
        VStack(spacing: Spacing.md) {
            spentReceivedRow
            netRemainingRow
        }
    }

    private var spentReceivedRow: some View {
        HStack(spacing: Spacing.md) {
            BudgetMetricPill(
                icon: "arrow.up.right",
                label: String(localized: "Đã chi"),
                value: viewModel.formattedTotalSpent,
                color: .appError
            )
            BudgetMetricPill(
                icon: "arrow.down.left",
                label: String(localized: "Nhận được"),
                value: viewModel.formattedTotalReceived,
                color: .appIncome
            )
        }
    }

    private var netRemainingRow: some View {
        HStack(spacing: Spacing.md) {
            BudgetMetricPill(
                icon: "plusminus",
                label: String(localized: "Ròng"),
                value: viewModel.formattedNet,
                color: viewModel.netAmount >= 0 ? .appIncome : .appError
            )
            BudgetMetricPill(
                icon: "banknote.fill",
                label: String(localized: "Còn lại"),
                value: viewModel.formattedRemaining,
                color: viewModel.remainingIsNegative ? .appError : .appIncome
            )
        }
    }

    private var savingsTargetField: some View {
        HStack(spacing: Spacing.sm) {
            Text(String(localized: "Mục tiêu tiết kiệm Tết"))
                .font(Typography.bodySmall)
                .foregroundStyle(Color.onSurfaceVariant)
            Spacer()
            TextField("0", text: $viewModel.savingsTargetText)
                .keyboardType(.numberPad)
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurface)
                .multilineTextAlignment(.trailing)
                .frame(width: 120)
                .onChange(of: viewModel.savingsTargetText) {
                    viewModel.updateSavingsTarget()
                }
            Text("₫")
                .font(Typography.bodySmall)
                .foregroundStyle(Color.onSurfaceVariant)
        }
    }
}

// MARK: - Category Section

private extension TetBudgetView {
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader("Danh mục Tết")
                .padding(.horizontal, Spacing.lg)
            categoryCards
        }
    }

    private var categoryCards: some View {
        VStack(spacing: 0) {
            ForEach(
                Array(TetCategory.allCases.enumerated()),
                id: \.element
            ) { index, category in
                tetCategoryRow(category)
                if index < TetCategory.allCases.count - 1 {
                    Divider()
                        .foregroundStyle(Color.outlineVariant)
                        .padding(.leading, 56 + Spacing.lg)
                }
            }
        }
        .padding(.vertical, Spacing.sm)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerMedium))
        .padding(Spacing.xs)
        .m3Card(cornerRadius: Spacing.cornerMedium + Spacing.xs)
    }

    private func tetCategoryRow(_ category: TetCategory) -> some View {
        let spent = viewModel.spentByCategory[category.label] ?? 0
        return HStack(spacing: Spacing.md) {
            M3IconBadge(icon: category.icon, color: Color(hex: category.colorHex))
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(category.label)
                    .font(Typography.bodyLarge)
                    .foregroundStyle(Color.onSurface)
            }
            Spacer()
            Text(spent.formattedVND)
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurface)
                .monospacedDigit()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(category.label)
        .accessibilityValue(spent.formattedVND)
    }
}

// MARK: - Date Range Section

private extension TetBudgetView {
    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "Khoảng thời gian"))
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurfaceVariant)
            HStack(spacing: Spacing.md) {
                DatePicker(
                    String(localized: "Từ"),
                    selection: $viewModel.startDate,
                    displayedComponents: .date
                )
                .labelsHidden()
                Text("—")
                    .foregroundStyle(Color.onSurfaceVariant)
                DatePicker(
                    String(localized: "Đến"),
                    selection: $viewModel.endDate,
                    displayedComponents: .date
                )
                .labelsHidden()
            }
        }
        .padding(Spacing.lg)
        .onChange(of: viewModel.startDate) {
            viewModel.loadData(transactions: allTransactions)
        }
        .onChange(of: viewModel.endDate) {
            viewModel.loadData(transactions: allTransactions)
        }
    }
}

// MARK: - Tet Categories

internal enum TetCategory: String, CaseIterable, Sendable {
    case liXiGiven
    case liXiReceived
    case food
    case decoration
    case travel
    case clothes

    internal var label: String {
        switch self {
        case .liXiGiven: String(localized: "Lì xì đã cho")
        case .liXiReceived: String(localized: "Lì xì nhận được")
        case .food: String(localized: "Thực phẩm ngày Tết")
        case .decoration: String(localized: "Trang trí")
        case .travel: String(localized: "Du lịch Tết")
        case .clothes: String(localized: "Quần áo mới")
        }
    }

    internal var icon: String {
        switch self {
        case .liXiGiven: "gift.fill"
        case .liXiReceived: "gift.fill"
        case .food: "fork.knife"
        case .decoration: "sparkles"
        case .travel: "airplane"
        case .clothes: "tshirt.fill"
        }
    }

    internal var colorHex: String {
        switch self {
        case .liXiGiven: "#D7A49A"
        case .liXiReceived: "#A4B1BA"
        case .food: "#B5B89A"
        case .decoration: "#E4C9B6"
        case .travel: "#E1DAD3"
        case .clothes: "#3D3633"
        }
    }
}

#Preview {
    NavigationStack { TetBudgetView() }
        .modelContainer(for: Transaction.self, inMemory: true)
}
