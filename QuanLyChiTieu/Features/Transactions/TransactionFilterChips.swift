import SwiftUI

// MARK: - TransactionFilterChips

internal struct TransactionFilterChips: View {
    @Binding internal var filterType: TransactionType?

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    internal var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                chipButton(label: String(localized: "Tất cả"), type: nil)
                chipButton(label: String(localized: "Chi tiêu"), type: .expense)
                chipButton(label: String(localized: "Thu nhập"), type: .income)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.xs)
        }
        .animation(
            reduceMotion ? .none : Motion.spatialDefault,
            value: filterType
        )
    }
}

// MARK: - Chip Builders

private extension TransactionFilterChips {
    private func chipButton(
        label: String,
        type: TransactionType?
    ) -> some View {
        let isSelected = filterType == type
        return Button {
            triggerHaptic()
            filterType = isSelected ? nil : type
        } label: {
            Text(label)
                .font(Typography.labelLarge)
                .foregroundStyle(isSelected ? Color.onPrimary : .primary)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
        }
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .background(
            isSelected ? Color.appPrimary : Color.surfaceContainerHigh,
            in: .capsule
        )
    }

    private func triggerHaptic() {
        HapticService.lightImpact()
    }
}
