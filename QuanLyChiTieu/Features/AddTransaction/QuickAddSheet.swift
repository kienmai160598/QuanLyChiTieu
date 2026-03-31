import SwiftUI
import SwiftData

// MARK: - Quick Add Sheet

/// Compact half-sheet for rapidly adding an expense transaction.
/// Shows amount display, quick amount chips, category row, and save button.
internal struct QuickAddSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query private var allCategories: [Category]

    private var expenseCategories: [Category] {
        allCategories.filter { $0.type == .expense }
    }

    @State private var viewModel = AddTransactionViewModel()
    @State private var showFullForm = false

    internal var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                amountDisplay
                quickAmountChips
                categoryRow
                Spacer(minLength: Spacing.sm)
                actionButtons
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.lg)
            .navigationTitle(String(localized: "Thêm nhanh"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { closeToolbar }
            .overlay { if viewModel.showingSuccess { successOverlay } }
            .onChange(of: viewModel.shouldDismiss) { _, val in if val { dismiss() } }
        }
        .fullScreenCover(isPresented: $showFullForm) {
            AddTransactionView()
        }
    }
}

// MARK: - Amount Display

private extension QuickAddSheet {
    private var amountDisplay: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
            Text(viewModel.parsedAmount > 0 ? viewModel.displayAmount : "0")
                .font(Typography.heroLarge)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .contentTransition(.numericText(value: Double(
                    truncating: viewModel.parsedAmount as NSDecimalNumber
                )))
            Text("₫")
                .font(Typography.headlineMedium)
        }
        .foregroundStyle(
            viewModel.parsedAmount > 0 ? Color.appError : Color.onSurfaceVariant.opacity(0.4)
        )
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .animation(reduceMotion ? .none : Motion.effectDefault, value: viewModel.rawAmountDigits)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "Số tiền"))
        .accessibilityValue("\(viewModel.displayAmount) VND")
    }
}

// MARK: - Quick Amount Chips

private extension QuickAddSheet {
    private static let quickAmounts: [(String, Decimal)] = [
        ("50.000", 50_000),
        ("100.000", 100_000),
        ("200.000", 200_000),
        ("500.000", 500_000),
    ]

    private var quickAmountChips: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(Self.quickAmounts, id: \.1) { label, amount in
                quickAmountChip(label: label, amount: amount)
            }
        }
    }

    private func quickAmountChip(label: String, amount: Decimal) -> some View {
        let isSelected = viewModel.parsedAmount == amount

        return Button {
            HapticService.lightImpact()
            withAnimation(Motion.spatialFast) {
                viewModel.rawAmountDigits = "\(amount)"
            }
        } label: {
            Text(label)
                .font(isSelected ? Typography.labelLargeEmphasized : Typography.labelLarge)
                .foregroundStyle(isSelected ? Color.onPrimary : Color.onSurface)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.appPrimary : Color.surfaceContainerHigh, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label) VND")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Category Row

private extension QuickAddSheet {
    private var categoryRow: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "Danh mục"))
                .font(Typography.titleSmallEmphasized)
                .foregroundStyle(Color.onSurfaceVariant)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(expenseCategories) { category in
                        categoryChip(category)
                    }
                }
                .padding(.horizontal, Spacing.xxs)
            }
        }
    }

    private func categoryChip(_ category: Category) -> some View {
        let isSelected = viewModel.selectedCategory?.id == category.id

        return Button {
            HapticService.lightImpact()
            withAnimation(Motion.spatialFast) {
                viewModel.selectedCategory = isSelected ? nil : category
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: category.icon)
                    .font(.system(size: IconSize.sm, weight: .medium))
                Text(category.localizedName)
                    .font(isSelected ? Typography.labelLargeEmphasized : Typography.labelLarge)
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? Color.onPrimary : Color.onSurface)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(isSelected ? Color.appPrimary : Color.surfaceContainerHigh, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.localizedName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Action Buttons

private extension QuickAddSheet {
    private var actionButtons: some View {
        VStack(spacing: Spacing.sm) {
            saveButton
            expandButton
        }
    }

    private var saveButton: some View {
        Button {
            viewModel.saveTransaction(context: context)
        } label: {
            Text(String(localized: "Lưu"))
                .font(Typography.labelLargeEmphasized)
                .foregroundStyle(Color.onPrimary)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color.appPrimary, in: Capsule())
                .opacity(viewModel.isValid ? 1.0 : 0.4)
        }
        .buttonStyle(ExpressivePressStyle())
        .disabled(!viewModel.isValid || viewModel.isSaving)
    }

    private var expandButton: some View {
        Button {
            dismiss()
            showFullForm = true
        } label: {
            Text(String(localized: "Thêm chi tiết"))
                .font(Typography.labelLarge)
                .foregroundStyle(Color.onSurfaceVariant)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "Mở form đầy đủ"))
    }
}

// MARK: - Toolbar & Overlays

private extension QuickAddSheet {
    @ToolbarContentBuilder
    private var closeToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
            }
            .accessibilityLabel(String(localized: "Đóng"))
        }
    }

    private var successOverlay: some View {
        SuccessOverlay(
            message: String(localized: "Đã lưu!"),
            accessibilityMessage: String(localized: "Giao dịch đã được lưu thành công")
        )
    }
}

// MARK: - Preview

#Preview {
    QuickAddSheet()
        .presentationDetents([.medium])
        .modelContainer(
            for: [Transaction.self, Category.self],
            inMemory: true
        )
}
