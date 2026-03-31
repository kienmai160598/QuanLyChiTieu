import SwiftUI

// MARK: - M3 Expressive Elevation Levels

internal enum M3Elevation: Sendable {
    case level0
    case level1
    case level2
    case level3
}

// MARK: - M3 Card Modifier

/// Applies surface background + continuous corner radius. No shadow.
private struct M3CardModifier: ViewModifier {
    private let cornerRadius: CGFloat
    private let backgroundColor: Color

    internal init(cornerRadius: CGFloat, backgroundColor: Color) {
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
    }

    internal func body(content: Content) -> some View {
        content
            .background(
                backgroundColor,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
    }
}

// MARK: - View Extension

internal extension View {
    /// M3 card: surface background + continuous corners. No shadow.
    func m3Card(
        cornerRadius: CGFloat = Spacing.cornerExtraLarge,
        background: Color = .surfaceContainerLow
    ) -> some View {
        modifier(M3CardModifier(cornerRadius: cornerRadius, backgroundColor: background))
    }

    /// M3 hero card with larger corner radius.
    func m3HeroCard(
        cornerRadius: CGFloat = Spacing.cornerExtraExtraLarge,
        background: Color = .surfaceContainerLow
    ) -> some View {
        m3Card(cornerRadius: cornerRadius, background: background)
    }

    /// Individual white card background for a List row.
    /// Each item is its own card with rounded corners following M3 formula:
    /// **Outer Radius (28pt) = Inner Radius (12pt) + Padding (16pt)**.
    func m3SectionRow(
        screenMargin: CGFloat = Spacing.lg,
        contentPadding: CGFloat = Spacing.lg
    ) -> some View {
        let verticalGap = Spacing.xs
        let verticalPad = Spacing.md
        return self
            .listRowBackground(
                RoundedRectangle(
                    cornerRadius: Spacing.cornerHero,
                    style: .continuous
                )
                .fill(Color.surfaceContainerLowest)
                .padding(.horizontal, screenMargin)
                .padding(.vertical, verticalGap)
            )
            .listRowInsets(EdgeInsets(
                top: verticalGap + verticalPad,
                leading: screenMargin + contentPadding,
                bottom: verticalGap + verticalPad,
                trailing: screenMargin + contentPadding
            ))
            .listRowSeparator(.hidden)
    }
}
