import SwiftUI

// MARK: - SavingsGoalTemplatesSheet

/// Sheet for selecting pre-defined savings goal templates.
/// Displays a 2-column grid of template cards with icon, name, suggested amount, and duration.
internal struct SavingsGoalTemplatesSheet: View {
    internal let onSelectTemplate: (SavingsGoalTemplate) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var selectedTemplateID: String?

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.sm),
        GridItem(.flexible(), spacing: Spacing.sm),
    ]

    internal var body: some View {
        NavigationStack {
            ScrollView {
                templateGrid
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.xxxl)
            }
            .appBackground()
            .navigationTitle(String(localized: "Chọn mẫu mục tiêu"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .toolbar { toolbarItems }
            .onAppear { appeared = true }
        }
        .presentationDetents([.medium])
        .presentationCornerRadius(Spacing.cornerExtraExtraLarge)
        .presentationBackground(Color.surfaceContainerLowest)
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
            }
            .accessibilityLabel(String(localized: "Đóng"))
        }
    }
}

// MARK: - Template Grid

private extension SavingsGoalTemplatesSheet {
    private var templateGrid: some View {
        LazyVGrid(columns: columns, spacing: Spacing.sm) {
            ForEach(Array(SavingsGoalTemplate.all.enumerated()), id: \.element.id) { index, template in
                templateCard(template, index: index)
            }
        }
    }

    private func templateCard(_ template: SavingsGoalTemplate, index: Int) -> some View {
        let isSelected = selectedTemplateID == template.id
        let templateColor = Color(hex: template.colorHex)

        return Button {
            selectTemplate(template)
        } label: {
            VStack(alignment: .leading, spacing: Spacing.md) {
                iconCircle(template: template, templateColor: templateColor)
                templateInfo(template: template)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground(isSelected: isSelected, templateColor: templateColor))
            .clipShape(RoundedRectangle(
                cornerRadius: isSelected ? Spacing.cornerHero : Spacing.cornerExtraLarge,
                style: .continuous
            ))
        }
        .buttonStyle(ExpressivePressStyle())
        .opacity(reduceMotion || appeared ? 1 : 0)
        .offset(y: reduceMotion || appeared ? 0 : 8)
        .animation(
            reduceMotion ? .none : Motion.spatialSlow.delay(Double(index) * 0.05),
            value: appeared
        )
        .animation(reduceMotion ? .none : Motion.spatialDefault, value: isSelected)
        .accessibilityLabel(accessibilityLabel(for: template))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func iconCircle(template: SavingsGoalTemplate, templateColor: Color) -> some View {
        Image(systemName: template.icon)
            .font(.system(size: IconSize.lg, weight: .semibold))
            .foregroundStyle(templateColor)
            .frame(width: IconSize.containerXL, height: IconSize.containerXL)
            .background(templateColor.opacity(0.15), in: Circle())
    }

    private func templateInfo(template: SavingsGoalTemplate) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(template.name)
                .font(Typography.bodyMediumEmphasized)
                .foregroundStyle(Color.onSurface)
                .lineLimit(1)

            Text(template.formattedSuggestedAmount)
                .font(Typography.labelSmall)
                .foregroundStyle(Color.onSurface)
                .lineLimit(1)

            if let duration = template.deadlineDescription {
                Text(duration)
                    .font(Typography.labelSmall)
                    .foregroundStyle(Color.onSurfaceVariant)
                    .lineLimit(1)
            }

            Text(template.category.displayName)
                .font(Typography.labelSmall)
                .foregroundStyle(Color.onSurfaceVariant)
                .lineLimit(1)
        }
    }

    private func cardBackground(isSelected: Bool, templateColor: Color) -> some ShapeStyle {
        isSelected
            ? AnyShapeStyle(templateColor.opacity(0.12))
            : AnyShapeStyle(Color.surfaceContainerLow)
    }

    private func accessibilityLabel(for template: SavingsGoalTemplate) -> String {
        var label = template.name
        label += ", " + template.formattedSuggestedAmount
        if let duration = template.deadlineDescription {
            label += ", " + duration
        }
        label += ", " + template.category.displayName
        return label
    }
}

// MARK: - Actions

private extension SavingsGoalTemplatesSheet {
    private func selectTemplate(_ template: SavingsGoalTemplate) {
        HapticService.lightImpact()
        withAnimation(Motion.spatialFast) {
            selectedTemplateID = template.id
        }
        dismissAfterSelection(template)
    }

    private func dismissAfterSelection(_ template: SavingsGoalTemplate) {
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            onSelectTemplate(template)
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    SavingsGoalTemplatesSheet { template in
        print("Selected: \(template.name)")
    }
}
