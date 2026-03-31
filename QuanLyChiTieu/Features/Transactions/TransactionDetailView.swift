import SwiftUI
import SwiftData

// MARK: - TransactionDetailView

internal struct TransactionDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: TransactionDetailViewModel

    internal init(transaction: Transaction) {
        _viewModel = State(
            initialValue: TransactionDetailViewModel(transaction: transaction)
        )
    }

    internal var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                heroCard
                detailsCard
                if viewModel.hasNote { noteCard }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
        }
        .appBackground()
        .navigationTitle(String(localized: "Chi tiết"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .alert(
            String(localized: "Xoá giao dịch?"),
            isPresented: $viewModel.isShowingDeleteAlert
        ) {
            deleteAlertActions
        } message: {
            Text(String(localized: "Hành động này không thể hoàn tác."))
        }
        .sheet(isPresented: $viewModel.isShowingEditSheet) {
            NavigationStack {
                EditTransactionView(transaction: viewModel.transaction)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(Spacing.cornerExtraExtraLarge)
            .presentationBackground(Color.surfaceContainerLowest)
        }
        .alert(
            String(localized: "Lỗi"),
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            if let error = viewModel.errorMessage { Text(error) }
        }
    }
}

// MARK: - Hero Card

private extension TransactionDetailView {
    private var heroCard: some View {
        VStack(spacing: Spacing.md) {
            categoryIcon
            amountText
            typeBadge
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .m3Card(cornerRadius: Spacing.cornerExtraLarge)
    }

    private var categoryIcon: some View {
        Image(systemName: viewModel.categoryIcon)
            .font(.system(size: IconSize.md, weight: .medium))
            .foregroundStyle(Color.onSurface)
            .frame(width: IconSize.containerXXL, height: IconSize.containerXXL)
            .background(Color.surfaceContainerHigh, in: Circle())
    }

    private var amountText: some View {
        Text(viewModel.formattedAmount)
            .font(Typography.heroLarge)
            .foregroundStyle(viewModel.amountColor)
    }

    private var typeBadge: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: viewModel.typeIcon)
                .font(Typography.labelMedium)
            Text(viewModel.typeDisplayName)
                .font(Typography.labelLarge)
        }
        .foregroundStyle(viewModel.amountColor)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(viewModel.amountColor.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Details Card

private extension TransactionDetailView {
    private var detailsCard: some View {
        VStack(spacing: 0) {
            detailRow(
                icon: viewModel.categoryIcon,
                label: String(localized: "Danh mục"),
                value: viewModel.categoryName
            )
            Divider()
            detailRow(
                icon: "calendar",
                label: String(localized: "Ngày"),
                value: viewModel.formattedDate,
                subtitle: viewModel.formattedTime
            )
        }
        .padding(.vertical, Spacing.xs)
        .m3Card(cornerRadius: Spacing.cornerExtraLarge)
    }

    private func detailRow(
        icon: String,
        label: String,
        value: String,
        subtitle: String? = nil
    ) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: IconSize.sm, weight: .medium))
                .foregroundStyle(Color.onSurfaceVariant)
                .frame(width: IconSize.containerXS)
            Text(label)
                .font(Typography.bodyLarge)
                .foregroundStyle(Color.onSurface)
            Spacer()
            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text(value)
                    .font(Typography.bodyLarge)
                    .foregroundStyle(Color.onSurfaceVariant)
                if let subtitle {
                    Text(subtitle)
                        .font(Typography.labelSmall)
                        .foregroundStyle(Color.outlineVariant)
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .frame(minHeight: 52)
    }
}

// MARK: - Note Card

private extension TransactionDetailView {
    private var noteCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "note.text")
                    .font(.system(size: IconSize.sm, weight: .medium))
                    .foregroundStyle(Color.onSurfaceVariant)
                Text(String(localized: "Ghi chú"))
                    .font(Typography.labelLarge)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
            Text(viewModel.noteText)
                .font(Typography.bodyLarge)
                .foregroundStyle(Color.onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.lg)
        .m3Card(cornerRadius: Spacing.cornerExtraLarge)
    }
}

// MARK: - Toolbar & Alerts

private extension TransactionDetailView {
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button { viewModel.showEditSheet() } label: {
                Image(systemName: "pencil")
            }
            .accessibilityLabel(String(localized: "Sửa giao dịch"))
        }
        ToolbarItem(placement: .destructiveAction) {
            Button(role: .destructive) {
                viewModel.confirmDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(Color.appError)
            }
            .accessibilityLabel(String(localized: "Xoá giao dịch"))
        }
    }

    @ViewBuilder
    private var deleteAlertActions: some View {
        Button(String(localized: "Huỷ"), role: .cancel) {}
        Button(String(localized: "Xoá"), role: .destructive) {
            viewModel.deleteTransaction(context: context)
            if viewModel.errorMessage == nil { dismiss() }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TransactionDetailView(
            transaction: Transaction(
                amount: 150_000,
                note: "Cà phê sáng với đồng nghiệp",
                date: .now,
                type: .expense
            )
        )
    }
    .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
}
