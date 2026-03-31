import SwiftUI
import SwiftData

internal struct EventDetailView: View {
    internal let event: Event

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showAddExpenseAlert = false
    @State private var showDeleteConfirmation = false
    @State private var expenseAmountText: String = ""

    internal var body: some View {
        mainContent
            .appBackground()
            .navigationTitle(event.name)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbar { toolbarButtons }
            .alert(String(localized: "Thêm chi tiêu"), isPresented: $showAddExpenseAlert) {
                expenseAlertActions
            } message: {
                Text(String(localized: "Nhập số tiền chi tiêu cho sự kiện"))
            }
            .confirmationDialog(String(localized: "Xoá sự kiện"), isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                deleteDialogActions
            } message: {
                Text(String(localized: "Bạn có chắc muốn xoá sự kiện này?"))
            }
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                statusBadge
                progressCard
                detailsCard
                addExpenseButton
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
        }
    }

    @ViewBuilder
    private var expenseAlertActions: some View {
        TextField(String(localized: "Số tiền"), text: $expenseAmountText)
            .keyboardType(.numberPad)
        Button(String(localized: "Thêm")) { addExpense() }
        Button(String(localized: "Huỷ"), role: .cancel) { expenseAmountText = "" }
    }

    @ViewBuilder
    private var deleteDialogActions: some View {
        Button(String(localized: "Xoá"), role: .destructive) { deleteEvent() }
        Button(String(localized: "Huỷ"), role: .cancel) {}
    }

    @ToolbarContentBuilder
    private var toolbarButtons: some ToolbarContent {
        ToolbarItem(placement: .destructiveAction) {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
            }
            .accessibilityLabel(String(localized: "Xoá sự kiện"))
        }
    }
}

// MARK: - Status Badge

private extension EventDetailView {
    private var statusBadge: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: statusIcon)
                .foregroundStyle(statusColor)
            Text(statusLabel)
                .font(Typography.labelLarge)
                .foregroundStyle(statusColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
    }

    private var statusIcon: String {
        if event.isActive { return "circle.fill" }
        if event.startDate > Date.now { return "clock.fill" }
        return "checkmark.circle.fill"
    }

    private var statusColor: Color {
        if event.isActive { return .appIncome }
        if event.startDate > Date.now { return Color(hex: event.colorHex) }
        return .onSurfaceVariant
    }

    private var statusLabel: String {
        if event.isActive { return String(localized: "Đang diễn ra") }
        if event.startDate > Date.now { return String(localized: "Sắp tới") }
        return String(localized: "Đã kết thúc")
    }
}

// MARK: - Progress Card

private extension EventDetailView {
    private var progressCard: some View {
        VStack(spacing: Spacing.lg) {
            progressRing
            metricRow
        }
        .padding(Spacing.xl)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerMedium))
        .padding(Spacing.xs)
        .m3Card(cornerRadius: Spacing.cornerMedium + Spacing.xs)
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.outlineVariant.opacity(0.3), lineWidth: 10)
                .frame(width: 120, height: 120)
            Circle()
                .trim(from: 0, to: event.budgetProgress)
                .stroke(progressTintColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
            VStack(spacing: Spacing.xs) {
                Text("\(Int(event.budgetProgress * 100))%")
                    .font(Typography.headlineSmall)
                    .foregroundStyle(Color.onSurface)
                    .contentTransition(.numericText())
                Text(String(localized: "đã chi"))
                    .font(Typography.labelSmall)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
        }
        .accessibilityLabel(
            String(localized: "Đã chi \(Int(event.budgetProgress * 100)) phần trăm ngân sách")
        )
    }

    private var metricRow: some View {
        HStack(spacing: Spacing.md) {
            BudgetMetricPill(
                icon: "arrow.up.right",
                label: String(localized: "Đã chi"),
                value: event.formattedSpent,
                color: .appError
            )
            BudgetMetricPill(
                icon: "banknote.fill",
                label: String(localized: "Ngân sách"),
                value: event.formattedBudget,
                color: Color(hex: event.colorHex)
            )
        }
    }

    private var progressTintColor: Color {
        let progress = event.budgetProgress
        if progress >= 0.9 { return Color.appError }
        if progress >= 0.7 { return Color.appWarning }
        return Color(hex: event.colorHex)
    }
}

// MARK: - Details Card

private extension EventDetailView {
    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            detailRow(
                label: String(localized: "Ngày bắt đầu"),
                value: event.startDate.formatted(.dateTime.day().month(.wide).year())
            )
            detailRow(
                label: String(localized: "Ngày kết thúc"),
                value: event.endDate.formatted(.dateTime.day().month(.wide).year())
            )
            detailRow(
                label: String(localized: "Còn lại"),
                value: event.remainingBudget.formattedVND
            )
            if !event.notes.isEmpty {
                detailRow(
                    label: String(localized: "Ghi chú"),
                    value: event.notes
                )
            }
        }
        .padding(Spacing.xl)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerMedium))
        .padding(Spacing.xs)
        .m3Card(cornerRadius: Spacing.cornerMedium + Spacing.xs)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Typography.bodySmall)
                .foregroundStyle(Color.onSurfaceVariant)
            Spacer()
            Text(value)
                .font(Typography.bodyLarge)
                .foregroundStyle(Color.onSurface)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Actions

private extension EventDetailView {
    @ViewBuilder
    private var addExpenseButton: some View {
        if event.isActive {
            Button { showAddExpenseAlert = true } label: {
                Text(String(localized: "Thêm chi tiêu"))
                    .font(Typography.labelLarge)
                    .foregroundStyle(Color.onSurface)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Color.appPrimary, in: .capsule)
            }
        }
    }

    private func addExpense() {
        let cleaned = expenseAmountText.replacingOccurrences(of: ".", with: "")
        guard let amount = Decimal(string: cleaned), amount > 0 else {
            expenseAmountText = ""
            return
        }
        event.spentAmount += amount
        try? context.save()
        expenseAmountText = ""
        HapticService.success()
    }

    private func deleteEvent() {
        context.delete(event)
        try? context.save()
        dismiss()
    }
}

#Preview {
    let event = Event(
        name: "Du lịch Đà Lạt",
        icon: "airplane",
        colorHex: "#D7A49A",
        startDate: .now,
        endDate: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: .now) ?? .now,
        budgetLimit: 5_000_000,
        spentAmount: 2_000_000
    )
    NavigationStack { EventDetailView(event: event) }
        .modelContainer(for: Event.self, inMemory: true)
}
