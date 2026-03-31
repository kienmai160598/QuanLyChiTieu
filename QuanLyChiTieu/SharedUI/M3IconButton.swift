import SwiftUI

// MARK: - M3 Icon Button Styles

/// Standard icon button with rounded-square background.
/// Use for toolbar actions, navigation buttons, and icon-only controls.
///
/// Variants:
/// - `.filled`: solid `surfaceContainerHigh` bg + `onSurface` icon (default, soft)
/// - `.filledTonal`: solid `primaryContainer` bg + `onPrimaryContainer` icon
/// - `.primary`: solid `appPrimary` bg + white icon (prominent)
internal struct M3IconButton: View {
    private let icon: String
    private let style: Style
    private let size: CGFloat
    private let cornerRadius: CGFloat

    internal enum Style {
        case filled
        case filledTonal
        case primary
    }

    internal init(
        icon: String,
        style: Style = .filled,
        size: CGFloat = 44,
        cornerRadius: CGFloat = Spacing.cornerMedium
    ) {
        self.icon = icon
        self.style = style
        self.size = size
        self.cornerRadius = cornerRadius
    }

    internal var body: some View {
        Image(systemName: icon)
            .font(Typography.titleSmall)
            .foregroundStyle(foregroundColor)
            .frame(width: size, height: size)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var foregroundColor: Color {
        switch style {
        case .filled: Color.onSurface
        case .filledTonal: Color.onPrimaryContainer
        case .primary: .white
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .filled: Color.surfaceContainerHigh
        case .filledTonal: Color.primaryContainer
        case .primary: Color.appPrimary
        }
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: Spacing.md) {
        M3IconButton(icon: "gearshape", style: .filled)
        M3IconButton(icon: "gearshape", style: .filledTonal)
        M3IconButton(icon: "gearshape", style: .primary)
    }
    .padding()
}
