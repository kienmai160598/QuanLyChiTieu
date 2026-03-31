import SwiftUI

// MARK: - PITCalculatorView

internal struct PITCalculatorView: View {
    @State private var viewModel = PITCalculatorViewModel()

    internal var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                inputSection
                if viewModel.parsedGross > 0 {
                    resultsSection
                    bracketBreakdown
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xl)
        }
        .navigationTitle(String(localized: "Tính thuế TNCN"))
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .appBackground()
    }
}

// MARK: - Input Section

private extension PITCalculatorView {
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionLabel(String(localized: "Thông tin thu nhập"))
            grossSalaryField
            dependentsStepper
            insuranceRateRow
        }
        .padding(Spacing.lg)
        .background(Color.surfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerLarge))
    }

    private var grossSalaryField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(String(localized: "Lương gross (VND/tháng)"))
                .font(Typography.labelLarge)
                .foregroundStyle(Color.onSurfaceVariant)
            TextField(
                String(localized: "Nhập lương gross"),
                text: $viewModel.grossSalary
            )
            .keyboardType(.numberPad)
            .font(Typography.bodyLarge)
            .padding(Spacing.md)
            .background(Color.surfaceContainerLow)
            .clipShape(
                RoundedRectangle(cornerRadius: Spacing.cornerMedium)
            )
        }
    }

    private var dependentsStepper: some View {
        HStack {
            Text(String(localized: "Số người phụ thuộc"))
                .font(Typography.labelLarge)
                .foregroundStyle(Color.onSurfaceVariant)
            Spacer()
            Stepper(
                "\(viewModel.numberOfDependents)",
                value: $viewModel.numberOfDependents,
                in: 0...20
            )
            .font(Typography.bodyLarge)
        }
    }

    private var insuranceRateRow: some View {
        HStack {
            Text(String(localized: "Tỷ lệ BHXH"))
                .font(Typography.labelLarge)
                .foregroundStyle(Color.onSurfaceVariant)
            Spacer()
            Text("\(viewModel.socialInsuranceRatePercent)%")
                .font(Typography.bodyLarge)
                .foregroundStyle(Color.onSurface)
        }
    }
}

// MARK: - Results Section

private extension PITCalculatorView {
    private var resultsSection: some View {
        VStack(spacing: Spacing.md) {
            summaryCard
            netSalaryCard
        }
    }

    private var summaryCard: some View {
        VStack(spacing: Spacing.sm) {
            resultRow(
                label: String(localized: "Thu nhập chịu thuế"),
                value: viewModel.taxableIncome.formattedVND
            )
            Divider()
            resultRow(
                label: String(localized: "Thuế TNCN"),
                value: viewModel.taxAmount.formattedVND
            )
            Divider()
            resultRow(
                label: String(localized: "Thuế suất hiệu dụng"),
                value: viewModel.effectiveRate.formattedPercent
            )
        }
        .padding(Spacing.lg)
        .m3Card(cornerRadius: Spacing.cornerLarge)
    }

    private var netSalaryCard: some View {
        VStack(spacing: Spacing.xs) {
            Text(String(localized: "Lương thực nhận"))
                .font(Typography.labelLarge)
                .foregroundStyle(Color.onSurfaceVariant)
            Text(viewModel.netSalary.formattedVND)
                .font(Typography.heroMedium)
                .foregroundStyle(Color.accentGreen)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .m3Card(cornerRadius: Spacing.cornerLarge)
    }

    private func resultRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Typography.bodyMedium)
                .foregroundStyle(Color.onSurfaceVariant)
            Spacer()
            Text(value)
                .font(Typography.titleMedium)
                .foregroundStyle(Color.onSurface)
                .contentTransition(.numericText())
        }
    }
}

// MARK: - Bracket Breakdown

private extension PITCalculatorView {
    private var bracketBreakdown: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionLabel(String(localized: "Chi tiết bậc thuế"))
            bracketTable
        }
        .padding(Spacing.lg)
        .m3Card(cornerRadius: Spacing.cornerLarge)
    }

    private var bracketTable: some View {
        VStack(spacing: Spacing.sm) {
            bracketHeader
            ForEach(viewModel.calculateBrackets()) { bracket in
                bracketRow(bracket)
            }
        }
    }

    private var bracketHeader: some View {
        HStack {
            Text(String(localized: "Bậc"))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(String(localized: "Thuế suất"))
                .frame(width: 60, alignment: .trailing)
            Text(String(localized: "Thuế"))
                .frame(width: 100, alignment: .trailing)
        }
        .font(Typography.labelMedium)
        .foregroundStyle(Color.onSurfaceVariant)
    }

    private func bracketRow(_ bracket: TaxBracket) -> some View {
        HStack {
            Text(bracket.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("\(bracket.ratePercent)%")
                .frame(width: 60, alignment: .trailing)
            Text(bracket.taxAmount.formattedVND)
                .frame(width: 100, alignment: .trailing)
        }
        .font(Typography.labelSmall)
        .foregroundStyle(
            bracket.taxableAmount > 0 ? Color.onSurface : Color.outlineVariant
        )
    }
}

// MARK: - Shared Helpers

private extension PITCalculatorView {
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Typography.sectionHeader)
            .foregroundStyle(Color.onSurface)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PITCalculatorView()
    }
}
