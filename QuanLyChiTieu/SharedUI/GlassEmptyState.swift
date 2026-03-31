import SwiftUI

// MARK: - Reusable empty state card (M3 Expressive)

/// M3E: surfaceContainerLow background, cornerExtraLarge, level1 elevation.
internal struct EmptyStateCard: View {
    internal let icon: String
    internal let title: String
    internal var subtitle: String? = nil
    internal var actionLabel: String? = nil
    internal var onAction: (() -> Void)? = nil

    internal var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(Typography.headlineLarge)
                .foregroundStyle(Color.onSurfaceVariant.opacity(0.4))
                .accessibilityHidden(true)

            Text(title)
                .font(Typography.bodyMedium)
                .foregroundStyle(Color.onSurfaceVariant)
                .multilineTextAlignment(.center)

            if let subtitle {
                Text(subtitle)
                    .font(Typography.bodySmall)
                    .foregroundStyle(Color.onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }

            if let actionLabel, let onAction {
                Button(actionLabel, action: onAction)
                    .font(Typography.labelLargeEmphasized)
                    .foregroundStyle(Color.appSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .m3Card(cornerRadius: Spacing.cornerExtraLarge)
    }
}
