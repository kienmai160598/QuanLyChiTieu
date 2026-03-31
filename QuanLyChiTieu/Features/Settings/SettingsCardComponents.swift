import SwiftUI

// MARK: - SettingsRow

internal struct SettingsRow<Trailing: View>: View {
    private let iconContent: IconContent
    private let iconColor: Color
    private let title: LocalizedStringKey
    private let subtitle: String?
    private let isDestructive: Bool
    private let trailing: Trailing

    private enum IconContent {
        case sfSymbol(String)
        case material(MaterialIcon.Icon)
    }

    internal init(
        icon: String,
        iconColor: Color,
        title: LocalizedStringKey,
        subtitle: String? = nil,
        isDestructive: Bool = false,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.iconContent = .sfSymbol(icon)
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.isDestructive = isDestructive
        self.trailing = trailing()
    }

    internal init(
        materialIcon: MaterialIcon.Icon,
        iconColor: Color,
        title: LocalizedStringKey,
        subtitle: String? = nil,
        isDestructive: Bool = false,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.iconContent = .material(materialIcon)
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.isDestructive = isDestructive
        self.trailing = trailing()
    }

    internal var body: some View {
        HStack(spacing: Spacing.md) {
            iconBadge
            titleContent
            Spacer(minLength: Spacing.xs)
            trailing
        }
    }

    @ViewBuilder
    private var iconBadge: some View {
        let color = isDestructive ? Color.appError : iconColor
        switch iconContent {
        case .sfSymbol(let name):
            M3IconBadge(icon: name, color: color)
        case .material(let icon):
            M3IconBadge(materialIcon: icon, color: color)
        }
    }

    private var titleContent: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(title)
                .font(Typography.bodyLarge)
                .foregroundStyle(
                    isDestructive ? Color.appError : Color.onSurface
                )
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            if let subtitle {
                Text(subtitle)
                    .font(Typography.bodySmall)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
        }
    }
}
