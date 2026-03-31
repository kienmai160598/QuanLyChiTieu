import SwiftUI
import SwiftData

internal struct DebtDetailView: View {
    internal let debt: Debt

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showPaymentSheet = false
    @State private var showSettleConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var paymentAmountText: String = ""

    internal var body: some View {
        mainContent
            .appBackground()
            .navigationTitle(debt.title)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbar { toolbarButtons }
            .alert(String(localized: "Thanh toán"), isPresented: $showPaymentSheet) {
                paymentAlertActions
            } message: {
                Text(String(localized: "Nhập số tiền thanh toán"))
            }
            .confirmationDialog(String(localized: "Tất toán khoản nợ"), isPresented: $showSettleConfirmation, titleVisibility: .visible) {
                settleDialogActions
            } message: {
                Text(String(localized: "Đánh dấu khoản nợ này đã tất toán?"))
            }
            .confirmationDialog(String(localized: "Xoá khoản nợ"), isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                deleteDialogActions
            } message: {
                Text(String(localized: "Bạn có chắc muốn xoá khoản nợ này?"))
            }
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                statusHeader
                progressCard
                detailsCard
                actionButtons
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
        }
    }

    @ViewBuilder
    private var paymentAlertActions: some View {
        TextField(String(localized: "Số tiền"), text: $paymentAmountText)
            .keyboardType(.numberPad)
        Button(String(localized: "Xác nhận")) { processPayment() }
        Button(String(localized: "Huỷ"), role: .cancel) { paymentAmountText = "" }
    }

    @ViewBuilder
    private var settleDialogActions: some View {
        Button(String(localized: "Tất toán"), role: .destructive) { settleDebt() }
        Button(String(localized: "Huỷ"), role: .cancel) {}
    }

    @ViewBuilder
    private var deleteDialogActions: some View {
        Button(String(localized: "Xoá"), role: .destructive) { deleteDebt() }
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
            .accessibilityLabel(String(localized: "Xoá khoản nợ"))
        }
    }
}

// MARK: - Status Header

private extension DebtDetailView {
    private var statusHeader: some View {
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
        if debt.isSettled { return "checkmark.circle.fill" }
        if debt.isOverdue { return "exclamationmark.triangle.fill" }
        return debt.isLent ? "arrow.up.right.circle.fill" : "arrow.down.left.circle.fill"
    }

    private var statusColor: Color {
        if debt.isSettled { return .appIncome }
        if debt.isOverdue { return .appError }
        return debt.isLent ? .appIncome : .appError
    }

    private var statusLabel: String {
        if debt.isSettled { return String(localized: "Đã tất toán") }
        if debt.isOverdue { return String(localized: "Quá hạn") }
        return debt.isLent
            ? String(localized: "Đang cho vay")
            : String(localized: "Đang nợ")
    }
}

// MARK: - Progress Card

private extension DebtDetailView {
    private var progressCard: some View {
        VStack(spacing: Spacing.lg) {
            progressRing
            metricRow
        }
        .padding(Spacing.xl)
        .m3Card(cornerRadius: Spacing.cornerMedium + Spacing.xs)
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.outlineVariant.opacity(0.3), lineWidth: 10)
                .frame(width: 120, height: 120)
            Circle()
                .trim(from: 0, to: debt.progress)
                .stroke(statusColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
            VStack(spacing: Spacing.xs) {
                Text("\(Int(debt.progress * 100))%")
                    .font(Typography.headlineSmall)
                    .foregroundStyle(Color.onSurface)
                    .contentTransition(.numericText())
                Text(String(localized: "đã trả"))
                    .font(Typography.labelSmall)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
        }
        .accessibilityLabel(
            String(localized: "Đã trả \(Int(debt.progress * 100)) phần trăm")
        )
    }

    private var metricRow: some View {
        HStack(spacing: Spacing.md) {
            BudgetMetricPill(
                icon: "banknote.fill",
                label: String(localized: "Gốc"),
                value: debt.formattedPrincipal,
                color: .appSecondary
            )
            BudgetMetricPill(
                icon: "hourglass",
                label: String(localized: "Còn lại"),
                value: debt.formattedRemaining,
                color: debt.isOverdue ? .appError : .appWarning
            )
        }
    }
}

// MARK: - Details Card

private extension DebtDetailView {
    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            detailCardContent
        }
        .padding(Spacing.xl)
        .m3Card(cornerRadius: Spacing.cornerMedium + Spacing.xs)
    }

    @ViewBuilder
    private var detailCardContent: some View {
        detailRow(label: String(localized: "Người"), value: debt.personName)
        detailRow(
            label: String(localized: "Ngày bắt đầu"),
            value: debt.startDate.formatted(.dateTime.day().month(.wide).year())
        )
        if let dueDate = debt.dueDate {
            detailRow(
                label: String(localized: "Hạn trả"),
                value: dueDate.formatted(.dateTime.day().month(.wide).year())
            )
        }
        if let rate = debt.interestRate {
            detailRow(label: String(localized: "Lãi suất"), value: "\(rate)%")
        }
        if !debt.notes.isEmpty {
            detailRow(label: String(localized: "Ghi chú"), value: debt.notes)
        }
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

private extension DebtDetailView {
    @ViewBuilder
    private var actionButtons: some View {
        if !debt.isSettled {
            VStack(spacing: Spacing.md) {
                Button { showPaymentSheet = true } label: {
                    Text(String(localized: "Thanh toán"))
                        .font(Typography.labelLarge)
                        .foregroundStyle(Color.onSurface)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Color.appPrimary, in: .capsule)
                }
                Button { showSettleConfirmation = true } label: {
                    Text(String(localized: "Đánh dấu tất toán"))
                        .font(Typography.labelLarge)
                        .foregroundStyle(Color.onSurface)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Color.surfaceContainerHigh, in: .capsule)
                }
            }
        }
    }

    private func processPayment() {
        let cleaned = paymentAmountText.replacingOccurrences(of: ".", with: "")
        guard let amount = Decimal(string: cleaned), amount > 0 else {
            paymentAmountText = ""
            return
        }
        let newRemaining = max(debt.remainingAmount - amount, 0)
        debt.remainingAmount = newRemaining
        if newRemaining == 0 {
            debt.isSettled = true
        }
        try? context.save()
        paymentAmountText = ""
        HapticService.success()
    }

    private func settleDebt() {
        debt.remainingAmount = 0
        debt.isSettled = true
        try? context.save()
        HapticService.success()
    }

    private func deleteDebt() {
        context.delete(debt)
        try? context.save()
        dismiss()
    }
}
