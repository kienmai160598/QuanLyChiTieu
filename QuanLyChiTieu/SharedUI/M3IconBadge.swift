import SwiftUI

// MARK: - M3 Icon Badge (M3 Expressive)

/// M3E: uses continuous corner radius for squircle feel.
internal struct M3IconBadge: View {
    private let size: CGFloat
    private let content: Content

    private enum Content {
        case sfSymbol(String)
        case material(MaterialIcon.Icon)
    }

    internal init(
        icon: String,
        color: Color = .clear,
        size: CGFloat = IconSize.containerLG
    ) {
        self.content = .sfSymbol(icon)
        self.size = size
    }

    internal init(
        materialIcon: MaterialIcon.Icon,
        color: Color = .clear,
        size: CGFloat = IconSize.containerLG
    ) {
        self.content = .material(materialIcon)
        self.size = size
    }

    internal var body: some View {
        iconView
            .foregroundStyle(Color.onSurface)
            .frame(width: size, height: size)
            .background(
                Color.surfaceContainerHigh,
                in: RoundedRectangle(
                    cornerRadius: size * 0.28,
                    style: .continuous
                )
            )
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var iconView: some View {
        switch content {
        case .sfSymbol(let name):
            Image(systemName: name)
                .font(.system(size: size * 0.38, weight: .medium))
        case .material(let icon):
            MaterialIcon(icon, size: size * 0.55)
        }
    }
}
